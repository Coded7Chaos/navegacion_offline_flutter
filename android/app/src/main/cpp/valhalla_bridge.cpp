#include <jni.h>
#include <string>
#include <android/log.h>

// Macro para imprimir logs en Android Logcat
#define LOG_TAG "ValhallaNative"
#define LOGD(...) __android_log_print(ANDROID_LOG_DEBUG, LOG_TAG, __VA_ARGS__)

// EXTERN "C" es obligatorio para evitar que C++ cambie los nombres de función
extern "C" {

    // Función de prueba: Inicializar
    // __attribute__((visibility("default"))) hace visible la función para Dart
    __attribute__((visibility("default")))
    const char* init_valhalla(char* configPath) {
        LOGD("Inicializando Valhalla con config: %s", configPath);
        
        // AQUÍ IRÁ LA LÓGICA REAL DE VALHALLA MÁS ADELANTE
        
        return "Valhalla Inicializado Correctamente (Mock)";
    }

    // Función de prueba: Calcular Ruta
    __attribute__((visibility("default")))
    const char* get_route(double lat, double lon) {
        LOGD("Calculando ruta desde: %f, %f", lat, lon);
        
        // Simulamos devolver un JSON
        return "{ \"trip\": { \"status\": \"success\" } }";
    }
}