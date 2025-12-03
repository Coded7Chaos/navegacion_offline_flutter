import 'dart:io';

import 'package:app_navegacion_offline/models/geo_point.dart';
import 'package:app_navegacion_offline/models/location_point.dart';
import 'package:app_navegacion_offline/models/puma_route.dart';
import 'package:app_navegacion_offline/models/search_result.dart';
import 'package:app_navegacion_offline/models/route_schedule.dart';
import 'package:flutter/services.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

class RouteDatabaseService {
  RouteDatabaseService._();

  static final RouteDatabaseService instance = RouteDatabaseService._();

  Database? _database;

  Future<Database> get _db async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final documentsDir = await getApplicationDocumentsDirectory();
    final dbPath = p.join(documentsDir.path, 'transporte_app.db');
    final file = File(dbPath);

    if (!await file.exists()) {
      final byteData = await rootBundle.load('assets/maps/transporte_app.db');
      await file.writeAsBytes(byteData.buffer.asUint8List(), flush: true);
    }

    return openDatabase(dbPath, readOnly: true);
  }

  Future<void> ensureInitialized() async {
    await _db;
  }

  Future<List<LocationPoint>> _searchPlaces(String query) async {
    final database = await _db;
    final likeQuery = '%${query.toUpperCase()}%';

    final ubicaciones = await database.rawQuery(
      'SELECT id_ubicacion, nombre, latitud, longitud FROM ubicaciones WHERE UPPER(nombre) LIKE ? LIMIT 8',
      [likeQuery],
    );

    final paradas = await database.rawQuery(
      'SELECT id_parada, nombre, latitud, longitud, direccion FROM paradas WHERE UPPER(nombre) LIKE ? LIMIT 5',
      [likeQuery],
    );

    final locationResults = ubicaciones
        .map((row) => LocationPoint.fromMap(
              Map<String, Object?>.from(row),
              LocationPointType.location,
            ))
        .toList();

    final stopResults = paradas
        .map((row) => LocationPoint.fromMap(
              Map<String, Object?>.from(row),
              LocationPointType.stop,
            ))
        .toList();

    return [...locationResults, ...stopResults];
  }

  Future<List<PumaRoute>> _searchRoutes(String query) async {
    final database = await _db;
    final likeQuery = '%${query.toUpperCase()}%';
    final rows = await database.rawQuery(
      'SELECT id_ruta_puma, nombre, sentido, estado FROM rutas WHERE UPPER(nombre) LIKE ? ORDER BY nombre LIMIT 5',
      [likeQuery],
    );

    return rows
        .map((row) => PumaRoute.fromMap(Map<String, Object?>.from(row)))
        .toList();
  }

  Future<List<PumaRoute>> getAllRoutes() async {
    final database = await _db;
    final rows = await database.query(
      'rutas',
      columns: ['id_ruta_puma', 'nombre', 'sentido', 'estado'],
      orderBy: 'nombre ASC',
    );
    return rows
        .map((row) => PumaRoute.fromMap(Map<String, Object?>.from(row)))
        .toList();
  }

  Future<List<LocationPoint>> getStopsForRoute(int routeId) async {
    final database = await _db;
    final rows = await database.rawQuery(
      '''
      SELECT p.id_parada, p.nombre, p.direccion, p.latitud, p.longitud, pr.min_orden
      FROM paradas p
      INNER JOIN (
        SELECT id_parada, MIN(orden) AS min_orden
        FROM paradaruta
        WHERE id_ruta = ? AND id_parada IS NOT NULL
        GROUP BY id_parada
      ) pr ON pr.id_parada = p.id_parada
      WHERE p.latitud IS NOT NULL AND p.longitud IS NOT NULL
      ORDER BY pr.min_orden ASC
      ''',
      [routeId],
    );

    return rows
        .map((row) => LocationPoint.fromMap(
              Map<String, Object?>.from(row),
              LocationPointType.stop,
            ))
        .toList();
  }

  Future<List<GeoPoint>> getRoutePolyline(int routeId) async {
    final database = await _db;
    final rows = await database.rawQuery(
      '''
      SELECT c.latitud, c.longitud
      FROM paradaruta pr
      INNER JOIN coordenadas c ON pr.id_coordenada = c.id_coordenada
      WHERE pr.id_ruta = ? AND c.latitud IS NOT NULL AND c.longitud IS NOT NULL
      ORDER BY pr.orden ASC
      ''',
      [routeId],
    );

    return rows
        .map((row) => GeoPoint(
              latitude: (row['latitud'] as num).toDouble(),
              longitude: (row['longitud'] as num).toDouble(),
            ))
        .toList();
  }

  Future<List<SearchResult>> search(String query) async {
    final normalized = query.trim();
    if (normalized.length < 2) return [];

    final places = await _searchPlaces(normalized);
    final routes = await _searchRoutes(normalized);

    final results = <SearchResult>[];
    results.addAll(places.map(SearchResult.fromLocation));
    results.addAll(routes.map(SearchResult.fromRoute));

    return results;
  }

  Future<List<RouteSchedule>> getRouteSchedules(int routeId) async {
    final database = await _db;
    final rows = await database.rawQuery(
      '''
      SELECT DISTINCT d.descripcion AS dia, h.hora_inicio, h.hora_final
      FROM ruta_horario rh
      INNER JOIN dia_horario dh ON dh.id_horario = rh.id_horario
      INNER JOIN dia d ON d.dia_id = dh.dia_id
      INNER JOIN horario h ON h.id_horario = rh.id_horario
      WHERE rh.id_ruta_puma = ? AND h.hora_inicio IS NOT NULL AND h.hora_final IS NOT NULL
      ORDER BY dh.dia_id
      ''',
      [routeId],
    );

    return rows
        .map(
          (row) => RouteSchedule(
            dayDescription: (row['dia'] as String?) ?? 'Sin día',
            startTime: (row['hora_inicio'] as int?) ?? 0,
            endTime: (row['hora_final'] as int?) ?? 0,
          ),
        )
        .toList();
  }
}
