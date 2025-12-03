import 'dart:io';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:maplibre_gl/maplibre_gl.dart';
import 'package:provider/provider.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../providers/map_provider.dart';
import '../providers/data_provider.dart';
import '../models/ruta.dart';
import 'route_results_screen.dart';
import 'route_detail_screen.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  MaplibreMapController? mapController;
  String? _stylePath;
  bool _isLoading = true;
  bool _isOnline = false;
  StreamSubscription? _connectivitySubscription;

  @override
  void initState() {
    super.initState();
    _prepararArchivosOffline();
    _initConnectivity();
    
    // Load paradas for search
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<DataProvider>(context, listen: false).loadParadas();
      Provider.of<MapProvider>(context, listen: false).determinePosition();
    });
  }

  @override
  void dispose() {
    _connectivitySubscription?.cancel();
    super.dispose();
  }

  Future<void> _initConnectivity() async {
    final result = await Connectivity().checkConnectivity();
    _updateConnectionStatus(result);
    _connectivitySubscription = Connectivity().onConnectivityChanged.listen(_updateConnectionStatus);
  }

  void _updateConnectionStatus(ConnectivityResult result) {
    setState(() {
      _isOnline = result != ConnectivityResult.none;
    });
  }

  Future<void> _prepararArchivosOffline() async {
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
        _isLoading = false;
      });
    } catch (e) {
      print("Error preparando mapas: $e");
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _onMapCreated(MaplibreMapController controller) {
    mapController = controller;
  }

  @override
  Widget build(BuildContext context) {
    final mapProvider = Provider.of<MapProvider>(context);
    final dataProvider = Provider.of<DataProvider>(context);

    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      body: Stack(
        children: [
          // 1. MAP LAYER
          MaplibreMap(
            initialCameraPosition: mapProvider.cameraPosition,
            styleString: _stylePath ?? "",
            onMapCreated: _onMapCreated,
            onCameraIdle: () {
               if (mapController != null && mapProvider.isSelectingDestination) {
                 // logic to update destination if dragging map (optional)
               }
            },
            onMapClick: (point, latLng) {
               if (mapProvider.isSelectingDestination) {
                 mapProvider.setDestination(latLng);
                 mapProvider.setIsSelectingDestination(false);
                 // Add symbol logic here (would require controller.addSymbol)
                 mapController?.addSymbol(SymbolOptions(
                   geometry: latLng,
                   iconImage: "marker-15", // Ensure this icon exists in style or assets
                   iconSize: 1.5,
                 ));
               }
            },
             myLocationEnabled: true,
             myLocationRenderMode: MyLocationRenderMode.GPS,
             myLocationTrackingMode: MyLocationTrackingMode.Tracking,
          ),

          // 2. CROSSHAIR (Center)
          const Center(
            child: Icon(Icons.add, size: 30, color: Colors.black54),
          ),

          // 3. SEARCH BAR (Top)
          Positioned(
            top: 40,
            left: 10,
            right: 10,
            child: Column(
              children: [
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4)],
                  ),
                  child: TextField(
                    onChanged: (value) => mapProvider.updateSearchValue(value, dataProvider.paradas),
                    decoration: InputDecoration(
                      hintText: 'Buscar parada...',
                      border: InputBorder.none,
                      prefixIcon: const Icon(Icons.search),
                      suffixIcon: IconButton(
                        icon: const Icon(Icons.my_location),
                        onPressed: () {
                          mapProvider.determinePosition();
                           if (mapProvider.originPoint != null && mapController != null) {
                              mapController!.animateCamera(
                                CameraUpdate.newLatLngZoom(mapProvider.originPoint!, 15)
                              );
                           }
                        },
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    ),
                  ),
                ),
                if (mapProvider.searchResults.isNotEmpty)
                  Container(
                    margin: const EdgeInsets.only(top: 5),
                    color: Colors.white,
                    constraints: const BoxConstraints(maxHeight: 200),
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: mapProvider.searchResults.length,
                      itemBuilder: (ctx, i) {
                        final res = mapProvider.searchResults[i];
                        return ListTile(
                          title: Text(res.nombre),
                          onTap: () {
                             final latLng = LatLng(res.latitud, res.longitud);
                             mapProvider.setDestination(latLng);
                             mapProvider.updateSearchValue('', []); // clear search
                             mapController?.animateCamera(CameraUpdate.newLatLngZoom(latLng, 15));
                              mapController?.addSymbol(SymbolOptions(
                               geometry: latLng,
                               iconImage: "marker-15",
                               iconSize: 1.5,
                             ));
                          },
                        );
                      },
                    ),
                  )
              ],
            ),
          ),

          // 4. CONNECTIVITY STATUS (Bottom Right)
          Positioned(
            bottom: 100,
            right: 16,
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: _isOnline ? Colors.green : Colors.red,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                _isOnline ? 'Online' : 'Offline',
                style: const TextStyle(color: Colors.white),
              ),
            ),
          ),

          // 5. BOTTOM ACTION (Search Route)
          if (mapProvider.originPoint != null && mapProvider.destinationPoint != null)
            Positioned(
              bottom: 20,
              left: 20,
              right: 20,
              child: Container(
                padding: const EdgeInsets.all(8),
                 decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                     boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 6)],
                  ),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back),
                      onPressed: () => mapProvider.setDestination(null),
                    ),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () async {
                          // Show Loading
                          showDialog(
                            context: context, 
                            barrierDismissible: false,
                            builder: (_) => const Center(child: CircularProgressIndicator())
                          );

                          try {
                            final results = await dataProvider.findRoutes(
                              mapProvider.originPoint!.latitude,
                              mapProvider.originPoint!.longitude,
                              mapProvider.destinationPoint!.latitude,
                              mapProvider.destinationPoint!.longitude,
                            );

                            Navigator.pop(context); // Hide loading

                            if (results.isEmpty) {
                               ScaffoldMessenger.of(context).showSnackBar(
                                 const SnackBar(content: Text("No se encontraron rutas cercanas directas."))
                               );
                            } else {
                              // Navigate to Results
                              Navigator.push(context, MaterialPageRoute(
                                builder: (_) => RouteResultsScreen(
                                  results: results,
                                  onResultSelected: (selectedRoute) {
                                    // Create a temporary Ruta object to reuse RouteDetailScreen
                                    final tempRuta = Ruta(
                                      idRutaPuma: selectedRoute.routeId,
                                      nombre: selectedRoute.routeName,
                                      sentido: "Ida/Vuelta", // You might want to fetch this too
                                      estado: true
                                    );
                                    Navigator.push(context, MaterialPageRoute(
                                      builder: (_) => RouteDetailScreen(ruta: tempRuta)
                                    ));
                                  },
                                )
                              ));
                            }
                          } catch (e) {
                             Navigator.pop(context); // Hide loading
                             print("Error finding routes: $e");
                             ScaffoldMessenger.of(context).showSnackBar(
                                 SnackBar(content: Text("Error buscando rutas: $e"))
                               );
                          }
                        },
                        child: const Text("Buscar ruta"),
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
