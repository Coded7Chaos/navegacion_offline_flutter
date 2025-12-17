import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../blocs/user/user_bloc.dart';
import '../blocs/user/user_event.dart';
import '../blocs/user/user_state.dart';
import '../models/local_user.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF8F3),
      body: SafeArea(
        child: BlocBuilder<UserBloc, UserState>(
          builder: (context, state) {
            if (state is! UserLoaded) {
              return const Center(child: CircularProgressIndicator());
            }
            final user = state.user;
            return Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 8),
                  Center(
                    child: Column(
                      children: [
                        Container(
                          width: 110,
                          height: 110,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: LinearGradient(
                              colors: [Color(0xFFD97846), Color(0xFFF4A942)],
                            ),
                          ),
                          child: const Icon(Icons.person,
                              size: 60, color: Colors.white),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          user.nombreCompleto,
                          style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 20,
                              color: Color(0xFF5C3A29)),
                        ),
                        Text(
                          user.telefono,
                          style: const TextStyle(color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  _ProfileTile(
                    icon: Icons.edit,
                    label: 'Editar información',
                    onTap: () => _openEdit(context, user),
                  ),
                  _ProfileTile(
                    icon: Icons.favorite,
                    label: 'Favoritos guardados',
                    onTap: () => _openList(
                      context,
                      'Favoritos',
                      state.favoritos.map((id) => 'Ruta $id').toList(),
                    ),
                  ),
                  _ProfileTile(
                    icon: Icons.history,
                    label: 'Historial de rutas',
                    onTap: () => _openList(context, 'Historial', state.historial),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  void _openEdit(BuildContext context, LocalUser user) {
    final nombres = TextEditingController(text: user.nombres);
    final pA = TextEditingController(text: user.primerApellido);
    final sA = TextEditingController(text: user.segundoApellido);
    final tel = TextEditingController(text: user.telefono);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            left: 16,
            right: 16,
            top: 16,
            bottom: 16 + MediaQuery.of(context).viewInsets.bottom,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Editar información',
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF5C3A29)),
              ),
              const SizedBox(height: 12),
              _EditField(controller: nombres, label: 'Nombres'),
              _EditField(controller: pA, label: 'Primer apellido'),
              _EditField(controller: sA, label: 'Segundo apellido'),
              _EditField(controller: tel, label: 'Teléfono'),
              const SizedBox(height: 14),
              ElevatedButton(
                onPressed: () {
                  context.read<UserBloc>().add(UserUpdated(LocalUser(
                        nombres: nombres.text.trim(),
                        primerApellido: pA.text.trim(),
                        segundoApellido: sA.text.trim(),
                        telefono: tel.text.trim(),
                      )));
                  Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFD97846),
                  foregroundColor: Colors.white,
                  minimumSize: const Size.fromHeight(44),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text('Guardar'),
              ),
            ],
          ),
        );
      },
    );
  }

  void _openList(BuildContext context, String title, List<String> items) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF5C3A29)),
                ),
                const SizedBox(height: 12),
                if (items.isEmpty)
                  const Padding(
                    padding: EdgeInsets.all(12.0),
                    child: Text('No hay elementos registrados'),
                  )
                else
                  Flexible(
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: items.length,
                      itemBuilder: (context, index) {
                        return ListTile(
                          leading: const Icon(Icons.route),
                          title: Text(items[index]),
                        );
                      },
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _ProfileTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _ProfileTile({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        onTap: onTap,
        leading: Container(
          width: 42,
          height: 42,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              colors: [Color(0xFFD97846), Color(0xFFF4A942)],
            ),
          ),
          child: Icon(icon, color: Colors.white),
        ),
        title: Text(label,
            style: const TextStyle(
                fontWeight: FontWeight.w600, color: Color(0xFF5C3A29))),
        trailing: const Icon(Icons.chevron_right),
      ),
    );
  }
}

class _EditField extends StatelessWidget {
  final TextEditingController controller;
  final String label;

  const _EditField({required this.controller, required this.label});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: TextField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          filled: true,
          fillColor: const Color(0xFFFFF1E3),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: Color(0xFFD97846)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: Color(0xFFD97846)),
          ),
        ),
      ),
    );
  }
}
