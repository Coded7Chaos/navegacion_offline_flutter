import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../repositories/data_repository.dart';
import '../models/ruta.dart';
import 'route_detail_screen.dart';

class RoutesScreen extends StatefulWidget {
  const RoutesScreen({super.key});

  @override
  State<RoutesScreen> createState() => _RoutesScreenState();
}

class _RoutesScreenState extends State<RoutesScreen> {
  @override
  Widget build(BuildContext context) {
    final repository = RepositoryProvider.of<DataRepository>(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Rutas Puma'),
      ),
      body: FutureBuilder<List<Ruta>>(
        future: repository.loadRutas(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final rutas = snapshot.data!;
          if (rutas.isEmpty) {
            return const Center(child: Text('No hay rutas disponibles'));
          }
          return ListView.builder(
            itemCount: rutas.length,
            itemBuilder: (context, index) {
              final ruta = rutas[index];
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: ListTile(
                  leading: const Icon(Icons.directions_bus, color: Colors.blue),
                  title: Text(ruta.nombre, style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text(ruta.sentido),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => RouteDetailScreen(
                          ruta: ruta,
                          repository: repository,
                        ),
                      ),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}
