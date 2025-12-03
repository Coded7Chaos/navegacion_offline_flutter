import 'package:flutter/services.dart';

class ValhallaService {
  // Canal de comunicación con Kotlin
  static const platform = MethodChannel('com.tudeveloper.valhalla/route');

  Future<String> obtenerRuta(String jsonRequest) async {
    try {
      // Le decimos a Kotlin: "Oye, calcula esta ruta"
      // Nota: Necesitas pasarle la ruta a un archivo valhalla.json real en el celular
      // Por ahora enviamos un path dummy para probar que responde
      final String result = await platform.invokeMethod('getRoute', {
        'configPath': '/data/user/0/com.tu.app/files/valhalla.json', 
        'requestJson': jsonRequest
      });
      return result;
    } on PlatformException catch (e) {
      return "Error de Valhalla: '${e.message}'.";
    }
  }
}