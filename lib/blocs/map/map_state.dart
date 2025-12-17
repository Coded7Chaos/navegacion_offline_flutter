import 'package:equatable/equatable.dart';
import 'package:maplibre_gl/maplibre_gl.dart';
import '../../models/ubicacion.dart';
import '../../repositories/data_repository.dart';

class MapState extends Equatable {
  static const Object _unset = Object();

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
    Object? userLocation = _unset,
    Object? destination = _unset,
    bool? selectionMode,
    String? searchQuery,
    List<Ubicacion>? searchResults,
    List<RouteSearchResult>? routeResults,
    Object? selectedRouteId = _unset,
    int? routeSelectionVersion,
    Object? error = _unset,
  }) {
    return MapState(
      loading: loading ?? this.loading,
      cameraPosition: cameraPosition ?? this.cameraPosition,
      userLocation: userLocation == _unset ? this.userLocation : userLocation as LatLng?,
      destination: destination == _unset ? this.destination : destination as LatLng?,
      selectionMode: selectionMode ?? this.selectionMode,
      searchQuery: searchQuery ?? this.searchQuery,
      searchResults: searchResults ?? this.searchResults,
      routeResults: routeResults ?? this.routeResults,
      selectedRouteId:
          selectedRouteId == _unset ? this.selectedRouteId : selectedRouteId as int?,
      routeSelectionVersion:
          routeSelectionVersion ?? this.routeSelectionVersion,
      error: error == _unset ? this.error : error as String?,
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
