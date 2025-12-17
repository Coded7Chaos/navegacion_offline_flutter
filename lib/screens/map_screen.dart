import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:path_provider/path_provider.dart';
import 'package:maplibre_gl/maplibre_gl.dart';
import '../blocs/map/map_bloc.dart';
import '../blocs/map/map_event.dart';
import '../blocs/map/map_state.dart';
import '../blocs/user/user_bloc.dart';
import '../blocs/user/user_event.dart';
import '../repositories/data_repository.dart';
import '../models/ruta.dart';
import '../models/ubicacion.dart';
import 'route_detail_screen.dart';
import 'route_results_screen.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  MaplibreMapController? _controller;
  String? _stylePath;
  bool _styleLoading = true;
  Symbol? _destinationSymbol;
  Line? _activeLine;
  final List<Symbol> _stopSymbols = [];
  int? _pendingRouteId;

  @override
  void initState() {
    super.initState();
    _prepareOfflineStyle();
  }

  Future<void> _prepareOfflineStyle() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final mapsDir = Directory('${directory.path}/maps');
      if (!await mapsDir.exists()) await mapsDir.create();

      final mbtilesPath = '${mapsDir.path}/lapaz.mbtiles';
      if (!File(mbtilesPath).existsSync()) {
        final byteData = await rootBundle.load('assets/maps/lapaz.mbtiles');
        await File(mbtilesPath).writeAsBytes(byteData.buffer.asUint8List());
      }

      final styleString = await rootBundle.loadString('assets/maps/style.json');
      final finalStyle = styleString.replaceFirst('{path_to_mbtiles}', mbtilesPath);
      final styleFile = File('${mapsDir.path}/style_final.json');
      await styleFile.writeAsString(finalStyle);

      setState(() {
        _stylePath = styleFile.path;
        _styleLoading = false;
      });
    } catch (e) {
      setState(() => _styleLoading = false);
    }
  }

  Future<void> _onMapCreated(MaplibreMapController controller) async {
    _controller = controller;
    if (_pendingRouteId != null) {
      final repository = RepositoryProvider.of<DataRepository>(context);
      final routeId = _pendingRouteId!;
      _pendingRouteId = null;
      await _drawRouteLine(repository, routeId);
    }
  }

  Future<void> _addDestinationMarker(LatLng point) async {
    if (_controller == null) return;
    if (_destinationSymbol != null) {
      await _controller!.removeSymbol(_destinationSymbol!);
    }
    _destinationSymbol = await _controller!.addSymbol(SymbolOptions(
      geometry: point,
      iconImage: "marker-15",
      iconSize: 1.6,
    ));
    await _controller!.animateCamera(CameraUpdate.newLatLng(point));
  }

  Future<void> _drawRouteLine(DataRepository repository, int routeId) async {
    if (_controller == null) return;
    if (_activeLine != null) {
      await _controller!.removeLine(_activeLine!);
      _activeLine = null;
    }
    await _clearStopSymbols();
    final coords = await repository.getRoutePolyline(routeId);
    final geometry =
        coords.map((u) => LatLng(u.latitud, u.longitud)).toList();
    if (geometry.isNotEmpty) {
      _activeLine = await _controller!.addLine(LineOptions(
        geometry: geometry,
        lineColor: "#D97846",
        lineWidth: 5.0,
      ));
      await _controller!.animateCamera(
        CameraUpdate.newLatLngBounds(
          _boundsFrom(geometry),
          left: 40,
          top: 60,
          right: 40,
          bottom: 160,
        ),
      );
    }
  }

  LatLngBounds _boundsFrom(List<LatLng> coords) {
    double minLat = coords.first.latitude;
    double maxLat = coords.first.latitude;
    double minLon = coords.first.longitude;
    double maxLon = coords.first.longitude;
    for (final c in coords) {
      minLat = minLat > c.latitude ? c.latitude : minLat;
      maxLat = maxLat < c.latitude ? c.latitude : maxLat;
      minLon = minLon > c.longitude ? c.longitude : minLon;
      maxLon = maxLon < c.longitude ? c.longitude : maxLon;
    }
    return LatLngBounds(
      southwest: LatLng(minLat, minLon),
      northeast: LatLng(maxLat, maxLon),
    );
  }

  Future<void> _clearStopSymbols() async {
    if (_controller == null) return;
    if (_stopSymbols.isEmpty) return;

    // Work on a snapshot to avoid concurrent modification if this method is
    // triggered while another call is still awaiting removes.
    final symbols = List<Symbol>.from(_stopSymbols);
    _stopSymbols.clear();

    for (final s in symbols) {
      await _controller!.removeSymbol(s);
    }
  }

  Future<void> _drawStops(DataRepository repository, int routeId) async {
    if (_controller == null) return;
    await _clearStopSymbols();
    final stops = await repository.getStopsForRoute(routeId);
    for (final stop in stops) {
      final symbol = await _controller!.addSymbol(SymbolOptions(
        geometry: LatLng(stop.lat, stop.lon),
        iconImage: "marker-15",
        iconSize: 1.2,
        textField: stop.nombre,
        textOffset: const Offset(0, 1.4),
        textSize: 12,
      ));
      _stopSymbols.add(symbol);
    }
  }

  Future<void> _showAllStops(DataRepository repository) async {
    if (_controller == null) return;
    await _clearStopSymbols();
    final stops = await repository.loadParadas();
    for (final stop in stops) {
      final symbol = await _controller!.addSymbol(SymbolOptions(
        geometry: LatLng(stop.lat, stop.lon),
        iconImage: "marker-15",
        iconSize: 1.2,
        textField: stop.nombre,
        textOffset: const Offset(0, 1.4),
        textSize: 12,
      ));
      _stopSymbols.add(symbol);
    }
  }

  @override
  Widget build(BuildContext context) {
    final repository = RepositoryProvider.of<DataRepository>(context);
    return Scaffold(
      backgroundColor: const Color(0xFFFFF8F3),
      body: _styleLoading
          ? const Center(child: CircularProgressIndicator())
          : BlocConsumer<MapBloc, MapState>(
              listenWhen: (prev, curr) =>
                  prev.destination != curr.destination ||
                  prev.routeResults != curr.routeResults ||
                  prev.routeSelectionVersion != curr.routeSelectionVersion ||
                  prev.error != curr.error,
              listener: (context, state) async {
                if (state.destination != null) {
                  await _addDestinationMarker(state.destination!);
                }
                if (state.routeSelectionVersion > 0 &&
                    state.selectedRouteId != null) {
                  if (_controller == null) {
                    _pendingRouteId = state.selectedRouteId;
                  } else {
                    await _drawRouteLine(repository, state.selectedRouteId!);
                  }
                }
                if (state.error != null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(state.error!)),
                  );
                }
                if (state.routeResults.isNotEmpty) {
                  final summary =
                      'Desde mi ubicación hacia destino (${state.destination?.latitude.toStringAsFixed(4)}, ${state.destination?.longitude.toStringAsFixed(4)})';
                  context.read<UserBloc>().add(HistoryAdded(summary));
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => RouteResultsScreen(
                        results: state.routeResults.take(5).toList(),
                        onResultSelected: (selected) {
                          final tempRuta = Ruta(
                            idRutaPuma: selected.routeId,
                            nombre: selected.routeName,
                            sentido: 'Ida/Vuelta',
                            estado: true,
                          );
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => RouteDetailScreen(
                                ruta: tempRuta,
                                repository: repository,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ).then((_) {
                    context.read<MapBloc>().add(MapClearResults());
                  });
                }
              },
              builder: (context, state) {
                return Stack(
                  children: [
                    MaplibreMap(
                      initialCameraPosition: CameraPosition(
                          target: state.cameraPosition, zoom: 13),
                      onMapCreated: _onMapCreated,
                      styleString: _stylePath ?? "",
                      myLocationEnabled: true,
                      myLocationTrackingMode: MyLocationTrackingMode.Tracking,
                      onMapClick: (p, latLng) {
                        if (state.selectionMode) {
                          context
                              .read<MapBloc>()
                              .add(MapDestinationSelected(latLng));
                        }
                      },
                    ),
                    if (state.selectionMode)
                      const Center(
                        child: Icon(Icons.add_location_alt,
                            color: Colors.black54, size: 32),
                      ),
                    Positioned(
                      top: 40,
                      left: 16,
                      right: 16,
                      child: Column(
                        children: [
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.08),
                                  blurRadius: 10,
                                  offset: const Offset(0, 6),
                                ),
                              ],
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: TextField(
                                    onChanged: (v) => context
                                        .read<MapBloc>()
                                        .add(MapSearchChanged(v)),
                                    decoration: const InputDecoration(
                                      hintText: 'Buscar ubicación o parada',
                                      border: InputBorder.none,
                                      contentPadding: EdgeInsets.symmetric(
                                          horizontal: 14, vertical: 14),
                                    ),
                                  ),
                                ),
                                IconButton(
                                  icon: Icon(
                                    Icons.my_location,
                                    color: state.selectionMode
                                        ? const Color(0xFFD97846)
                                        : const Color(0xFF5C3A29),
                                  ),
                                  onPressed: () => context
                                      .read<MapBloc>()
                                      .add(MapToggleSelectionMode()),
                                ),
                              ],
                            ),
                          ),
                          if (state.searchResults.isNotEmpty)
                            Container(
                              margin: const EdgeInsets.only(top: 6),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.08),
                                    blurRadius: 10,
                                    offset: const Offset(0, 6),
                                  ),
                                ],
                              ),
                              constraints: const BoxConstraints(maxHeight: 200),
                              child: ListView.builder(
                                shrinkWrap: true,
                                itemCount: state.searchResults.length,
                                itemBuilder: (context, index) {
                                  final Ubicacion res =
                                      state.searchResults[index];
                                  return ListTile(
                                    title: Text(res.nombre),
                                    onTap: () {
                                      final point =
                                          LatLng(res.latitud, res.longitud);
                                      context
                                          .read<MapBloc>()
                                          .add(MapDestinationSelected(point));
                                      _addDestinationMarker(point);
                                      _controller?.animateCamera(
                                          CameraUpdate.newLatLngZoom(
                                              point, 15));
                                    },
                                  );
                                },
                              ),
                            ),
                        ],
                      ),
                    ),
                    Positioned(
                      bottom: 120,
                      left: 16,
                      right: 16,
                      child: Row(
                        children: [
                          _CircleButton(
                            icon: Icons.navigation,
                            onPressed: () async {
                              context
                                  .read<MapBloc>()
                                  .add(MapUserLocationRequested());
                              final user = state.userLocation;
                              if (user != null) {
                                await _controller?.animateCamera(
                                    CameraUpdate.newLatLngZoom(user, 15));
                              }
                            },
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: (state.destination != null &&
                                      state.userLocation != null)
                                  ? () => context
                                      .read<MapBloc>()
                                      .add(MapRouteRequested())
                                  : null,
                              style: ElevatedButton.styleFrom(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 14),
                                backgroundColor: const Color(0xFFD97846),
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                              ),
                              child: const Text(
                                'Buscar ruta más corta',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          _CircleButton(
                            icon: Icons.list,
                            onPressed: () => _openRoutesSheet(repository),
                          ),
                        ],
                      ),
                    ),
                    Positioned(
                      bottom: 70,
                      right: 16,
                      child: state.destination != null
                          ? FloatingActionButton.small(
                              heroTag: 'clearDest',
                              backgroundColor: Colors.white,
                              onPressed: () => context
                                  .read<MapBloc>()
                                  .add(MapDestinationCleared()),
                              child: const Icon(Icons.close,
                                  color: Color(0xFF5C3A29)),
                            )
                          : const SizedBox.shrink(),
                    ),
                  ],
                );
              },
            ),
    );
  }

  Future<void> _openRoutesSheet(DataRepository repository) async {
    final rutas = await repository.loadRutas();
    if (!mounted) return;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) {
        int? selectedId;
        bool showStops = false;
        return StatefulBuilder(builder: (context, setModalState) {
          return SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Rutas disponibles',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                      color: Color(0xFF5C3A29),
                    ),
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton(
                    onPressed: () async {
                      await _showAllStops(repository);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: const Color(0xFF5C3A29),
                      minimumSize: const Size.fromHeight(44),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: const BorderSide(color: Color(0xFFD97846)),
                      ),
                    ),
                    child: const Text('Mostrar todas las paradas'),
                  ),
                  const SizedBox(height: 8),
                  Flexible(
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: rutas.length,
                      itemBuilder: (context, index) {
                        final ruta = rutas[index];
                        return Card(
                          margin: const EdgeInsets.symmetric(vertical: 6),
                          child: ListTile(
                            title: Text(ruta.nombre),
                            subtitle: Text(ruta.sentido),
                            trailing: const Icon(Icons.chevron_right),
                            onTap: () async {
                              selectedId = ruta.idRutaPuma ?? index;
                              showStops = false;
                              setModalState(() {});
                              await _drawRouteLine(
                                  repository, ruta.idRutaPuma ?? index);
                            },
                          ),
                        );
                      },
                    ),
                  ),
                  if (selectedId != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: ElevatedButton(
                        onPressed: () async {
                          showStops = !showStops;
                          setModalState(() {});
                          if (showStops) {
                            await _drawStops(repository, selectedId!);
                          } else {
                            await _clearStopSymbols();
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFD97846),
                          foregroundColor: Colors.white,
                          minimumSize: const Size.fromHeight(44),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(showStops
                            ? 'Ocultar paradas'
                            : 'Mostrar paradas'),
                      ),
                    ),
                  const SizedBox(height: 12),
                  ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: const Color(0xFF5C3A29),
                      minimumSize: const Size.fromHeight(44),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: const BorderSide(color: Color(0xFFD97846)),
                      ),
                    ),
                    child: const Text('Cerrar'),
                  ),
                ],
              ),
            ),
          );
        });
      },
    );
  }
}

class _CircleButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onPressed;

  const _CircleButton({required this.icon, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      shape: const CircleBorder(),
      elevation: 6,
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onPressed,
        child: SizedBox(
          width: 48,
          height: 48,
          child: Icon(icon, color: const Color(0xFF5C3A29)),
        ),
      ),
    );
  }
}
