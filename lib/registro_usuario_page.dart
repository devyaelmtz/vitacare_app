import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

/// El registro público crea únicamente la cuenta base en users.
class RegistroUsuarioPage extends StatefulWidget {
  const RegistroUsuarioPage({super.key});

  @override
  State<RegistroUsuarioPage> createState() => _RegistroUsuarioPageState();
}

class _RegistroUsuarioPageState extends State<RegistroUsuarioPage> {
  final _formKey = GlobalKey<FormState>();
  final _controllers = {
    for (final field in [
      'email',
      'password',
      'nombre',
      'app',
      'apm',
      'telefono',
    ])
      field: TextEditingController(),
  };
  bool _cargando = false;
  bool _mostrarPassword = false;

  @override
  void dispose() {
    for (final controller in _controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _registrar() async {
    if (_cargando || !_formKey.currentState!.validate()) return;
    setState(() => _cargando = true);
    final host = !kIsWeb && defaultTargetPlatform == TargetPlatform.android
        ? 'http://10.0.2.2:3000'
        : 'http://localhost:3000';
    try {
      final response = await http.post(
        Uri.parse('$host/api/users'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          for (final field in _controllers.keys)
            field: field == 'password'
                ? _controllers[field]!.text
                : _controllers[field]!.text.trim(),
        }),
      );
      if (!mounted) return;
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      if (response.statusCode == 201) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Cuenta creada. Ya puedes iniciar sesión.'),
          ),
        );
        Navigator.pop(context);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(data['error'] ?? 'No se pudo crear la cuenta.'),
          ),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No se pudo conectar con el servidor.')),
        );
      }
    } finally {
      if (mounted) setState(() => _cargando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    const labels = {
      'nombre': 'Nombre(s)',
      'app': 'Apellido Paterno',
      'apm': 'Apellido Materno',
      'telefono': 'Teléfono',
      'email': 'Correo electrónico',
      'password': 'Contraseña',
    };
    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      appBar: AppBar(
        title: const Text('Crear cuenta'),
        backgroundColor: Colors.red,
        foregroundColor: Colors.white,
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(25),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    'Datos de la cuenta',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.red,
                    ),
                  ),
                  const SizedBox(height: 20),
                  for (final field in labels.keys) ...[
                    TextFormField(
                      controller: _controllers[field],
                      obscureText: field == 'password' && !_mostrarPassword,
                      keyboardType: field == 'email'
                          ? TextInputType.emailAddress
                          : field == 'telefono'
                              ? TextInputType.phone
                              : TextInputType.text,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Campo obligatorio';
                        }
                        if (field == 'email' &&
                            !RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$')
                                .hasMatch(value.trim())) {
                          return 'Correo inválido';
                        }
                        return null;
                      },
                      decoration: InputDecoration(
                        labelText: labels[field],
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        suffixIcon: field == 'password'
                            ? IconButton(
                                icon: Icon(
                                  _mostrarPassword
                                      ? Icons.visibility
                                      : Icons.visibility_off,
                                ),
                                onPressed: () => setState(
                                  () => _mostrarPassword = !_mostrarPassword,
                                ),
                              )
                            : null,
                      ),
                    ),
                    const SizedBox(height: 15),
                  ],
                  const SizedBox(height: 35),
                  SizedBox(
                    height: 55,
                    child: ElevatedButton(
                      onPressed: _cargando ? null : _registrar,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: _cargando
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text('CREAR CUENTA'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
