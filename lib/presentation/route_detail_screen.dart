import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:maplibre_gl/maplibre_gl.dart';
import 'package:path_provider/path_provider.dart';
import '../models/ruta.dart';
import '../models/parada.dart';
import '../models/ubicacion.dart';
import '../repositories/data_repository.dart';
import '../blocs/user/user_bloc.dart';
import '../blocs/user/user_event.dart';
import '../blocs/user/user_state.dart';

class RouteDetailScreen extends StatefulWidget {
  final Ruta ruta;
  final DataRepository repository;

  const RouteDetailScreen({super.key, required this.ruta, required this.repository});

  @override
  State<RouteDetailScreen> createState() => _RouteDetailScreenState();
}

class _RouteDetailScreenState extends State<RouteDetailScreen> {
  MapLibreMapController? mapController;
  String? _stylePath;
  bool _isLoadingMap = true;
  bool _isStyleLoaded = false;
  
  // Route Data
  List<LatLng> _polylineCoordinates = [];
  List<Parada> _stops = [];
  bool _isLoadingData = true;
  bool _iconsLoaded = false;
  bool _routeDrawn = false;

  static const String _stopIconName = "parada-icon";

  @override
  void initState() {
    super.initState();
    _prepararArchivosOffline();
    _loadRouteData();
  }

  Future<void> _loadRouteData() async {
    if (widget.ruta.idRutaPuma == null) return;
    
    try {
      final List<Ubicacion> coords = await widget.repository.getRoutePolyline(widget.ruta.idRutaPuma!);
      final List<LatLng> latLngs = coords.map((c) => LatLng(c.latitud, c.longitud)).toList();
      final List<Parada> stops = await widget.repository.getStopsForRoute(widget.ruta.idRutaPuma!);

      if (mounted) {
        setState(() {
          _polylineCoordinates = latLngs;
          _stops = stops;
          _isLoadingData = false;
        });
        _drawRouteOnMap();
      }
    } catch (e) {
      print("Error loading route data: $e");
      if (mounted) setState(() => _isLoadingData = false);
    }
  }

  Future<void> _prepararArchivosOffline() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final mapsDir = Directory('${directory.path}/maps');
      if (!await mapsDir.exists()) await mapsDir.create();

      final mbtilesPath = '${mapsDir.path}/lapaz.mbtiles';
      // Ensure mbtiles exists (copied in MapScreen, but good to check)
      if (!File(mbtilesPath).existsSync()) {
         final byteData = await rootBundle.load('assets/maps/lapaz.mbtiles');
         await File(mbtilesPath).writeAsBytes(byteData.buffer.asUint8List());
      }

      final styleString = await rootBundle.loadString('assets/maps/style.json');
      final finalStyle = styleString.replaceFirst('{path_to_mbtiles}', mbtilesPath);

      final styleFile = File('${mapsDir.path}/style_final.json');
      await styleFile.writeAsString(finalStyle);

