import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class RegistroPacientePage extends StatefulWidget {
  const RegistroPacientePage({super.key});

  @override
  State<RegistroPacientePage> createState() => _RegistroPacientePageState();
}

class _RegistroPacientePageState extends State<RegistroPacientePage> {
  // Controladores de texto para los campos
  final TextEditingController nombreController = TextEditingController();
  final TextEditingController appController = TextEditingController();
  final TextEditingController apmController = TextEditingController();
  final TextEditingController telefonoController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  final TextEditingController fechaNacController = TextEditingController();
  final TextEditingController contactoEmergenciaController = TextEditingController();
  final TextEditingController telEmergenciaController = TextEditingController();

  // Banderas de estado
  bool mostrarPassword = false;
  bool _estaCargando = false;

  // Ajuste de IP dinámico: 10.0.2.2 para emuladores de Android
  String get hostUrl =>
      (!kIsWeb && defaultTargetPlatform == TargetPlatform.android)
          ? 'http://10.0.2.2:3000'
          : 'http://localhost:3000';

  @override
  void dispose() {
    nombreController.dispose();
    appController.dispose();
    apmController.dispose();
    telefonoController.dispose();
    emailController.dispose();
    passwordController.dispose();
    fechaNacController.dispose();
    contactoEmergenciaController.dispose();
    telEmergenciaController.dispose();
    super.dispose();
  }

  // MÉTODO PARA REGISTRAR EN EL BACKEND
  Future<void> _registrarPaciente() async {
    // 1. Validación básica de campos vacíos
    if (nombreController.text.isEmpty ||
        emailController.text.isEmpty ||
        passwordController.text.isEmpty ||
        telefonoController.text.isEmpty) {
      _mostrarAlerta('Error', 'Por favor, completa al menos los campos obligatorios (Nombre, Correo, Contraseña, Teléfono).', true);
      return;
    }

    setState(() => _estaCargando = true);

    try {
      // 2. Realizar la petición POST
      final response = await http.post(
        Uri.parse('$hostUrl/api/users'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': emailController.text.trim(),
          'password': passwordController.text.trim(),
          'nombre': nombreController.text.trim(),
          'app': appController.text.trim(),
          'apm': apmController.text.trim(),
          'telefono': telefonoController.text.trim(),
          'rol': 'PACIENTE',
          // Estos campos se envían, pero requerirán que actualices 
          // tu backend en el futuro si deseas guardarlos en una tabla 'pacientes'
          'fechaNac': fechaNacController.text.trim(),
          'contactoEmergencia': contactoEmergenciaController.text.trim(),
          'telefonoEmergencia': telEmergenciaController.text.trim(),
        }),
      );

      final Map<String, dynamic> respuestaJson = jsonDecode(response.body);

      // 3. Evaluar respuesta del servidor (201 Created)
      if (response.statusCode == 201 && respuestaJson['status'] == 'success') {
        _mostrarAlerta('¡Éxito!', 'Paciente registrado correctamente.', false);
      } else {
        String mensajeError = respuestaJson['error'] ?? 'Error al registrar el paciente.';
        _mostrarAlerta('Error', mensajeError, true);
      }
    } catch (e) {
      print('Error de conexión: $e');
      _mostrarAlerta('Error de Conexión', 'No se pudo conectar con el servidor.', true);
    } finally {
      if (mounted) setState(() => _estaCargando = false);
    }
  }

  void _mostrarAlerta(String titulo, String mensaje, bool esError) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(
              esError ? Icons.error_outline : Icons.check_circle_outline,
              color: esError ? Colors.red : Colors.green,
            ),
            const SizedBox(width: 10),
            Text(titulo),
          ],
        ),
        content: Text(mensaje),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context); // Cierra la alerta
              if (!esError) {
                Navigator.pop(context); // Si fue éxito, regresa al Login
              }
            },
            child: const Text('Entendido'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      appBar: AppBar(
        title: const Text('Registro de Paciente'),
        backgroundColor: Colors.red,
        foregroundColor: Colors.white,
      ),
      body: _crearContenido(),
    );
  }

  Widget _crearContenido() {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 600), // Responsivo en Web
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(25),
          child: Column(
            children: [
              _crearTitulo('Datos del Paciente', Colors.red),
              _crearSizedBox(20),
              _crearCampoTexto('Nombre(s)', 'Ingresa tu nombre', Icons.person, nombreController, TextInputType.name),
              _crearSizedBox(15),
              _crearCampoTexto('Apellido Paterno', 'Ingresa tu apellido paterno', Icons.person_outline, appController, TextInputType.name),
              _crearSizedBox(15),
              _crearCampoTexto('Apellido Materno', 'Ingresa tu apellido materno', Icons.person_outline, apmController, TextInputType.name),
              _crearSizedBox(15),
              _crearCampoTexto('Teléfono', 'Ej. 5512345678', Icons.phone, telefonoController, TextInputType.phone),
              _crearSizedBox(15),
              _crearCampoTexto('Correo electrónico', 'ejemplo@correo.com', Icons.email, emailController, TextInputType.emailAddress),
              _crearSizedBox(15),
              _crearCampoPassword(),
              
              _crearSizedBox(30),

              _crearTitulo('Información Médica', Colors.redAccent),
              _crearSizedBox(20),
              _crearCampoTexto('Fecha de Nacimiento', 'YYYY-MM-DD', Icons.calendar_today, fechaNacController, TextInputType.datetime),
              _crearSizedBox(15),
              _crearCampoTexto('Contacto de Emergencia', 'Nombre del contacto', Icons.health_and_safety, contactoEmergenciaController, TextInputType.name),
              _crearSizedBox(15),
              _crearCampoTexto('Teléfono de Emergencia', 'Ej. 5512345678', Icons.contact_phone, telEmergenciaController, TextInputType.phone),
              
              _crearSizedBox(35),
              
              // BOTÓN FINAL CON ESTADO DE CARGA
              _crearBoton('REGISTRAR PACIENTE'),
            ],
          ),
        ),
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

  Widget _crearCampoTexto(String label, String hint, IconData icono, TextEditingController controller, TextInputType tipoTeclado) {
    return TextField(
      controller: controller,
      keyboardType: tipoTeclado,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icono),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
        ),
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
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        suffixIcon: IconButton(
          icon: Icon(
            mostrarPassword ? Icons.visibility : Icons.visibility_off,
          ),
          onPressed: () {
            setState(() {
              mostrarPassword = !mostrarPassword;
            });
          },
        ),
      ),
    );
  }

  Widget _crearBoton(String texto) {
    return SizedBox(
      width: double.infinity,
      height: 55,
      child: ElevatedButton(
        onPressed: _estaCargando ? null : _registrarPaciente, // Se desactiva si está cargando
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.red,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: _estaCargando
            ? const CircularProgressIndicator(color: Colors.white)
            : Text(
                texto,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
      ),
    );
  }

  Widget _crearSizedBox(double alt) {
    return SizedBox(height: alt);
  }
}