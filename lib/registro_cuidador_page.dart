import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import 'services/api_session.dart';

import 'package:flutter/material.dart';

class RegistroCuidadorPage extends StatefulWidget {
  const RegistroCuidadorPage({super.key});

  @override
  State<RegistroCuidadorPage> createState() => _RegistroCuidadorPageState();
}

class _RegistroCuidadorPageState extends State<RegistroCuidadorPage> {
  // Controladores de texto para los campos
  final TextEditingController nombreController = TextEditingController();
  final TextEditingController appController = TextEditingController();
  final TextEditingController apmController = TextEditingController();
  final TextEditingController telefonoController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  final TextEditingController numeroLicenciaController =
      TextEditingController();
  final TextEditingController parentescoRelacionController =
      TextEditingController();

  // Bandera para la contraseña
  bool mostrarPassword = false;
  bool _estaCargando = false;

  @override
  void dispose() {
    for (final controller in [
      nombreController,
      appController,
      apmController,
      telefonoController,
      emailController,
      passwordController,
      numeroLicenciaController,
      parentescoRelacionController,
    ]) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _registrarCuidador() async {
    if (!ApiSession.isAdmin || _estaCargando) return;
    if ([
      nombreController,
      appController,
      apmController,
      telefonoController,
      emailController,
      passwordController,
    ].any((c) => c.text.trim().isEmpty)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Completa todos los datos personales.')),
      );
      return;
    }
    setState(() => _estaCargando = true);
    final host = !kIsWeb && defaultTargetPlatform == TargetPlatform.android
        ? 'http://10.0.2.2:3000'
        : 'http://localhost:3000';
    try {
      final response = await http.post(
        Uri.parse('$host/api/cuidadores'),
        headers: ApiSession.headers,
        body: jsonEncode({
          'email': emailController.text.trim(),
          'password': passwordController.text,
          'nombre': nombreController.text.trim(),
          'app': appController.text.trim(),
          'apm': apmController.text.trim(),
          'telefono': telefonoController.text.trim(),
          'numeroLicencia': numeroLicenciaController.text.trim(),
          'parentescoRelacion': parentescoRelacionController.text.trim(),
        }),
      );
      if (!mounted) return;
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      if (response.statusCode == 201) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Cuidador registrado correctamente.')),
        );
        Navigator.pop(context);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(data['error'] ?? 'Error al registrar cuidador.'),
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
      if (mounted) setState(() => _estaCargando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!ApiSession.isAdmin) {
      return const Scaffold(
        body: Center(child: Text('Acceso exclusivo del administrador.')),
      );
    }
    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      appBar: AppBar(
        title: const Text('Registro de Cuidador'),
        backgroundColor: Colors.blueAccent,
        foregroundColor: Colors.white,
      ),
      body: _crearContenido(),
    );
  }

  Widget _crearContenido() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(25),
      child: Column(
        children: [
          _crearTitulo('Datos del Cuidador', Colors.blueAccent),
          _crearSizedBox(20),
          _crearCampoTexto(
            'Nombre(s)',
            'Ingresa tu nombre',
            Icons.person,
            nombreController,
            TextInputType.name,
          ),
          _crearSizedBox(15),
          _crearCampoTexto(
            'Apellido Paterno',
            'Ingresa tu apellido paterno',
            Icons.person_outline,
            appController,
            TextInputType.name,
          ),
          _crearSizedBox(15),
          _crearCampoTexto(
            'Apellido Materno',
            'Ingresa tu apellido materno',
            Icons.person_outline,
            apmController,
            TextInputType.name,
          ),
          _crearSizedBox(15),
          _crearCampoTexto(
            'Teléfono',
            'Ej. 5512345678',
            Icons.phone,
            telefonoController,
            TextInputType.phone,
          ),
          _crearSizedBox(15),
          _crearCampoTexto(
            'Correo electrónico',
            'ejemplo@correo.com',
            Icons.email,
            emailController,
            TextInputType.emailAddress,
          ),
          _crearSizedBox(15),
          _crearCampoPassword(),
          _crearSizedBox(30),
          _crearTitulo('Información Profesional', Colors.blueAccent),
          _crearSizedBox(20),
          _crearCampoTexto(
            'Número de Licencia',
            'Opcional si aplica',
            Icons.badge,
            numeroLicenciaController,
            TextInputType.text,
          ),
          _crearSizedBox(15),
          _crearCampoTexto(
            'Parentesco o Relación',
            'Ej. Familiar, Enfermero, etc.',
            Icons.family_restroom,
            parentescoRelacionController,
            TextInputType.text,
          ),
          _crearSizedBox(35),
          _crearBoton(
            'REGISTRAR CUIDADOR',
            Colors.blueAccent,
            _registrarCuidador,
          ),
        ],
      ),
    );
  }

  Widget _crearTitulo(String texto, Color color) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(
        texto,
        style: TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.bold,
          color: color,
        ),
      ),
    );
  }

  Widget _crearCampoTexto(
    String label,
    String hint,
    IconData icono,
    TextEditingController controller,
    TextInputType tipoTeclado,
  ) {
    return TextField(
      controller: controller,
      keyboardType: tipoTeclado,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icono),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  Widget _crearCampoPassword() {
    return TextField(
      controller: passwordController,
      obscureText: !mostrarPassword,
      decoration: InputDecoration(
        labelText: 'Contraseña',
        prefixIcon: const Icon(Icons.lock),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        suffixIcon: IconButton(
          icon: Icon(mostrarPassword ? Icons.visibility : Icons.visibility_off),
          onPressed: () {
            setState(() {
              mostrarPassword = !mostrarPassword;
            });
          },
        ),
      ),
    );
  }

  Widget _crearBoton(String texto, Color colorBoton, VoidCallback onPressed) {
    return SizedBox(
      width: double.infinity,
      height: 55,
      child: ElevatedButton(
        onPressed: _estaCargando ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: colorBoton,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: Text(
          texto,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  Widget _crearSizedBox(double alt) {
    return SizedBox(height: alt);
  }
}
