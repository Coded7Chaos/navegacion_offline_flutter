import 'dart:math';
import '../models/parada.dart';
import '../models/ruta.dart';
import '../models/ubicacion.dart';
import '../models/parada_ruta.dart';
import '../database/database_helper.dart';

/// Simple repository that wraps the existing SQLite helper.
/// Keeps a small in-memory cache so BLoCs can request data without
/// worrying about listeners or widget lifecycles.
class DataRepository {
  List<Parada> _paradas = [];
  List<Ruta> _rutas = [];

  Future<List<Parada>> loadParadas() async {
    if (_paradas.isNotEmpty) return _paradas;
    final db = await DatabaseHelper.instance.database;
    final List<Map<String, dynamic>> maps =
        await db.query('paradas', where: 'estado = ?', whereArgs: [1]);
    _paradas = List.generate(maps.length, (i) => Parada.fromMap(maps[i]));
    return _paradas;
  }

  Future<List<Ruta>> loadRutas() async {
    if (_rutas.isNotEmpty) return _rutas;
    final db = await DatabaseHelper.instance.database;
    final List<Map<String, dynamic>> maps =
        await db.query('rutas', where: 'estado = ?', whereArgs: [1]);
    _rutas = List.generate(maps.length, (i) => Ruta.fromMap(maps[i]));
    return _rutas;
  }

  Future<List<Ubicacion>> getRoutePolyline(int routeId) async {
    final db = await DatabaseHelper.instance.database;
    final List<Map<String, dynamic>> stopsInfo = await db.rawQuery('''
      SELECT pr.orden, pr.id_coordenada
      FROM paradaruta pr
      JOIN paradas p ON pr.id_parada = p.id_parada
      WHERE pr.id_ruta = ? AND p.estado = 1
      ORDER BY pr.orden
    ''', [routeId]);

    if (stopsInfo.isEmpty) return [];

    int startCoordId = stopsInfo.first['id_coordenada'] as int;
    final maxOrderStop = stopsInfo.reduce((curr, next) =>
        (curr['orden'] as int) > (next['orden'] as int) ? curr : next);
    int endCoordId = maxOrderStop['id_coordenada'] as int;

    final List<Map<String, dynamic>> coordsData = await db.rawQuery('''
      SELECT * FROM coordenadas 
      WHERE id_coordenada BETWEEN ? AND ? 
      ORDER BY id_coordenada
    ''', [startCoordId, endCoordId]);

    return coordsData
        .map((c) => Ubicacion(
              nombre: '',
              latitud: c['latitud'] as double,
              longitud: c['longitud'] as double,
            ))
        .toList();
  }

  Future<List<Ubicacion>> getPolylineBetweenCoords(
      int startCoordId, int endCoordId) async {
    final db = await DatabaseHelper.instance.database;
    final int a = min(startCoordId, endCoordId);
    final int b = max(startCoordId, endCoordId);

    final List<Map<String, dynamic>> coordsData = await db.rawQuery('''
      SELECT * FROM coordenadas
      WHERE id_coordenada BETWEEN ? AND ?
      ORDER BY id_coordenada
    ''', [a, b]);

    return coordsData
        .map((c) => Ubicacion(
              nombre: '',
              latitud: c['latitud'] as double,
              longitud: c['longitud'] as double,
            ))
        .toList();
  }

  Future<List<Parada>> getStopsForRoute(int routeId) async {
    final db = await DatabaseHelper.instance.database;
    final List<Map<String, dynamic>> maps = await db.rawQuery('''
      SELECT p.*
      FROM paradaruta pr
      JOIN paradas p ON pr.id_parada = p.id_parada
      WHERE pr.id_ruta = ? AND p.estado = 1
      ORDER BY pr.orden
    ''', [routeId]);

    return List.generate(maps.length, (i) => Parada.fromMap(maps[i]));
  }

  double _calculateDistance(
      double lat1, double lon1, double lat2, double lon2) {
    const double r = 6371000.0;
    double dLat = (lat2 - lat1) * (pi / 180.0);
    double dLon = (lon2 - lon1) * (pi / 180.0);
    double a = sin(dLat / 2) * sin(dLat / 2) +
        cos(lat1 * (pi / 180.0)) *
            cos(lat2 * (pi / 180.0)) *
            sin(dLon / 2) *
            sin(dLon / 2);
    double c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return r * c;
  }

