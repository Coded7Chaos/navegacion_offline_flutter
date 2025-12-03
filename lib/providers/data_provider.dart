import 'package:flutter/foundation.dart';
import '../models/parada.dart';
import '../models/ruta.dart';
import '../models/ubicacion.dart';
import '../database/database_helper.dart';

class DataProvider with ChangeNotifier {
  List<Parada> _paradas = [];
  List<Parada> get paradas => _paradas;

  List<Ruta> _rutas = [];
  List<Ruta> get rutas => _rutas;

  Future<void> loadParadas() async {
    final db = await DatabaseHelper.instance.database;
    final List<Map<String, dynamic>> maps = await db.query('paradas', where: 'estado = ?', whereArgs: [1]);
    _paradas = List.generate(maps.length, (i) => Parada.fromMap(maps[i]));
    notifyListeners();
  }

  Future<void> loadRutas() async {
    final db = await DatabaseHelper.instance.database;
    final List<Map<String, dynamic>> maps = await db.query('rutas', where: 'estado = ?', whereArgs: [1]);
    _rutas = List.generate(maps.length, (i) => Ruta.fromMap(maps[i]));
    notifyListeners();
  }

  Future<void> addParada(Parada parada) async {
    final db = await DatabaseHelper.instance.database;
    await db.insert('paradas', parada.toMap());
    await loadParadas();
  }

  // Logic to get route polyline points (Coordinates)
  Future<List<Ubicacion>> getRoutePolyline(int routeId) async {
    final db = await DatabaseHelper.instance.database;

    // 1. Get ordered stops to find start and end coordinate IDs
    final List<Map<String, dynamic>> stopsInfo = await db.rawQuery('''
      SELECT pr.orden, pr.id_coordenada
      FROM paradaruta pr
      JOIN paradas p ON pr.id_parada = p.id_parada
      WHERE pr.id_ruta = ? AND p.estado = 1
      ORDER BY pr.orden
    ''', [routeId]);

    if (stopsInfo.isEmpty) return [];

    int startCoordId = stopsInfo.first['id_coordenada'] as int;
    // Find max order
    final maxOrderStop = stopsInfo.reduce((curr, next) => 
      (curr['orden'] as int) > (next['orden'] as int) ? curr : next);
    int endCoordId = maxOrderStop['id_coordenada'] as int;

    // 2. Fetch all coordinates between start and end
    final List<Map<String, dynamic>> coordsData = await db.rawQuery('''
      SELECT * FROM coordenadas 
      WHERE id_coordenada BETWEEN ? AND ? 
      ORDER BY id_coordenada
    ''', [startCoordId, endCoordId]);

    return coordsData.map((c) => Ubicacion(
      nombre: '', // Not needed for polyline
      latitud: c['latitud'] as double,
      longitud: c['longitud'] as double,
    )).toList();
  }

  // Logic to get actual stops for the route (to show markers)
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
}
