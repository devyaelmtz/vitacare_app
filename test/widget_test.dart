import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:vitacare_app/main.dart';
import 'package:vitacare_app/components/selector_usuario.dart';
import 'package:vitacare_app/registro_paciente_page.dart';
import 'package:vitacare_app/registro_cuidador_page.dart';
import 'package:vitacare_app/admin_dashboard_page.dart';
import 'package:vitacare_app/models/users.dart';
import 'package:vitacare_app/registro_usuario_page.dart';
import 'package:vitacare_app/seleccion_registro_page.dart';
import 'package:vitacare_app/services/api_session.dart';

void main() {
  tearDown(ApiSession.clear);

  testWidgets('Crear cuenta abre solo el formulario base', (tester) async {
    await tester.pumpWidget(const VitaCareApp());
    expect(find.byType(DropdownButtonFormField<String>), findsNothing);
    await tester.ensureVisible(find.text('Crear cuenta'));
    await tester.tap(find.text('Crear cuenta'));
    await tester.pumpAndSettle();
    expect(find.byType(RegistroUsuarioPage), findsOneWidget);
    expect(find.byType(TextFormField), findsNWidgets(6));
    expect(find.byType(DropdownButtonFormField<String>), findsNothing);
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
            'rol': 'PENDIENTE',
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
      expect(find.text('PENDIENTE · Sin perfil'), findsOneWidget);
      final badge = tester.widget<Container>(find
          .ancestor(
              of: find.text('PENDIENTE · Sin perfil'),
              matching: find.byType(Container))
          .first);
      expect((badge.decoration as BoxDecoration).color, Colors.orange.shade800);
      expect(find.text('Juan Pérez'), findsNothing);
      await tester.tap(find.text('Registrar Paciente / Cuidador'));
      await tester.pumpAndSettle();
      expect(find.byType(SeleccionRegistroPage), findsOneWidget);
    }, () => client);
    client.close();
  });
  for (final paciente in [true, false]) {
    testWidgets(
        '${paciente ? 'Paciente' : 'Cuidador'} autocompleta y envía solo ID y perfil',
        (tester) async {
      ApiSession.token = 'test-session';
      ApiSession.rol = 'ADMIN';
      Map<String, dynamic>? payload;
      final users = [
        {
          'id': '123',
          'nombre': 'Ana',
          'app': 'Pérez',
          'apm': 'López',
          'email': 'ana@example.invalid',
          'telefono': '5551111111',
          'rol': 'PACIENTE'
        },
        {
          'id': '456',
          'nombre': 'Luis',
          'app': 'García',
          'apm': 'Ruiz',
          'email': 'luis@example.invalid',
          'telefono': '5552222222',
          'rol': 'CUIDADOR'
        },
      ];
      final client = MockClient((request) async {
        expect(request.headers['Authorization'], 'Bearer test-session');
        if (request.method == 'GET') {
          expect(request.url.path, '/api/users');
          return http.Response(jsonEncode(users), 200,
              headers: {'content-type': 'application/json; charset=utf-8'});
        }
        expect(
            request.url.path, paciente ? '/api/pacientes' : '/api/cuidadores');
        payload = jsonDecode(request.body) as Map<String, dynamic>;
        return http.Response('{"status":"success"}', 201);
      });
      await http.runWithClient(() async {
        await tester.pumpWidget(MaterialApp(
            home: paciente
                ? const RegistroPacientePage()
                : const RegistroCuidadorPage()));
        await tester.pumpAndSettle();
        final selector = find.byType(DropdownButtonFormField<int>);
        for (final name in [
          'Ana Pérez López — ana@example.invalid',
          'Luis García Ruiz — luis@example.invalid'
        ]) {
          await tester.ensureVisible(selector);
          await tester.tap(selector);
          await tester.pumpAndSettle();
          await tester.tap(find.text(name).last);
          await tester.pumpAndSettle();
        }
        final fields =
            tester.widgetList<TextField>(find.byType(TextField)).toList();
        expect(fields.take(5).map((f) => f.controller!.text),
            ['Luis', 'García', 'Ruiz', '5552222222', 'luis@example.invalid']);
        expect(fields.take(5).every((f) => f.readOnly), isTrue);
        expect(fields.skip(5).every((f) => !f.readOnly), isTrue);
        expect(find.text('Contraseña'), findsNothing);
        final extra = paciente
            ? ['2000-01-01', 'Contacto', '5553333333']
            : ['L123', 'Familiar'];
        for (var i = 0; i < extra.length; i++) {
          await tester.enterText(find.byType(TextField).at(i + 5), extra[i]);
        }
        final button =
            find.text(paciente ? 'REGISTRAR PACIENTE' : 'REGISTRAR CUIDADOR');
        await tester.ensureVisible(button);
        await tester.tap(button);
        await tester.pumpAndSettle();
        expect(payload!['usuario_id'], 456);
        expect(
            payload!.keys.toSet(),
            paciente
                ? {
                    'usuario_id',
                    'fechaNac',
                    'contactoEmergencia',
                    'telefonoEmergencia'
                  }
                : {'usuario_id', 'numeroLicencia', 'parentescoRelacion'});
      }, () => client);
      client.close();
    });
  }
  testWidgets('registro público envía seis campos y ningún rol',
      (tester) async {
    Map<String, dynamic>? payload;
    final client = MockClient((request) async {
      expect(request.url.path, '/api/users');
      payload = jsonDecode(request.body) as Map<String, dynamic>;
      return http.Response('{"status":"success"}', 201);
    });
    await http.runWithClient(() async {
      await tester.pumpWidget(const MaterialApp(home: RegistroUsuarioPage()));
      final values = [
        'Ana',
        'Pérez',
        'López',
        '5551111111',
        'ana@example.invalid',
        'password-test'
      ];
      for (var i = 0; i < values.length; i++) {
        await tester.enterText(find.byType(TextFormField).at(i), values[i]);
      }
      await tester.ensureVisible(find.text('CREAR CUENTA'));
      await tester.tap(find.text('CREAR CUENTA'));
      await tester.pumpAndSettle();
      expect(payload!.keys.toSet(),
          {'nombre', 'app', 'apm', 'telefono', 'email', 'password'});
    }, () => client);
    client.close();
  });

  testWidgets(
      'selector permite reintentar una carga fallida e informa lista vacía',
      (tester) async {
    var requests = 0;
    final client = MockClient((request) async {
      requests++;
      return requests == 1
          ? http.Response('{}', 503)
          : http.Response('[]', 200);
    });
    await http.runWithClient(() async {
      await tester.pumpWidget(MaterialApp(
          home: Scaffold(
              body: SelectorUsuario(
                  onSelected: (_) => fail('No hay usuario disponible')))));
      await tester.pumpAndSettle();
      expect(find.text('No se pudieron cargar los usuarios.'), findsOneWidget);
      await tester.tap(find.text('Reintentar'));
      await tester.pumpAndSettle();
      expect(find.text('No hay usuarios registrados para seleccionar.'),
          findsOneWidget);
      expect(requests, 2);
    }, () => client);
    client.close();
  });
}
