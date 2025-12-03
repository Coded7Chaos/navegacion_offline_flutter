import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/data_provider.dart';
import '../models/parada.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    // Load data when screen initializes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<DataProvider>(context, listen: false).loadParadas();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Navegación Offline'),
        actions: [
          IconButton(
            icon: const Icon(Icons.person),
            onPressed: () {
              // Navigate to User Screen (placeholder)
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Ir a perfil de usuario')),
              );
            },
          ),
        ],
      ),
      body: Consumer<DataProvider>(
        builder: (context, dataProvider, child) {
          if (dataProvider.paradas.isEmpty) {
            return const Center(
              child: Text('No hay paradas disponibles'),
            );
          }
          return ListView.builder(
            itemCount: dataProvider.paradas.length,
            itemBuilder: (context, index) {
              final parada = dataProvider.paradas[index];
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: ListTile(
                  title: Text(parada.nombre),
                  subtitle: Text('${parada.lat}, ${parada.lon}'),
                  trailing: const Icon(Icons.directions_bus),
                  onTap: () {
                    // Handle tap if needed
                  },
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Placeholder for adding stop
           ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Agregar parada')),
              );
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
