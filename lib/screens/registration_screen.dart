import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../blocs/user/user_bloc.dart';
import '../blocs/user/user_event.dart';
import '../models/local_user.dart';

class RegistrationScreen extends StatefulWidget {
  const RegistrationScreen({super.key});

  @override
  State<RegistrationScreen> createState() => _RegistrationScreenState();
}

class _RegistrationScreenState extends State<RegistrationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nombres = TextEditingController();
  final _primerApellido = TextEditingController();
  final _segundoApellido = TextEditingController();
  final _telefono = TextEditingController();

  @override
  void dispose() {
    _nombres.dispose();
    _primerApellido.dispose();
    _segundoApellido.dispose();
    _telefono.dispose();
    super.dispose();
  }

  void _onSubmit() {
    if (!_formKey.currentState!.validate()) return;
    final user = LocalUser(
      nombres: _nombres.text.trim(),
      primerApellido: _primerApellido.text.trim(),
      segundoApellido: _segundoApellido.text.trim(),
      telefono: _telefono.text.trim(),
    );
    context.read<UserBloc>().add(UserRegistered(user));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      // Background handled by theme
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Image.asset('assets/images/alfiler.png',
                        height: 72, fit: BoxFit.contain),
                    const SizedBox(width: 12),
                    Image.asset('assets/images/hombre.png',
                        height: 72, fit: BoxFit.contain),
                  ],
                ),
                const SizedBox(height: 32),
                Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(24),
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(16),
                            gradient: LinearGradient(
                              colors: [theme.primaryColor, theme.colorScheme.secondary],
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: const [
                              Text(
                                'Bienvenido a Rutikal',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              SizedBox(height: 8),
                              Text(
                                'Sistema de Transporte Pumakatari - La Paz',
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 14,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),
                        Form(
                          key: _formKey,
                          child: Column(
                            children: [
                              _InputField(
                                controller: _nombres,
                                label: 'Nombres',
                                hint: 'Sus nombres',
                              ),
                              const SizedBox(height: 16),
                              _InputField(
                                controller: _primerApellido,
                                label: 'Primer Apellido',
                                hint: 'Su primer apellido',
                              ),
                              const SizedBox(height: 16),
                              _InputField(
                                controller: _segundoApellido,
                                label: 'Segundo Apellido',
                                hint: 'Su segundo apellido',
                              ),
                              const SizedBox(height: 16),
                              _InputField(
                                controller: _telefono,
                                label: 'Teléfono',
                                hint: 'Su número celular',
                                keyboardType: TextInputType.phone,
                              ),
                              const SizedBox(height: 24),
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton(
                                  onPressed: _onSubmit,
                                  style: ElevatedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 16),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    backgroundColor: theme.primaryColor,
                                    foregroundColor: Colors.white,
                                    elevation: 4,
                                  ),
                                  child: const Text(
                                    'Registrar Cuenta',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _InputField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String hint;
  final TextInputType keyboardType;

  const _InputField({
    required this.controller,
    required this.label,
    required this.hint,
    this.keyboardType = TextInputType.text,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 6),
          child: Text(label,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.primaryColor,
              )),
        ),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          validator: (v) =>
              (v == null || v.trim().isEmpty) ? 'Campo obligatorio' : null,
          decoration: InputDecoration(
            hintText: hint,
            // Uses theme decoration by default now, but we can override if needed
          ),
        ),
      ],
    );
  }
}
