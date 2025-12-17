import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../blocs/user/user_bloc.dart';
import '../blocs/user/user_event.dart';
import '../blocs/user/user_state.dart';
import '../models/local_user.dart';
import 'favorites_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      // Background handled by theme
      body: SafeArea(
        bottom: false, // For floating nav
        child: BlocBuilder<UserBloc, UserState>(
          builder: (context, state) {
            if (state is! UserLoaded) {
              return const Center(child: CircularProgressIndicator());
            }
            final user = state.user;
            return SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 100), // Bottom padding for nav
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const SizedBox(height: 20),
                  Stack(
                    alignment: Alignment.bottomRight,
                    children: [
                      Container(
                        width: 120,
                        height: 120,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white,
                          boxShadow: [
                            BoxShadow(
                              color: theme.primaryColor.withOpacity(0.2),
                              blurRadius: 20,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(4.0),
                          child: Container(
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  theme.primaryColor,
                                  theme.colorScheme.secondary,
                                ],
                              ),
                            ),
                            child: const Icon(Icons.person,
                                size: 64, color: Colors.white),
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 8,
                            ),
                          ],
                        ),
                        child: Icon(Icons.edit, size: 16, color: theme.primaryColor),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Text(
                    user.nombreCompleto,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: theme.textTheme.titleLarge?.color),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    user.telefono,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 32),
                  
                  // Menu Items
                  _ProfileTile(
                    icon: Icons.person_outline_rounded,
                    label: 'Editar información',
                    onTap: () => _openEdit(context, user),
                  ),
                  const SizedBox(height: 12),
                  _ProfileTile(
                    icon: Icons.favorite_border_rounded,
                    label: 'Favoritos guardados',
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const FavoritesScreen()),
                    ),
                  ),
                  const SizedBox(height: 12),
                  _ProfileTile(
                    icon: Icons.history_rounded,
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
    final theme = Theme.of(context);
    final nombres = TextEditingController(text: user.nombres);
    final pA = TextEditingController(text: user.primerApellido);
    final sA = TextEditingController(text: user.segundoApellido);
    final tel = TextEditingController(text: user.telefono);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
          ),
          child: Padding(
            padding: EdgeInsets.only(
              left: 20,
              right: 20,
              top: 20,
              bottom: 20 + MediaQuery.of(context).viewInsets.bottom,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                Text(
                  'Editar Perfil',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.primaryColor,
                  ),
                ),
                const SizedBox(height: 20),
                _EditField(controller: nombres, label: 'Nombres'),
                const SizedBox(height: 12),
                _EditField(controller: pA, label: 'Primer Apellido'),
                const SizedBox(height: 12),
                _EditField(controller: sA, label: 'Segundo Apellido'),
                const SizedBox(height: 12),
                _EditField(controller: tel, label: 'Teléfono'),
                const SizedBox(height: 24),
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
                    backgroundColor: theme.primaryColor,
                    foregroundColor: Colors.white,
                    minimumSize: const Size.fromHeight(50),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: const Text('Guardar Cambios'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _openList(BuildContext context, String title, List<String> items) {
    final theme = Theme.of(context);
    
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 20),
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  Text(
                    title,
                    style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: theme.primaryColor),
                  ),
                  const SizedBox(height: 20),
                  if (items.isEmpty)
                    Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Column(
                        children: [
                          Icon(Icons.inbox_rounded, size: 48, color: Colors.grey[300]),
                          const SizedBox(height: 12),
                          Text(
                            'No hay elementos registrados',
                            style: TextStyle(color: Colors.grey[500]),
                          ),
                        ],
                      ),
                    )
                  else
                    Flexible(
                      child: ListView.separated(
                        shrinkWrap: true,
                        itemCount: items.length,
                        separatorBuilder: (context, index) => const Divider(),
                        itemBuilder: (context, index) {
                          return ListTile(
                            leading: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: theme.primaryColor.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(Icons.history, color: theme.primaryColor),
                            ),
                            title: Text(items[index]),
                          );
                        },
                      ),
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
    final theme = Theme.of(context);
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: theme.primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(icon, color: theme.primaryColor),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    label,
                    style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600),
                  ),
                ),
                Icon(Icons.chevron_right, color: Colors.grey[300]),
              ],
            ),
          ),
        ),
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
    // Uses the Theme's inputDecorationTheme
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
      ),
    );
  }
}
