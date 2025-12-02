import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:maplibre_gl/maplibre_gl.dart';

void main() {
  runApp(const MaterialApp(home: MapaOfflinePage()));
}

class MapaOfflinePage extends StatefulWidget {
  const MapaOfflinePage({super.key});

  @override
  State<MapaOfflinePage> createState() => _MapaOfflinePageState();
}

class _MapaOfflinePageState extends State<MapaOfflinePage> {
  // Variables para guardar las rutas finales en el celular
  late String _stylePath;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _prepararArchivosOffline();
  }

  /// Esta función copia los assets al almacenamiento del dispositivo
  Future<void> _prepararArchivosOffline() async {
    try {
      // 1. Obtener directorio de documentos de la app
      final directory = await getApplicationDocumentsDirectory();
      final mapsDir = Directory('${directory.path}/maps');
      if (!await mapsDir.exists()) await mapsDir.create();

      // 2. Copiar el MBTiles (el mapa pesado)
      final mbtilesPath = '${mapsDir.path}/lapaz.mbtiles';
      if (!File(mbtilesPath).existsSync()) {
        final byteData = await rootBundle.load('assets/maps/lapaz.mbtiles');
        await File(mbtilesPath).writeAsBytes(byteData.buffer.asUint8List());
        print("MBTiles copiado a: $mbtilesPath");
      }

      // 3. Leer y modificar el style.json dinámicamente
      final styleString = await rootBundle.loadString('assets/maps/style.json');
      
      // AQUÍ OCURRE LA MAGIA: Reemplazamos el placeholder con la ruta real del mbtiles
      // La sintaxis 'mbtiles://' le dice a MapLibre que es un archivo local
      final finalStyle = styleString.replaceFirst(
        '{path_to_mbtiles}', 
        mbtilesPath
      );

      // 4. Guardar el style.json final listo para usarse
      final styleFile = File('${mapsDir.path}/style_final.json');
      await styleFile.writeAsString(finalStyle);

      setState(() {
        _stylePath = styleFile.path;
        _isLoading = false;
      });

    } catch (e) {
      print("Error preparando mapas: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 20),
            Text("Copiando mapas al dispositivo...\n(Esto solo pasa la primera vez)"),
          ],
        )),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text("La Paz Offline")),
      body: MaplibreMap(
        // Coordenadas de La Paz, Bolivia
        initialCameraPosition: const CameraPosition(
          target: LatLng(-16.5000, -68.1193), 
          zoom: 12,
        ),
        // Usamos el archivo de estilo que acabamos de generar
        styleString: _stylePath, 
        
        onMapCreated: (MaplibreMapController controller) {
          print("Mapa cargado exitosamente");
        },
      ),
    );
  }
}