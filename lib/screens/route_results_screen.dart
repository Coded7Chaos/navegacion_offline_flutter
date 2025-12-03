import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:maplibre_gl/maplibre_gl.dart';
import '../providers/data_provider.dart';
import '../models/parada.dart';

class RouteResultsScreen extends StatelessWidget {
  final List<RouteSearchResult> results;
  final Function(RouteSearchResult) onResultSelected;

  const RouteResultsScreen({
    super.key, 
    required this.results,
    required this.onResultSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${results.length} Rutas encontradas'),
      ),
      body: results.isEmpty
          ? const Center(child: Text('No se encontraron rutas directas.'))
          : ListView.builder(
              itemCount: results.length,
              itemBuilder: (context, index) {
                final res = results[index];
                return Card(
                  margin: const EdgeInsets.all(8),
                  child: ListTile(
                    leading: const Icon(Icons.directions_bus, size: 40, color: Colors.blue),
                    title: Text(res.routeName, style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('De: ${res.startStop.nombre}'),
                        Text('A: ${res.endStop.nombre}'),
                        Text('Distancia a caminar: ${(res.totalWalkingDistance).toStringAsFixed(0)} m'),
                      ],
                    ),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => onResultSelected(res),
                  ),
                );
              },
            ),
    );
  }
}
