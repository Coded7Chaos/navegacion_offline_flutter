import 'package:equatable/equatable.dart';
import 'package:maplibre_gl/maplibre_gl.dart';
import '../../models/ubicacion.dart';
import '../../repositories/data_repository.dart';

class MapState extends Equatable {
  final bool loading;
  final LatLng cameraPosition;
  final LatLng? userLocation;
  final LatLng? destination;
  final bool selectionMode;
  final String searchQuery;
  final List<Ubicacion> searchResults;
  final List<RouteSearchResult> routeResults;
  final int? selectedRouteId;
  final int routeSelectionVersion;
  final String? error;

  const MapState({
    this.loading = false,
    this.cameraPosition = const LatLng(-16.5000, -68.1193),
    this.userLocation,
    this.destination,
    this.selectionMode = false,
    this.searchQuery = '',
    this.searchResults = const [],
    this.routeResults = const [],
    this.selectedRouteId,
    this.routeSelectionVersion = 0,
    this.error,
  });

  MapState copyWith({
    bool? loading,
    LatLng? cameraPosition,
    LatLng? userLocation,
    LatLng? destination,
    bool? selectionMode,
    String? searchQuery,
    List<Ubicacion>? searchResults,
    List<RouteSearchResult>? routeResults,
    int? selectedRouteId,
    int? routeSelectionVersion,
    String? error,
  }) {
    return MapState(
      loading: loading ?? this.loading,
      cameraPosition: cameraPosition ?? this.cameraPosition,
      userLocation: userLocation ?? this.userLocation,
      destination: destination,
      selectionMode: selectionMode ?? this.selectionMode,
      searchQuery: searchQuery ?? this.searchQuery,
      searchResults: searchResults ?? this.searchResults,
      routeResults: routeResults ?? this.routeResults,
      selectedRouteId: selectedRouteId ?? this.selectedRouteId,
      routeSelectionVersion:
          routeSelectionVersion ?? this.routeSelectionVersion,
      error: error,
    );
  }

  @override
  List<Object?> get props => [
        loading,
        cameraPosition,
        userLocation,
        destination,
        selectionMode,
        searchQuery,
        searchResults,
        routeResults,
        selectedRouteId,
        routeSelectionVersion,
        error,
      ];
}
