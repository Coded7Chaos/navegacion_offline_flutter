import 'package:flutter/material.dart';
import 'package:tflite_flutter/tflite_flutter.dart'; // Import needed for TfLiteType
import 'services/tflite_service.dart'; // Asegúrate que la ruta sea correcta
import 'ui/detector_screen.dart';

void main() {
  // 1. CRÍTICO: Inicializar el motor de Flutter antes de cargar plugins nativos.
  // Esto soluciona el error: "Could not create root isolate"
  WidgetsFlutterBinding.ensureInitialized();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Prueba TFLite',
      theme: ThemeData(primarySwatch: Colors.blue, useMaterial3: true),
      home: HomeScreen(),
    );
  }
}

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // Instanciamos el servicio
  final TfliteService _aiService = TfliteService();

  String _resultado = "Presiona el botón para probar";
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _cargarModelo();
  }

  Future<void> _cargarModelo() async {
    setState(() => _isLoading = true);
    await _aiService.loadModel();
    setState(() {
      _isLoading = false;
      _resultado = "Modelo cargado.\nListo para inferencia.\nInput Shape: ${_aiService.inputShape}";
    });
  }

  @override
  void dispose() {
    _aiService.dispose();
    super.dispose();
  }

  void _ejecutarPrueba() {
    setState(() {
      _resultado = "Generando datos de prueba...";
      _isLoading = true;
    });

    // Pequeño delay para que la UI se actualice antes de procesar
    Future.delayed(Duration(milliseconds: 100), () {
      try {
        // 2. GENERACIÓN DE DATOS DUMMY (MOCKING)
        // Usamos la forma REAL del modelo
        var shape = _aiService.inputShape;
        var type = _aiService.inputType;

        if (shape.isEmpty) {
             throw Exception("El modelo no reportó input shape.");
        }

        // Asumimos que es [Batch, Height, Width, Channels]
        // Si el modelo es diferente (ej: flatten), habría que adaptar.
        // Para SSD MobileNet suele ser [1, 300, 300, 3]
        
        int batch = shape.length > 0 ? shape[0] : 1;
        int height = shape.length > 1 ? shape[1] : 1;
        int width = shape.length > 2 ? shape[2] : 1;
        int channels = shape.length > 3 ? shape[3] : 1;

        // Generamos datos según el tipo esperado
        var dummyImage;
        
        if (type == TensorType.uint8) {
            // Para uint8 usamos enteros
             dummyImage = List.generate(
              batch,
              (i) => List.generate(
                height,
                (j) => List.generate(
                  width,
                  (k) => List.generate(
                    channels,
                    (l) => 0, 
                  ),
                ),
              ),
            );
        } else {
            // Para float32 usamos doubles
             dummyImage = List.generate(
              batch,
              (i) => List.generate(
                height,
                (j) => List.generate(
                  width,
                  (k) => List.generate(
                    channels,
                    (l) => 0.0, 
                  ),
                ),
              ),
            );
        }

        // Ejecutamos la inferencia
        var output = _aiService.runInference(dummyImage);

        // Si devuelve null o error string
        if (output == null || output is String) {
          setState(() {
            _resultado = "Error: $output";
            _isLoading = false;
          });
          return;
        }

        // Si recibimos un Mapa (Multi-output)
        if (output is Map) {
             setState(() {
                String details = "";
                output.forEach((index, val) {
                    // Intentamos sacar una muestra
                    var sample = "N/A";
                    if (val is List && val.isNotEmpty) {
                         // Acceder al primer elemento flattenizado de forma segura
                         dynamic first = val[0];
                         if (first is List) first = first[0]; 
                         if (first is List) first = first[0]; // Por si acaso 3D
                         sample = first.toString();
                    }
                    details += "Out $index: $sample\n";
                });
                
                _resultado = "✅ ¡Éxito (Multi-Output)!\n"
                             "Outputs recibidos: ${output.length}\n\n"
                             "$details";
                _isLoading = false;
             });
             return;
        }

        // Fallback por si acaso
        setState(() {
          _resultado = "Resultado recibido: $output";
          _isLoading = false;
        });
      } catch (e) {
        print("Error en UI: $e");
        setState(() {
          _resultado = "Error crítico: $e";
          _isLoading = false;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("TFLite System Check")),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Indicador de estado
              Container(
                padding: const EdgeInsets.all(15),
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.grey),
                ),
                child: Text(
                  _resultado,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 16, fontFamily: 'Courier'),
                ),
              ),
              const SizedBox(height: 30),

              if (_isLoading)
                const CircularProgressIndicator()
              else
                Column(
                  children: [
                    ElevatedButton.icon(
                      onPressed: _ejecutarPrueba,
                      icon: const Icon(Icons.memory),
                      label: const Text("Ejecutar Inferencia de Prueba"),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 30,
                          vertical: 15,
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton.icon(
                      onPressed: () {
                         Navigator.push(
                           context, 
                           MaterialPageRoute(builder: (_) => const DetectorScreen()),
                         );
                      },
                      icon: const Icon(Icons.camera_alt),
                      label: const Text("Modo Detección (Cámara)"),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 30,
                          vertical: 15,
                        ),
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ],
                ),

              const SizedBox(height: 20),
              const Text(
                "Nota: Esta prueba envía una 'imagen negra' generada por código para verificar que el puente C++/Dart funciona.",
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
          ),
        ),
      ),
    );
  }
}