  Future<List<Parada>> getNearbyStops(double lat, double lon) async {
    if (_paradas.isEmpty) await loadParadas();
    return _paradas
        .where((p) => _calculateDistance(lat, lon, p.lat, p.lon) < 600)
        .toList();
  }

  Future<List<int>> _getRouteIdsForStop(int paradaId) async {
    final db = await DatabaseHelper.instance.database;
    final result = await db
        .rawQuery('SELECT id_ruta FROM paradaruta WHERE id_parada = ?', [paradaId]);
    return result.map((r) => r['id_ruta'] as int).toList();
  }

  Future<ParadaRuta?> _getParadaRutaInfo(int paradaId, int rutaId) async {
    final db = await DatabaseHelper.instance.database;
    final result = await db.rawQuery(
        'SELECT * FROM paradaruta WHERE id_parada = ? AND id_ruta = ?',
        [paradaId, rutaId]);
    if (result.isNotEmpty) {
      return ParadaRuta.fromMap(result.first);
    }
    return null;
  }

  Future<String> _getRouteName(int routeId) async {
    final db = await DatabaseHelper.instance.database;
    final result = await db
        .rawQuery('SELECT nombre FROM rutas WHERE id_ruta_puma = ?', [routeId]);
    if (result.isNotEmpty) return result.first['nombre'] as String;
    return 'Ruta $routeId';
  }

  Future<List<RouteSearchResult>> findRoutes(
      double originLat, double originLon, double destLat, double destLon) async {
    final nearbyOrigin = await getNearbyStops(originLat, originLon);
    final nearbyDest = await getNearbyStops(destLat, destLon);

    if (nearbyOrigin.isEmpty || nearbyDest.isEmpty) return [];

    Map<int, List<int>> originRoutes = {};
    for (var p in nearbyOrigin) {
      originRoutes[p.idParada!] = await _getRouteIdsForStop(p.idParada!);
    }

    Map<int, List<int>> destRoutes = {};
    for (var p in nearbyDest) {
      destRoutes[p.idParada!] = await _getRouteIdsForStop(p.idParada!);
    }

    List<RouteSearchResult> candidates = [];

    for (var startStop in nearbyOrigin) {
      final startRouteIds = originRoutes[startStop.idParada!] ?? [];

      for (var endStop in nearbyDest) {
        final endRouteIds = destRoutes[endStop.idParada!] ?? [];

        final commonRoutes =
            startRouteIds.toSet().intersection(endRouteIds.toSet());

        for (var routeId in commonRoutes) {
          final startInfo = await _getParadaRutaInfo(startStop.idParada!, routeId);
          final endInfo = await _getParadaRutaInfo(endStop.idParada!, routeId);

          if (startInfo != null && endInfo != null && startInfo.orden < endInfo.orden) {
            double walkingDistOrigin = _calculateDistance(
                originLat, originLon, startStop.lat, startStop.lon);
            double walkingDistDest =
                _calculateDistance(destLat, destLon, endStop.lat, endStop.lon);

            candidates.add(RouteSearchResult(
                routeId: routeId,
                startStop: startStop,
                endStop: endStop,
                totalWalkingDistance: walkingDistOrigin + walkingDistDest,
                startInfo: startInfo,
                endInfo: endInfo));
          }
        }
      }
    }

    Map<int, RouteSearchResult> bestPerRoute = {};
    for (var c in candidates) {
      if (!bestPerRoute.containsKey(c.routeId) ||
          c.totalWalkingDistance < bestPerRoute[c.routeId]!.totalWalkingDistance) {
        bestPerRoute[c.routeId] = c;
      }
    }

    List<RouteSearchResult> finalResults = bestPerRoute.values.toList();
    for (var res in finalResults) {
      res.routeName = await _getRouteName(res.routeId);
    }

    finalResults.sort((a, b) => a.totalWalkingDistance.compareTo(b.totalWalkingDistance));
    return finalResults;
  }
}

class RouteSearchResult {
  final int routeId;
  String routeName;
  final Parada startStop;
  final Parada endStop;
  final double totalWalkingDistance;
  final ParadaRuta startInfo;
  final ParadaRuta endInfo;

  RouteSearchResult({
    required this.routeId,
    this.routeName = '',
    required this.startStop,
    required this.endStop,
    required this.totalWalkingDistance,
    required this.startInfo,
    required this.endInfo,
  });
}
