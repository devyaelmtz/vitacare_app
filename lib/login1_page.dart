import 'package:flutter/material.dart';


class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  // Controladores para obtener los datos escritos
  final TextEditingController correoController = TextEditingController();

  final TextEditingController passwordController = TextEditingController();

  // Controla si la contraseña se muestra
  //BANDERAS
  bool mostrarPassword = false;
  bool _recordarme = true;

  //BUILD
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      body: _crearContenido(),
    ); //Scaffold
  } //build

  Widget _crearContenido() {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(25),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _crearImagen(),
            _crearSizedBox(
                25), //Tarea: Crear un método que genere la caja SizedBox y resiva como parametro un valor numérico _metodo(valor_numerico),
            _crearTitulo(),
            _crearSizedBox(35),
            _crearCampoCorreo(),
            _crearSizedBox(20),
            _crearCampoPassword(),
            _crearSizedBox(10),
            _crearOpciones(),
            _crearSizedBox(20),
            _crearBotonLogin(),
            _crearSizedBox(25),
            _crearRegistro(),
          ],
        ),
      ),
    );
  } //_crearContenido

  Widget _crearImagen() {
    return Image.asset(
      '../assets/img/vitacare.png',
      width: 200,
      height: 200,
    );
  } //_crearImagen

  Widget _crearTitulo() {
    return Text(
      'Bienvenido',
      style: TextStyle(
        fontSize: 30,
        fontWeight: FontWeight.bold,
        color: Colors.red,
      ),
    );
  }

  Widget _crearCampoCorreo() {
    return TextField(
      controller: correoController,
      keyboardType: TextInputType.emailAddress,
      decoration: const InputDecoration(
        labelText: 'Correo electrónico',
        hintText: 'ejemplo@correo.com',
        prefixIcon: Icon(Icons.email),
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

  Widget _crearOpciones() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Checkbox(
              value: true,
              onChanged: (valor) {},
            ),
            const Text('Recordarme'),
          ],
        ),
        TextButton(
          onPressed: () {},
          child: const Text(
            '¿Olvidaste tu contraseña?',
          ),
        ),
      ],
    );
  }

  Widget _crearBotonLogin() {
    return SizedBox(
      width: double.infinity,
      height: 55,
      child: ElevatedButton(
        onPressed: () {
          String correo = correoController.text;
          String password = passwordController.text;

          print('Correo: $correo');
          print('Contraseña: $password');
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.red,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: const Text(
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
          onPressed: () {},
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
}//clase

