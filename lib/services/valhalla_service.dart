import 'dart:ffi'; // Para FFI
import 'dart:io'; // Para Platform
import 'package:ffi/ffi.dart'; // Necesitas agregar: flutter pub add ffi

// Definimos los tipos de C
typedef InitFunc = Pointer<Utf8> Function(Pointer<Utf8>);
typedef RouteFunc = Pointer<Utf8> Function(Double, Double);

// Definimos los tipos de Dart
typedef InitFuncDart = Pointer<Utf8> Function(Pointer<Utf8>);
typedef RouteFuncDart = Pointer<Utf8> Function(double, double);

class ValhallaService {
  late DynamicLibrary _nativeLib;
  late InitFuncDart _initValhalla;
  late RouteFuncDart _getRoute;

  ValhallaService() {

    if (Platform.isAndroid) {
      _nativeLib = DynamicLibrary.open('libvalhalla_native.so');
    } else if (Platform.isIOS){
      _nativeLib = DynamicLibrary.process();
    } else{
      throw UnsupportedError("Plataforma no soportada para Valhalla FFI");
    }

    
    _initValhalla = _nativeLib
        .lookup<NativeFunction<InitFunc>>('init_valhalla')
        .asFunction<InitFuncDart>();

    _getRoute = _nativeLib
        .lookup<NativeFunction<RouteFunc>>('get_route')
        .asFunction<RouteFuncDart>();
  }

  String inicializar(String configPath) {
    // Convertir String Dart -> String C
    final configC = configPath.toNativeUtf8();
    
    final resultC = _initValhalla(configC);
    
    // Leer resultado y liberar memoria
    final resultDart = resultC.toDartString();
    malloc.free(configC);
    
    return resultDart;
  }

  String obtenerRuta(double lat, double lon) {
    final resultC = _getRoute(lat, lon);
    return resultC.toDartString();
  }
}