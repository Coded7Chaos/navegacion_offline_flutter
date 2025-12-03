import 'package:flutter/material.dart';
import 'package:maplibre_gl/maplibre_gl.dart';
import 'package:geolocator/geolocator.dart';
import '../models/ubicacion.dart';
import '../models/parada.dart';

class MapProvider with ChangeNotifier {
  CameraPosition _cameraPosition = const CameraPosition(
    target: LatLng(-16.5000, -68.1193),
    zoom: 14,
  );
  CameraPosition get cameraPosition => _cameraPosition;

  LatLng? _originPoint;
  LatLng? get originPoint => _originPoint;

  LatLng? _destinationPoint;
  LatLng? get destinationPoint => _destinationPoint;

  bool _isSelectingDestination = false;
  bool get isSelectingDestination => _isSelectingDestination;

  String _searchValue = '';
  String get searchValue => _searchValue;

  List<Ubicacion> _searchResults = [];
  List<Ubicacion> get searchResults => _searchResults;

  void updateCameraPosition(CameraPosition position) {
    _cameraPosition = position;
    notifyListeners();
  }

  void setOrigin(LatLng point) {
    _originPoint = point;
    notifyListeners();
  }

  void setDestination(LatLng? point) {
    _destinationPoint = point;
    notifyListeners();
  }

  void setIsSelectingDestination(bool value) {
    _isSelectingDestination = value;
    notifyListeners();
  }

  void updateSearchValue(String value, List<Parada> allParadas) {
    _searchValue = value;
    if (value.isEmpty) {
      _searchResults = [];
    } else {
      _searchResults = allParadas
          .where((p) => p.nombre.toLowerCase().contains(value.toLowerCase()))
          .map((p) => Ubicacion(nombre: p.nombre, latitud: p.lat, longitud: p.lon))
          .toList();
    }
    notifyListeners();
  }

  Future<void> determinePosition() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return Future.error('Location services are disabled.');
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return Future.error('Location permissions are denied');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return Future.error(
          'Location permissions are permanently denied, we cannot request permissions.');
    }

    Position position = await Geolocator.getCurrentPosition();
    _originPoint = LatLng(position.latitude, position.longitude);
    _cameraPosition = CameraPosition(
        target: _originPoint!, zoom: 15);
    notifyListeners();
  }
}
