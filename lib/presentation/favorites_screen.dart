import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../blocs/user/user_bloc.dart';
import '../blocs/user/user_state.dart';
import '../models/ruta.dart';
import '../repositories/data_repository.dart';
import 'route_detail_screen.dart';

class FavoritesScreen extends StatelessWidget {
  const FavoritesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final repository = RepositoryProvider.of<DataRepository>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Favoritos'),
      ),
      body: BlocBuilder<UserBloc, UserState>(
        builder: (context, state) {
          if (state is! UserLoaded) {
            return const Center(child: CircularProgressIndicator());
          }

          final favIds = state.favoritos;
          if (favIds.isEmpty) {
            return const Center(child: Text('No tienes rutas favoritas.'));
          }

          return FutureBuilder<List<Ruta>>(
            future: repository.loadRutas(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }

              final rutas = snapshot.data!;
              final byId = <int, Ruta>{
                for (final r in rutas)
                  if (r.idRutaPuma != null) r.idRutaPuma!: r,
              };

              final favorites = favIds.map((id) {
                return byId[id] ??
                    Ruta(
                      idRutaPuma: id,
                      nombre: 'Ruta $id',
                      sentido: 'Ida/Vuelta',
                      estado: true,
                    );
              }).toList();

              return ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: favorites.length,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (context, index) {
                  final ruta = favorites[index];
                  return Card(
                    child: ListTile(
                      leading: const Icon(Icons.favorite, color: Colors.red),
                      title: Text(ruta.nombre),
                      subtitle: Text(ruta.sentido),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => RouteDetailScreen(
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
          );
        },
      ),
    );
  }
}
