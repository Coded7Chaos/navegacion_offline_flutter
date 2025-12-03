import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/data_provider.dart';
import 'route_detail_screen.dart';

class RoutesScreen extends StatefulWidget {
  const RoutesScreen({super.key});

  @override
  State<RoutesScreen> createState() => _RoutesScreenState();
}

class _RoutesScreenState extends State<RoutesScreen> {
  @override
  void initState() {
    super.initState();
    // Load routes when screen opens
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<DataProvider>(context, listen: false).loadRutas();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Rutas Puma'),
      ),
      body: Consumer<DataProvider>(
        builder: (context, dataProvider, child) {
          if (dataProvider.rutas.isEmpty) {
             // If empty, it might be loading or actually empty. 
             // Since loadRutas is async but doesn't set a loading state flag in this simple provider,
             // we assume it's loading if empty initially or just show empty message.
             return const Center(child: Text('Cargando rutas o no disponibles...'));
          }
          return ListView.builder(
            itemCount: dataProvider.rutas.length,
            itemBuilder: (context, index) {
              final ruta = dataProvider.rutas[index];
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
                        builder: (context) => RouteDetailScreen(ruta: ruta),
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
