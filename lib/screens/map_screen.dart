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

  @override
  Widget build(BuildContext context) {
    final repository = RepositoryProvider.of<DataRepository>(context);
    final theme = Theme.of(context);
    
    return Scaffold(
      // Background color handled by theme
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
                    SnackBar(
                      content: Text(state.error!),
                      backgroundColor: theme.colorScheme.error,
                      behavior: SnackBarBehavior.floating,
                    ),
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
                      Center(
                        child: Icon(Icons.add_location_alt,
                            color: theme.primaryColor, size: 40),
                      ),
                    Positioned(
                      top: 60, // Safe area
                      left: 20,
                      right: 20,
                      child: Column(
                        children: [
                          Container(
                            decoration: theme.inputDecorationTheme.fillColor != null 
                            ? BoxDecoration(
                              color: theme.inputDecorationTheme.fillColor,
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.1),
                                  blurRadius: 15,
                                  offset: const Offset(0, 5),
                                ),
                              ],
                            ) 
                            : null,
                            child: Row(
                              children: [
                                Expanded(
                                  child: TextField(
                                    onChanged: (v) => context
                                        .read<MapBloc>()
                                        .add(MapSearchChanged(v)),
                                    decoration: InputDecoration(
                                      hintText: 'Buscar ubicación o parada...',
                                      border: InputBorder.none,
                                      enabledBorder: InputBorder.none,
                                      focusedBorder: InputBorder.none,
                                      contentPadding: const EdgeInsets.symmetric(
                                          horizontal: 20, vertical: 16),
                                      prefixIcon: Icon(Icons.search, color: theme.primaryColor),
                                    ),
                                  ),
                                ),
                                Container(
                                  height: 30,
                                  width: 1,
                                  color: Colors.grey.withOpacity(0.3),
                                ),
                                IconButton(
                                  icon: Icon(
                                    Icons.my_location,
                                    color: state.selectionMode
                                        ? theme.primaryColor
                                        : Colors.grey,
                                  ),
                                  onPressed: () => context
                                      .read<MapBloc>()
                                      .add(MapToggleSelectionMode()),
                                ),
                                const SizedBox(width: 8),
                              ],
                            ),
                          ),
                          if (state.searchResults.isNotEmpty)
                            Container(
                              margin: const EdgeInsets.only(top: 12),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.1),
                                    blurRadius: 15,
                                    offset: const Offset(0, 5),
                                  ),
                                ],
                              ),
                              constraints: const BoxConstraints(maxHeight: 250),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(16),
                                child: ListView.separated(
                                  padding: EdgeInsets.zero,
                                  shrinkWrap: true,
                                  itemCount: state.searchResults.length,
                                  separatorBuilder: (context, index) => Divider(height: 1, color: Colors.grey.withOpacity(0.1)),
                                  itemBuilder: (context, index) {
                                    final Ubicacion res =
                                        state.searchResults[index];
                                    return ListTile(
                                      leading: Icon(Icons.location_on_outlined, color: theme.primaryColor),
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
                            ),
                        ],
                      ),
                    ),
                    Positioned(
                      bottom: 110, // Adjusted for floating nav
                      left: 20,
                      right: 20,
                      child: Row(
                        children: [
                          _CircleButton(
                            icon: Icons.near_me_rounded,
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
                          const SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: (state.destination != null &&
                                      state.userLocation != null)
                                  ? () => context
                                      .read<MapBloc>()
                                      .add(MapRouteRequested())
                                  : null,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: theme.primaryColor,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                elevation: 4,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(25),
                                ),
                              ),
                              child: const Text(
                                'Buscar Ruta',
                                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          _CircleButton(
                            icon: Icons.format_list_bulleted_rounded,
                            onPressed: () => _openRoutesSheet(repository),
                          ),
                        ],
                      ),
                    ),
                    if (state.destination != null)
                    Positioned(
                      bottom: 180,
                      right: 20,
                      child: FloatingActionButton.small(
                              heroTag: 'clearDest',
                              backgroundColor: Colors.white,
                              elevation: 4,
                              onPressed: () => context
                                  .read<MapBloc>()
                                  .add(MapDestinationCleared()),
                              child: Icon(Icons.close,
                                  color: theme.colorScheme.secondary),
                            ),
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
    final rootContext = context;
    final theme = Theme.of(context);
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
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
                  const SizedBox(height: 20),
                  Text(
                    'Rutas Disponibles',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: theme.primaryColor,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Flexible(
                    child: ListView.separated(
                      shrinkWrap: true,
                      itemCount: rutas.length,
                      separatorBuilder: (context, index) => const SizedBox(height: 8),
                      itemBuilder: (context, index) {
                        final ruta = rutas[index];
                        return Card(
                          elevation: 0,
                          color: theme.colorScheme.background,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: BorderSide(color: Colors.grey.withOpacity(0.1)),
                          ),
                          margin: EdgeInsets.zero,
                          child: ListTile(
                            leading: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: theme.primaryColor.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(Icons.directions_bus, color: theme.primaryColor),
                            ),
                            title: Text(ruta.nombre, style: const TextStyle(fontWeight: FontWeight.bold)),
                            subtitle: Text(ruta.sentido),
                            trailing: const Icon(Icons.chevron_right),
                            onTap: () async {
                              Navigator.pop(context);
                              if (!mounted) return;
                              Navigator.of(rootContext).push(
                                MaterialPageRoute(
                                  builder: (_) => RouteDetailScreen(
                                    ruta: ruta,
                                    repository: repository,
                                  ),
                                ),
                              );
                            },
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.grey[100],
                      foregroundColor: Colors.black87,
                      minimumSize: const Size.fromHeight(50),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: const Text('Cerrar'),
                  ),
                ],
              ),
            ),
          ),
        );
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
    final theme = Theme.of(context);
    return Material(
      color: Colors.white,
      shape: const CircleBorder(),
      elevation: 4,
      shadowColor: Colors.black.withOpacity(0.3),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onPressed,
        child: SizedBox(
          width: 50,
          height: 50,
          child: Icon(icon, color: theme.primaryColor),
        ),
      ),
    );
  }
}
