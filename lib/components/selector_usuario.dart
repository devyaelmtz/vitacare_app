import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../models/users.dart';
import '../services/api_session.dart';

/// Carga cuentas reales; los formularios conservan solo su identificador y datos de consulta.
class SelectorUsuario extends StatefulWidget {
  final ValueChanged<User> onSelected;
  final bool enabled;
  const SelectorUsuario(
      {super.key, required this.onSelected, this.enabled = true});

  @override
  State<SelectorUsuario> createState() => _SelectorUsuarioState();
}

class _SelectorUsuarioState extends State<SelectorUsuario> {
  List<User> _usuarios = [];
  int? _seleccionado;
  bool _cargando = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _cargarUsuarios();
  }

  Future<void> _cargarUsuarios() async {
    setState(() {
      _cargando = true;
      _error = null;
    });
    final host = !kIsWeb && defaultTargetPlatform == TargetPlatform.android
        ? 'http://10.0.2.2:3000'
        : 'http://localhost:3000';
    try {
      final response = await http.get(Uri.parse('$host/api/users'),
          headers: ApiSession.headers);
      if (response.statusCode != 200) {
        throw Exception('Error al cargar usuarios');
      }
      final usuarios = (jsonDecode(response.body) as List)
          .map((json) => User.fromJson(json))
          .toList();
      if (mounted) setState(() => _usuarios = usuarios);
    } catch (_) {
      if (mounted) {
        setState(() => _error = 'No se pudieron cargar los usuarios.');
      }
    } finally {
      if (mounted) setState(() => _cargando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_cargando) return const LinearProgressIndicator();
    if (_error != null) {
      return Column(children: [
        Text(_error!),
        TextButton(onPressed: _cargarUsuarios, child: const Text('Reintentar'))
      ]);
    }
    if (_usuarios.isEmpty) {
      return const Text('No hay usuarios registrados para seleccionar.');
    }
    return DropdownButtonFormField<int>(
      initialValue: _seleccionado,
      isExpanded: true,
      decoration: InputDecoration(
          labelText: 'Seleccionar usuario',
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10))),
      items: _usuarios
          .map((user) => DropdownMenuItem(
              value: user.id,
              child: Text(
                  '${user.nombre} ${user.app} ${user.apm} — ${user.email}',
                  overflow: TextOverflow.ellipsis)))
          .toList(),
      onChanged: !widget.enabled
          ? null
          : (id) {
              if (id == null) return;
              setState(() => _seleccionado = id);
              widget.onSelected(_usuarios.firstWhere((user) => user.id == id));
            },
    );
  }
}
