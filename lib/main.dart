import 'package:flutter/material.dart';
// import 'package:vitacare_app/login1_page.dart';
// import 'package:vitacare_app/presentation/views/contador/counter_screen.dart';
// import 'package:vitacare_app/seleccion_registro_page.dart';
import 'login_view.dart';
// import 'presentation/contador/counter_screen.dart';
// import 'package:vitacare_app/presentation/views/contador/counter_screen.dart';

void main() {
  runApp(const VitaCareApp());
}

class VitaCareApp extends StatelessWidget {
  const VitaCareApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      title: 'VitaCare',
      debugShowCheckedModeBanner: false,
      home: LoginView(),
    );
  }
}
