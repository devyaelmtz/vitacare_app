import 'package:flutter/material.dart';
import 'registro_paciente_page.dart';
import 'registro_cuidador_page.dart';

class SeleccionRegistroPage extends StatefulWidget {
  const SeleccionRegistroPage({super.key});

  @override
  State<SeleccionRegistroPage> createState() => _SeleccionRegistroPageState();
}

class _SeleccionRegistroPageState extends State<SeleccionRegistroPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      appBar: AppBar(
        title: const Text('Tipo de Cuenta'),
        backgroundColor: Colors.red,
        foregroundColor: Colors.white,
      ),
      body: _crearContenido(context),
    );
  }

  Widget _crearContenido(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(25),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _crearTitulo('¿Cómo deseas registrarte en VitaCare?'),
            _crearSizedBox(40),
            
            _crearBotonSeleccion(
              'Soy Paciente',
              'Busco registrar mis datos y gestionar mi salud.',
              Icons.favorite,
              Colors.red,
              () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const RegistroPacientePage(),
                  ),
                );
              },
            ),
            
            _crearSizedBox(25),

            _crearBotonSeleccion(
              'Soy Cuidador',
              'Ofrezco mis servicios de cuidado médico.',
              Icons.medication_liquid_sharp,
              Colors.blueAccent,
              () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const RegistroCuidadorPage(),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _crearTitulo(String texto) {
    return Text(
      texto,
      textAlign: TextAlign.center,
      style: const TextStyle(
        fontSize: 24,
        fontWeight: FontWeight.bold,
        color: Colors.black87,
      ),
    );
  }

  Widget _crearSizedBox(double alto) {
    return SizedBox(height: alto);
  }

  Widget _crearBotonSeleccion(String titulo, String descripcion, IconData icono, Color color, VoidCallback onPressed) {
    return OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.all(20),
        backgroundColor: Colors.white,
        side: BorderSide(color: color, width: 2), // Borde del color indicado
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15),
        ),
      ),
      child: Row(
        children: [
          Icon(icono, size: 45, color: color),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  titulo,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  descripcion,
                  style: const TextStyle(
                    fontSize: 13,
                    color: Colors.black54,
                  ),
                ),
              ],
            ),
          ),
          const Icon(Icons.arrow_forward_ios, color: Colors.grey, size: 18),
        ],
      ),
    );
  }
}