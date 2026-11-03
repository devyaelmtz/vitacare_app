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

  final TextEditingController numeroLicenciaController = TextEditingController();
  final TextEditingController parentescoRelacionController = TextEditingController();

  // Bandera para la contraseña
  bool mostrarPassword = false;

  @override
  Widget build(BuildContext context) {
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

          _crearTitulo('Información Profesional', Colors.blueAccent),
          _crearSizedBox(20),
          _crearCampoTexto('Número de Licencia', 'Opcional si aplica', Icons.badge, numeroLicenciaController, TextInputType.text),
          _crearSizedBox(15),
          _crearCampoTexto('Parentesco o Relación', 'Ej. Familiar, Enfermero, etc.', Icons.family_restroom, parentescoRelacionController, TextInputType.text),
          
          _crearSizedBox(35),
          
          _crearBoton('REGISTRAR CUIDADOR', Colors.blueAccent, () {
            print('Registrando Cuidador: ${nombreController.text}');
            print('Licencia: ${numeroLicenciaController.text}');
            
            Navigator.pop(context);
          }),
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

  Widget _crearBoton(String texto, Color colorBoton, VoidCallback onPressed) {
    return SizedBox(
      width: double.infinity,
      height: 55,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: colorBoton,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: Text(
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