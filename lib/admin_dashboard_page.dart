import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../models/users.dart';

class AdminDashboardPage extends StatefulWidget {
  final User admin; 

  const AdminDashboardPage({super.key, required this.admin});

  @override
  State<AdminDashboardPage> createState() => _AdminDashboardPageState();
}

class _AdminDashboardPageState extends State<AdminDashboardPage> {
  List<User> _usuarios = [];
  bool _estaCargando = true;

  String get hostUrl =>
      (!kIsWeb && defaultTargetPlatform == TargetPlatform.android)
          ? 'http://10.0.2.2:3000'
          : 'http://localhost:3000';

  @override
  void initState() {
    super.initState();
    _cargarUsuarios();
  }

  // MÉTODO PARA OBTENER USUARIOS DE TU API NODE.JS
  Future<void> _cargarUsuarios() async {
    setState(() => _estaCargando = true);

    try {
      /* 
      // DESCOMENTA ESTO CUANDO TU API TENGA LA RUTA /api/users LISTA
      final response = await http.get(Uri.parse('$hostUrl/api/users'));
      
      if (response.statusCode == 200) {
        final List<dynamic> datos = jsonDecode(response.body);
        setState(() {
          _usuarios = datos.map((json) => User.fromJson(json)).toList();
        });
      }
      */

      // DATOS DE PRUEBA (Borrar cuando conectes tu API)
      await Future.delayed(const Duration(seconds: 1)); 
      setState(() {
        _usuarios = [
          User(id: 1, email: 'paciente@test.com', password: '', nombre: 'Juan', app: 'Pérez', apm: 'Gómez', telefono: '5511223344', rol: 'PACIENTE'),
          User(id: 2, email: 'cuidador@test.com', password: '', nombre: 'María', app: 'López', apm: 'Díaz', telefono: '5599887766', rol: 'CUIDADOR'),
          widget.admin, 
        ];
      });
    } catch (e) {
      print('Error al cargar usuarios: $e');
    } finally {
      if (mounted) setState(() => _estaCargando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      appBar: AppBar(
        title: const Text('Panel de Administración'),
        backgroundColor: Colors.red,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _cargarUsuarios,
            tooltip: 'Actualizar tabla',
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              Navigator.pop(context); // Regresa al Login
            },
            tooltip: 'Cerrar sesión',
          ),
        ],
      ),
      body: _estaCargando
          ? const Center(child: CircularProgressIndicator(color: Colors.red))
          : Padding(
              // Quitamos el límite de ancho para que ocupe el 100% de la pantalla
              padding: const EdgeInsets.all(20.0),
              child: Column(
                // CAMBIO CLAVE: stretch fuerza a los elementos a abarcar todo el ancho
                crossAxisAlignment: CrossAxisAlignment.stretch, 
                children: [
                  Text(
                    'Hola, ${widget.admin.nombre}',
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                    textAlign: TextAlign.left,
                  ),
                  const SizedBox(height: 5),
                  const Text(
                    'Gestión de usuarios registrados en VitaCare',
                    style: TextStyle(fontSize: 16, color: Colors.black54),
                    textAlign: TextAlign.left,
                  ),
                  const SizedBox(height: 25),
                  
                  // TABLA DE USUARIOS RESPONSIVA
                  Expanded(
                    child: Card(
                      elevation: 4,
                      shadowColor: Colors.black12,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(15),
                        child: LayoutBuilder(
                          builder: (context, constraints) {
                            return SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: ConstrainedBox(
                                // Fuerza a la tabla a tener al menos el tamaño total de la pantalla
                                constraints: BoxConstraints(
                                  minWidth: constraints.maxWidth,
                                ),
                                child: SingleChildScrollView(
                                  child: DataTable(
                                    headingRowColor: MaterialStateProperty.all(
                                      Colors.red.withOpacity(0.1),
                                    ),
                                    // Aumentamos el espaciado para que se vea más distribuido en pantallas grandes
                                    columnSpacing: 40, 
                                    columns: const [
                                      DataColumn(label: Text('ID', style: TextStyle(fontWeight: FontWeight.bold))),
                                      DataColumn(label: Text('Nombre', style: TextStyle(fontWeight: FontWeight.bold))),
                                      DataColumn(label: Text('Rol', style: TextStyle(fontWeight: FontWeight.bold))),
                                      DataColumn(label: Text('Correo', style: TextStyle(fontWeight: FontWeight.bold))),
                                      DataColumn(label: Text('Teléfono', style: TextStyle(fontWeight: FontWeight.bold))),
                                    ],
                                    rows: _usuarios.map((user) {
                                      return DataRow(
                                        cells: [
                                          DataCell(Text(user.id.toString())),
                                          DataCell(Text('${user.nombre} ${user.app}'.trim())),
                                          DataCell(
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                              decoration: BoxDecoration(
                                                color: _getColorPorRol(user.rol),
                                                borderRadius: BorderRadius.circular(8),
                                              ),
                                              child: Text(
                                                user.rol,
                                                style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                                              ),
                                            ),
                                          ),
                                          DataCell(Text(user.email)),
                                          DataCell(Text(user.telefono)),
                                        ],
                                      );
                                    }).toList(),
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Color _getColorPorRol(String rol) {
    switch (rol.toUpperCase()) {
      case 'ADMIN':
        return Colors.purple;
      case 'PACIENTE':
        return Colors.teal;
      case 'CUIDADOR':
        return Colors.blueAccent;
      default:
        return Colors.grey;
    }
  }
}