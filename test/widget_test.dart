import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:vitacare_app/main.dart';
import 'package:vitacare_app/admin_dashboard_page.dart';
import 'package:vitacare_app/models/users.dart';
import 'package:vitacare_app/registro_usuario_page.dart';
import 'package:vitacare_app/seleccion_registro_page.dart';
import 'package:vitacare_app/services/api_session.dart';

void main() {
  tearDown(ApiSession.clear);

  testWidgets('Crear cuenta abre solo el formulario base', (tester) async {
    await tester.pumpWidget(const VitaCareApp());
    await tester.ensureVisible(find.text('Crear cuenta'));
    await tester.tap(find.text('Crear cuenta'));
    await tester.pumpAndSettle();
    expect(find.byType(RegistroUsuarioPage), findsOneWidget);
    expect(find.byType(TextFormField), findsNWidgets(6));
    expect(find.byType(DropdownButtonFormField<String>), findsOneWidget);
    expect(find.text('Información Médica'), findsNothing);
    expect(find.byType(SeleccionRegistroPage), findsNothing);
  });

  testWidgets('registro avanzado requiere una sesión administrativa', (
    tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: SeleccionRegistroPage()));
    expect(
      find.text('Este módulo es exclusivo del administrador.'),
      findsOneWidget,
    );
    expect(find.text('Registrar Paciente'), findsNothing);
  });

  testWidgets('dashboard muestra usuarios de GET y abre registro avanzado', (
    tester,
  ) async {
    ApiSession.token = 'test-session';
    ApiSession.rol = 'ADMIN';
    var requests = 0;
    final client = MockClient((request) async {
      expect(request.method, 'GET');
      expect(request.url.path, '/api/users');
      requests++;
      return http.Response(
        jsonEncode([
          {
            'id': '123',
            'email': 'real@example.invalid',
            'nombre': 'Usuario Real',
            'app': 'Prueba',
            'apm': 'Local',
            'telefono': '5551111111',
            'rol': 'PACIENTE',
          },
        ]),
        200,
      );
    });
    await http.runWithClient(() async {
      await tester.pumpWidget(
        MaterialApp(
          home: AdminDashboardPage(
            admin: User(
              id: 1,
              email: 'admin@example.invalid',
              password: '',
              nombre: 'Administrador',
              app: '',
              apm: '',
              telefono: '',
              rol: 'ADMIN',
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(requests, 1);
      expect(find.text('Usuario Real Prueba'), findsOneWidget);
      expect(find.text('Juan Pérez'), findsNothing);
      await tester.tap(find.text('Registrar Paciente / Cuidador'));
      await tester.pumpAndSettle();
      expect(find.byType(SeleccionRegistroPage), findsOneWidget);
    }, () => client);
    client.close();
  });
}
