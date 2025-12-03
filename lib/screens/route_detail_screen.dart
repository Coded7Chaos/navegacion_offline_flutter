import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:maplibre_gl/maplibre_gl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import '../models/ruta.dart';
import '../models/parada.dart';
import '../models/ubicacion.dart';
import '../providers/data_provider.dart';

class RouteDetailScreen extends StatefulWidget {
  final Ruta ruta;

  const RouteDetailScreen({super.key, required this.ruta});

  @override
  State<RouteDetailScreen> createState() => _RouteDetailScreenState();
}

class _RouteDetailScreenState extends State<RouteDetailScreen> {
  MaplibreMapController? mapController;
  String? _stylePath;
  bool _isLoadingMap = true;
  
  // Route Data
  List<LatLng> _polylineCoordinates = [];
  List<Parada> _stops = [];
  bool _isLoadingData = true;

  @override
  void initState() {
    super.initState();
    _prepararArchivosOffline();
    _loadRouteData();
  }

  Future<void> _loadRouteData() async {
    if (widget.ruta.idRutaPuma == null) return;
    
    final dataProvider = Provider.of<DataProvider>(context, listen: false);
    
    try {
      // Fetch Polyline Points
      final List<Ubicacion> coords = await dataProvider.getRoutePolyline(widget.ruta.idRutaPuma!);
      final List<LatLng> latLngs = coords.map((c) => LatLng(c.latitud, c.longitud)).toList();
      
      // Fetch Stops
      final List<Parada> stops = await dataProvider.getStopsForRoute(widget.ruta.idRutaPuma!);

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

  void _onMapCreated(MaplibreMapController controller) {
    mapController = controller;
    if (!_isLoadingData) {
      _drawRouteOnMap();
    }
  }

  void _drawRouteOnMap() async {
    if (mapController == null || _polylineCoordinates.isEmpty) return;

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
        iconImage: "marker-15", // Make sure this icon is available in style/assets
        iconSize: 1.0,
        textField: stop.nombre,
        textOffset: const Offset(0, 1.2),
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
      ),
      body: _isLoadingMap
          ? const Center(child: CircularProgressIndicator())
          : Stack(
              children: [
                MaplibreMap(
                  initialCameraPosition: const CameraPosition(
                    target: LatLng(-16.5000, -68.1193), // Default La Paz
                    zoom: 12,
                  ),
                  styleString: _stylePath ?? "",
                  onMapCreated: _onMapCreated,
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
              ],
            ),
    );
  }
}
