import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../blocs/alerts/alerts_bloc.dart';
import '../blocs/alerts/alerts_state.dart';
import '../models/alerta.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF8F3),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: BlocBuilder<AlertsBloc, AlertsState>(
            builder: (context, state) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 8),
                  const Text(
                    'Avisos y Notificaciones',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF5C3A29),
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Información importante sobre las rutas',
                    style: TextStyle(color: Colors.grey),
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: ListView.builder(
                      itemCount: state.alertas.length,
                      itemBuilder: (context, index) {
                        final alerta = state.alertas[index];
                        return _NotificationCard(
                          alerta: alerta,
                          onTap: () => _openAlertDetails(context, alerta),
                        );
                      },
                    ),
                  )
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  void _openAlertDetails(BuildContext context, Alerta alerta) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        alerta.rutaNombre,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFFD97846),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                  Text(
                    'Publicado el ${alerta.fecha}',
                    style: const TextStyle(color: Colors.grey),
                  ),
                  const SizedBox(height: 12),
                  _DetailSection(
                    title: 'Descripción',
                    child: Text(alerta.descripcionCompleta),
                  ),
                  if (alerta.paradasAfectadas.isNotEmpty)
                    _DetailSection(
                      title: 'Paradas afectadas',
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: alerta.paradasAfectadas
                            .map((e) => Text('• $e'))
                            .toList(),
                      ),
                    ),
                  if (alerta.paradasAlternativas.isNotEmpty)
                    _DetailSection(
                      title: 'Paradas alternativas',
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: alerta.paradasAlternativas
                            .map((e) => Text('• $e'))
                            .toList(),
                      ),
                    ),
                  _DetailSection(
                    title: 'Motivo',
                    child: Text(alerta.motivo),
                  ),
                  const SizedBox(height: 10),
                  ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFD97846),
                      foregroundColor: Colors.white,
                      minimumSize: const Size.fromHeight(44),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text('Cerrar'),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _NotificationCard extends StatelessWidget {
  final Alerta alerta;
  final VoidCallback onTap;

  const _NotificationCard({required this.alerta, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      margin: const EdgeInsets.symmetric(vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: ListTile(
        onTap: onTap,
        leading: Container(
          width: 50,
          height: 50,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              colors: [Color(0xFFD97846), Color(0xFFF4A942)],
            ),
          ),
          child: const Icon(Icons.priority_high, color: Colors.white),
        ),
        title: Text(alerta.rutaNombre,
            style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              alerta.descripcionCorta,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Text(
              alerta.fecha,
              style: const TextStyle(color: Colors.grey, fontSize: 12),
            ),
          ],
        ),
        trailing: const Icon(Icons.chevron_right),
      ),
    );
  }
}

class _DetailSection extends StatelessWidget {
  final String title;
  final Widget child;

  const _DetailSection({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF1E3),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
                fontWeight: FontWeight.w600, color: Color(0xFF5C3A29)),
          ),
          const SizedBox(height: 6),
          child,
        ],
      ),
    );
  }
}
