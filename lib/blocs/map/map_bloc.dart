import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:geolocator/geolocator.dart';
import 'package:maplibre_gl/maplibre_gl.dart';
import '../../repositories/data_repository.dart';
import '../../models/ubicacion.dart';
import 'map_event.dart';
import 'map_state.dart';

class MapBloc extends Bloc<MapEvent, MapState> {
  final DataRepository repository;

  MapBloc({required this.repository}) : super(const MapState()) {
    on<MapStarted>(_onStarted);
    on<MapSearchChanged>(_onSearchChanged);
    on<MapDestinationSelected>(_onDestinationSelected);
    on<MapDestinationCleared>(_onDestinationCleared);
    on<MapToggleSelectionMode>(_onToggleSelectionMode);
    on<MapUserLocationRequested>(_onUserLocationRequested);
    on<MapRouteRequested>(_onRouteRequested);
    on<MapClearResults>(_onClearResults);
  }

  Future<void> _onStarted(MapStarted event, Emitter<MapState> emit) async {
    emit(state.copyWith(loading: true));
    await repository.loadParadas();
    await _requestLocation(emit);
    emit(state.copyWith(loading: false));
  }

  Future<void> _requestLocation(Emitter<MapState> emit) async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return;

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return;
    }
    if (permission == LocationPermission.deniedForever) return;

    final position = await Geolocator.getCurrentPosition();
    emit(state.copyWith(
      userLocation: LatLng(position.latitude, position.longitude),
      cameraPosition: LatLng(position.latitude, position.longitude),
    ));
  }

  Future<void> _onUserLocationRequested(
      MapUserLocationRequested event, Emitter<MapState> emit) async {
    await _requestLocation(emit);
  }

  Future<void> _onSearchChanged(
      MapSearchChanged event, Emitter<MapState> emit) async {
    final query = event.query;
    if (query.isEmpty) {
      emit(state.copyWith(searchQuery: '', searchResults: const []));
      return;
    }
    final paradas = await repository.loadParadas();
    final results = paradas
        .where((p) => p.nombre.toLowerCase().contains(query.toLowerCase()))
        .map((p) => Ubicacion(nombre: p.nombre, latitud: p.lat, longitud: p.lon))
        .toList();
    emit(state.copyWith(searchQuery: query, searchResults: results));
  }

  void _onDestinationSelected(
      MapDestinationSelected event, Emitter<MapState> emit) {
    emit(state.copyWith(
      destination: event.destination,
      selectionMode: false,
      searchResults: const [],
    ));
  }

  void _onDestinationCleared(
      MapDestinationCleared event, Emitter<MapState> emit) {
    emit(state.copyWith(destination: null, routeResults: const []));
  }

  void _onToggleSelectionMode(
      MapToggleSelectionMode event, Emitter<MapState> emit) {
    emit(state.copyWith(selectionMode: !state.selectionMode));
  }

  Future<void> _onRouteRequested(
      MapRouteRequested event, Emitter<MapState> emit) async {
    if (state.userLocation == null || state.destination == null) return;
    emit(state.copyWith(loading: true, error: null));
    try {
      final results = await repository.findRoutes(
        state.userLocation!.latitude,
        state.userLocation!.longitude,
        state.destination!.latitude,
        state.destination!.longitude,
      );
      emit(state.copyWith(loading: false, routeResults: results));
    } catch (e) {
      emit(state.copyWith(
          loading: false, error: 'Error buscando rutas: ${e.toString()}'));
    }
  }

  void _onClearResults(MapClearResults event, Emitter<MapState> emit) {
    emit(state.copyWith(routeResults: const []));
  }
}
