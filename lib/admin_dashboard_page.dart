import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import 'models/users.dart';
import 'login_view.dart';
import 'seleccion_registro_page.dart';
import 'services/api_session.dart';

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
      final response = await http.get(Uri.parse('$hostUrl/api/users'));
      if (response.statusCode != 200) {
        throw Exception('No se pudieron obtener los usuarios');
      }
      final List<dynamic> datos = jsonDecode(response.body);
      if (!mounted) return;
      setState(() {
        _usuarios = datos.map((json) => User.fromJson(json)).toList();
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _usuarios = []);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'No se pudieron cargar los usuarios. Intenta actualizar.',
          ),
        ),
      );
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
              ApiSession.clear();
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => const LoginView()),
              );
            },
            tooltip: 'Cerrar sesión',
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: Colors.red,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.person_add),
        label: const Text('Registrar Paciente / Cuidador'),
        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const SeleccionRegistroPage(),
            ),
          );
          if (mounted) _cargarUsuarios();
        },
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
                                      DataColumn(
                                        label: Text(
                                          'ID',
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                      DataColumn(
                                        label: Text(
                                          'Nombre',
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                      DataColumn(
                                        label: Text(
                                          'Rol',
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                      DataColumn(
                                        label: Text(
                                          'Correo',
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                      DataColumn(
                                        label: Text(
                                          'Teléfono',
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ],
                                    rows: _usuarios.map((user) {
                                      return DataRow(
                                        cells: [
                                          DataCell(Text(user.id.toString())),
                                          DataCell(
                                            Text(
                                              '${user.nombre} ${user.app}'
                                                  .trim(),
                                            ),
                                          ),
                                          DataCell(
                                            Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                horizontal: 8,
                                                vertical: 4,
                                              ),
                                              decoration: BoxDecoration(
                                                color:
                                                    _getColorPorRol(user.rol),
                                                borderRadius:
                                                    BorderRadius.circular(8),
                                              ),
                                              child: Text(
                                                user.rol == 'PENDIENTE'
                                                    ? 'PENDIENTE · Sin perfil'
                                                    : user.rol,
                                                style: const TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.bold,
                                                ),
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
      case 'PENDIENTE':
        return Colors.orange.shade800;
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
