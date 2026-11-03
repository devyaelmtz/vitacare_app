import 'users.dart';

class Admin extends User {
  
  Admin({
    required int id,
    required String email,
    required String password,
    required String nombre,
    required String app,
    required String apm,
    required String telefono,
  }) : super(
          id: id,
          email: email,
          password: password,
          nombre: nombre,
          app: app,
          apm: apm,
          telefono: telefono,
          rol: 'ADMIN', // El rol está forzado por defecto
        );

  factory Admin.fromJson(Map<String, dynamic> json) {
    return Admin(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id'].toString()) ?? 0,
      email: json['email'] ?? '',
      password: json['password'] ?? '',
      nombre: json['nombre'] ?? '',
      app: json['app'] ?? '',
      apm: json['apm'] ?? '',
      telefono: json['telefono'] ?? '',
    );
  }
}