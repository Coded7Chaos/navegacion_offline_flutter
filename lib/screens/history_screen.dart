import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:maplibre_gl/maplibre_gl.dart';

import '../blocs/user/user_bloc.dart';
import '../blocs/user/user_state.dart';
import '../models/history_entry.dart';
import '../models/parada.dart';
import '../models/parada_ruta.dart';
import '../repositories/data_repository.dart';
import 'route_segment_screen.dart';

class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final repository = RepositoryProvider.of<DataRepository>(context);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Historial de rutas')),
      body: BlocBuilder<UserBloc, UserState>(
        builder: (context, state) {
          if (state is! UserLoaded) {
            return const Center(child: CircularProgressIndicator());
          }
          final items = state.historial;
          if (items.isEmpty) {
            return const Center(child: Text('No hay búsquedas en el historial.'));
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: items.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              final entry = items[index];
              final time =
                  '${entry.timestamp.hour.toString().padLeft(2, '0')}:${entry.timestamp.minute.toString().padLeft(2, '0')}';
              final date =
                  '${entry.timestamp.day.toString().padLeft(2, '0')}/${entry.timestamp.month.toString().padLeft(2, '0')}';

              return Card(
                child: ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: theme.primaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(Icons.history, color: theme.primaryColor),
                  ),
                  title: Text(
                    entry.routeName.isEmpty ? 'Ruta ${entry.routeId}' : entry.routeName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Sube: ${entry.boardStopName}'),
                      Text('Baja: ${entry.alightStopName}'),
                      Text('$date • $time'),
                    ],
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: entry.canReplay
                      ? () {
                          final result = _toRouteSearchResult(entry);
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => RouteSegmentScreen(
                                result: result,
                                repository: repository,
                                origin: LatLng(entry.originLat, entry.originLon),
                                destination:
                                    LatLng(entry.destinationLat, entry.destinationLon),
                              ),
                            ),
                          );
                        }
                      : null,
                ),
              );
            },
          );
        },
      ),
    );
  }

  RouteSearchResult _toRouteSearchResult(HistoryEntry entry) {
    final startStop = Parada(
      idParada: entry.boardStopId,
      lat: entry.boardStopLat,
      lon: entry.boardStopLon,
      nombre: entry.boardStopName,
      direccion: '',
      estado: true,
    );
    final endStop = Parada(
      idParada: entry.alightStopId,
      lat: entry.alightStopLat,
      lon: entry.alightStopLon,
      nombre: entry.alightStopName,
      direccion: '',
      estado: true,
    );

    final startInfo = ParadaRuta(
      idRuta: entry.routeId,
      idParada: entry.boardStopId ?? 0,
      orden: entry.boardOrder,
      tiempo: 0,
      idCoordenada: entry.boardCoordId,
    );
    final endInfo = ParadaRuta(
      idRuta: entry.routeId,
      idParada: entry.alightStopId ?? 0,
      orden: entry.alightOrder,
      tiempo: 0,
      idCoordenada: entry.alightCoordId,
    );

    return RouteSearchResult(
      routeId: entry.routeId,
      routeName: entry.routeName,
      startStop: startStop,
      endStop: endStop,
      totalWalkingDistance: entry.totalWalkingDistance,
      startInfo: startInfo,
      endInfo: endInfo,
    );
  }
}
