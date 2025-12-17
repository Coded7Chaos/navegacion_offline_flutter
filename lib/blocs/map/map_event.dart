import 'package:equatable/equatable.dart';
import 'package:maplibre_gl/maplibre_gl.dart';

abstract class MapEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

class MapStarted extends MapEvent {}

class MapSearchChanged extends MapEvent {
  final String query;
  MapSearchChanged(this.query);

  @override
  List<Object?> get props => [query];
}

class MapDestinationSelected extends MapEvent {
  final LatLng destination;
  MapDestinationSelected(this.destination);

  @override
  List<Object?> get props => [destination];
}

class MapDestinationCleared extends MapEvent {}

class MapToggleSelectionMode extends MapEvent {}

class MapUserLocationRequested extends MapEvent {}

class MapRouteRequested extends MapEvent {}

class MapClearResults extends MapEvent {}