      if (mounted) {
        setState(() {
          _stylePath = styleFile.path;
          _isLoadingMap = false;
        });
      }
    } catch (e) {
      print("Error preparing map style: $e");
    }
  }

  void _onMapCreated(MapLibreMapController controller) async {
    mapController = controller;
  }

  Future<void> _onStyleLoaded() async {
    if (!mounted || mapController == null) return;
    _isStyleLoaded = true;

    try {
      await mapController?.setSymbolIconAllowOverlap(true);
      await mapController?.setSymbolIconIgnorePlacement(true);
      await mapController?.setSymbolTextAllowOverlap(true);
      await mapController?.setSymbolTextIgnorePlacement(true);
    } catch (e) {
      print("Error configuring symbol collision: $e");
    }

    try {
      final ByteData bytes =
          await rootBundle.load("assets/images/parada_bus.png");
      final Uint8List list = bytes.buffer.asUint8List();
      await mapController!.addImage(_stopIconName, list);
      _iconsLoaded = true;
    } catch (e) {
      print("Error loading icon: $e");
    }

    _drawRouteOnMap();
  }

  void _drawRouteOnMap() async {
    if (mapController == null ||
        !_isStyleLoaded ||
        _polylineCoordinates.isEmpty ||
        !_iconsLoaded ||
        _routeDrawn) return;
    _routeDrawn = true;

    // 1. Draw Polyline
    await mapController!.addLine(LineOptions(
      geometry: _polylineCoordinates,
      lineColor: "#FF0000", // Red color for route
      lineWidth: 5.0,
      lineOpacity: 0.8,
    ));

    // 2. Draw Stops Markers
    for (var stop in _stops) {
      await mapController!.addSymbol(SymbolOptions(
        geometry: LatLng(stop.lat, stop.lon),
        iconImage: _stopIconName,
        iconSize: 0.5, // Adjusted size, original might be large
        textField: stop.nombre,
        textOffset: const Offset(0, 1.5),
        textSize: 12.0,
        textHaloColor: "#FFFFFF",
        textHaloWidth: 1.0,
      ));
    }

    // 3. Fit Bounds to show whole route
    if (_polylineCoordinates.isNotEmpty) {
      await mapController!.animateCamera(
        CameraUpdate.newLatLngBounds(
          _calculateBounds(_polylineCoordinates),
          left: 50, top: 50, right: 50, bottom: 50,
        ),
      );
    }
  }

  Future<void> _openStopsSheet() async {
    if (_stops.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No hay paradas disponibles.')),
      );
      return;
    }
    if (!mounted) return;
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 12),
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
                'Paradas',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                  color: Color(0xFF5C3A29),
                ),
              ),
              const SizedBox(height: 8),
              Flexible(
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: _stops.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (_, index) {
                    final stop = _stops[index];
                    return ListTile(
                      title: Text(stop.nombre),
                      trailing: const Icon(Icons.place_outlined),
                      onTap: () {
                        Navigator.pop(sheetContext);
                        _focusStop(stop);
                      },
                    );
                  },
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }

  Future<void> _focusStop(Parada stop) async {
    if (mapController == null) return;
    await mapController!.animateCamera(
      CameraUpdate.newLatLngZoom(LatLng(stop.lat, stop.lon), 16),
    );
  }

  LatLngBounds _calculateBounds(List<LatLng> coords) {
    double minLat = 90.0;
    double minLon = 180.0;
    double maxLat = -90.0;
    double maxLon = -180.0;

    for (var c in coords) {
      minLat = min(minLat, c.latitude);
      minLon = min(minLon, c.longitude);
      maxLat = max(maxLat, c.latitude);
      maxLon = max(maxLon, c.longitude);
    }

    return LatLngBounds(
      southwest: LatLng(minLat, minLon),
      northeast: LatLng(maxLat, maxLon),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.ruta.nombre),
        actions: [
          BlocBuilder<UserBloc, UserState>(
            builder: (context, state) {
              final isFav = state is UserLoaded &&
                  widget.ruta.idRutaPuma != null &&
                  state.favoritos.contains(widget.ruta.idRutaPuma);
              return IconButton(
                icon: Icon(
                  isFav ? Icons.favorite : Icons.favorite_border,
                  color: isFav ? Colors.red : null,
                ),
                onPressed: widget.ruta.idRutaPuma == null
                    ? null
                    : () => context
                        .read<UserBloc>()
                        .add(FavoriteToggled(widget.ruta.idRutaPuma!)),
              );
            },
          ),
        ],
      ),
      body: _isLoadingMap
          ? const Center(child: CircularProgressIndicator())
          : Stack(
              children: [
                MapLibreMap(
                  initialCameraPosition: const CameraPosition(
                    target: LatLng(-16.5000, -68.1193), // Default La Paz
                    zoom: 12,
                  ),
                  styleString: _stylePath ?? "",
                  onMapCreated: _onMapCreated,
                  onStyleLoadedCallback: _onStyleLoaded,
                ),
                if (_isLoadingData)
                  const Positioned(
                    top: 10,
                    right: 10,
                    child: Card(
                      child: Padding(
                        padding: EdgeInsets.all(8.0),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)),
                            SizedBox(width: 8),
                            Text("Cargando ruta..."),
                          ],
                        ),
                      ),
                    ),
                  ),
                Positioned(
                  bottom: 16,
                  right: 16,
                  child: FloatingActionButton.extended(
                    heroTag: 'stopsButton',
                    onPressed: _openStopsSheet,
                    backgroundColor: const Color(0xFFD97846),
                    foregroundColor: Colors.white,
                    label: const Text('Paradas'),
                    icon: const Icon(Icons.place),
                  ),
                ),
              ],
            ),
    );
  }
}
