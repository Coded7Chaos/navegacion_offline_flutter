# android/app/src/main/cpp/CMakeLists.txt
cmake_minimum_required(VERSION 3.10.2)

# Nombre de tu librería compartida
project("valhalla_native")

# Buscamos librerías del sistema (Log para debugear)
find_library(log-lib log)

# Definimos tu librería nativa
add_library(
        valhalla_native
        SHARED
        valhalla_bridge.cpp
)

# Enlazamos librerías
target_link_libraries(
        valhalla_native
        ${log-lib}
)