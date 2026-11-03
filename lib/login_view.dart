import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'admin_dashboard_page.dart';
import '../models/users.dart';
import 'seleccion_registro_page.dart';
import './components/alerta.dart';

class LoginView extends StatefulWidget {
  const LoginView({super.key});

  @override
  State<LoginView> createState() => _LoginViewState();
}

class _LoginViewState extends State<LoginView> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  String _selectedRol = 'PACIENTE';
  bool _estaCargando = false;
  bool mostrarPassword = false;
  bool _recordarme = true;

  final List<String> _roles = ['PACIENTE', 'CUIDADOR', 'ADMIN'];

  String get hostUrl =>
      (!kIsWeb && defaultTargetPlatform == TargetPlatform.android)
          ? 'http://10.0.2.2:3000'
          : 'http://localhost:3000';

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _submitLogin() {
    final String email = _emailController.text.trim();
    final String password = _passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      mostrarAlertaGlobal(
        context,
        'Por favor, ingresa tu correo y contraseña para continuar.',
        icono: Icons.warning_amber_rounded,
        colorIcono: Colors.orange,
        titulo: 'Campos vacíos',
      );
      return;
    }

    if (!_formKey.currentState!.validate()) {
      mostrarAlertaGlobal(
        context,
        'Revisa el formato de los datos ingresados. Asegúrate de que el correo sea válido.',
        icono: Icons.error_outline,
        colorIcono: Colors.red,
        titulo: 'Formato incorrecto',
      );
      return;
    }

    _intentarLogin();
  }

  void _intentarLogin() async {
    final String email = _emailController.text.trim();
    final String password = _passwordController.text.trim();

    setState(() => _estaCargando = true);

    try {
      final response = await http.post(
        Uri.parse('$hostUrl/api/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email,
          'password': password,
        }),
      );

      Map<String, dynamic> respuestaJson;
      try {
        respuestaJson = jsonDecode(response.body) as Map<String, dynamic>;
      } catch (_) {
        respuestaJson = {};
      }

      if (response.statusCode == 200 && respuestaJson['status'] == 'success') {
        final datoUsuario = respuestaJson['usuario'];

        try {
          User usuarioValido = User.fromJson(datoUsuario);

          if (mounted) {
            if (usuarioValido.rol == 'ADMIN') {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) => AdminDashboardPage(admin: usuarioValido),
                ),
              );
            } else {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) => const SeleccionRegistroPage(),
                ),
              );
            }
          }
        } catch (errorParseo) {
          if (mounted) {
            mostrarAlertaGlobal(
              context,
              'Error procesando los datos de tu cuenta.',
              icono: Icons.warning_amber_rounded,
              colorIcono: Colors.orange,
              titulo: 'Datos inválidos',
            );
          }
        }
      } else {
        final String mensajeError =
            respuestaJson['message'] ?? 'Correo o contraseña incorrectos.';
        if (mounted) {
          mostrarAlertaGlobal(
            context,
            mensajeError,
            icono: Icons.lock_outline,
            colorIcono: Colors.red,
            titulo: 'Acceso denegado',
          );
        }
      }
    } catch (e) {
      if (mounted) {
        mostrarAlertaGlobal(
          context,
          'No se pudo establecer la conexión con el servidor. Revisa tu red.',
          icono: Icons.wifi_off_rounded,
          colorIcono: Colors.deepOrange,
          titulo: 'Sin conexión',
        );
      }
    } finally {
      if (mounted) setState(() => _estaCargando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      body: _crearContenido(),
    );
  }

  Widget _crearContenido() {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 500),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(25),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _crearImagen(),
                _crearSizedBox(25),
                _crearTitulo(),
                _crearSizedBox(35),
                _crearCampoCorreo(),
                _crearSizedBox(20),
                _crearCampoPassword(),
                _crearSizedBox(20),
                _crearCampoRol(), 
                _crearSizedBox(10),
                _crearOpciones(),
                _crearSizedBox(20),
                _crearBotonLogin(),
                _crearSizedBox(25),
                _crearRegistro(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _crearImagen() {
    return Image.asset(
      'assets/img/vitacare.png',
      width: 200,
      height: 200,
      errorBuilder: (context, error, stackTrace) {
        return const Icon(Icons.health_and_safety, size: 150, color: Colors.red);
      },
    );
  }

  Widget _crearTitulo() {
    return const Text(
      'Bienvenido',
      style: TextStyle(
        fontSize: 30,
        fontWeight: FontWeight.bold,
        color: Colors.red,
      ),
    );
  }

  Widget _crearCampoCorreo() {
    return TextFormField(
      controller: _emailController,
      keyboardType: TextInputType.emailAddress,
      decoration: InputDecoration(
        labelText: 'Correo electrónico',
        hintText: 'ejemplo@correo.com',
        prefixIcon: const Icon(Icons.email),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
      ),
      validator: (value) {
        if (value == null || value.isEmpty) return 'Ingresa tu correo';
        if (!value.contains('@')) return 'Correo no válido';
        return null;
      },
    );
  }

  Widget _crearCampoPassword() {
    return TextFormField(
      controller: _passwordController,
      obscureText: !mostrarPassword,
      decoration: InputDecoration(
        labelText: 'Contraseña',
        prefixIcon: const Icon(Icons.lock),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
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
      validator: (value) {
        if (value == null || value.isEmpty) return 'Ingresa tu contraseña';
        return null;
      },
    );
  }

  Widget _crearCampoRol() {
    return DropdownButtonFormField<String>(
      initialValue: _selectedRol, 
      decoration: InputDecoration(
        labelText: 'Tipo de Usuario',
        prefixIcon: const Icon(Icons.manage_accounts),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
      ),
      items: _roles
          .map((rol) => DropdownMenuItem(value: rol, child: Text(rol)))
          .toList(),
      onChanged: (val) => setState(() => _selectedRol = val!),
    );
  }

  Widget _crearOpciones() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Checkbox(
              value: _recordarme,
              onChanged: (valor) {
                setState(() {
                  _recordarme = valor ?? false;
                });
              },
            ),
            const Text('Recordarme'),
          ],
        ),
        TextButton(
          onPressed: () {},
          child: const Text('¿Olvidaste tu contraseña?'),
        ),
      ],
    );
  }

  Widget _crearBotonLogin() {
    return SizedBox(
      width: double.infinity,
      height: 55,
      child: ElevatedButton(
        onPressed: _estaCargando ? null : _submitLogin,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.red,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: _estaCargando
            ? const CircularProgressIndicator(color: Colors.white)
            : const Text(
                'INICIAR SESIÓN',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
      ),
    );
  }

  Widget _crearRegistro() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Text('¿No tienes una cuenta?'),
        TextButton(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const SeleccionRegistroPage(),
              ),
            );
          },
          child: const Text(
            'Crear cuenta',
            style: TextStyle(
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }

  Widget _crearSizedBox(double alt) {
    return SizedBox(height: alt);
  }
}