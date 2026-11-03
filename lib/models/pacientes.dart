import 'users.dart';

class Paciente extends User {
  final String fechaNac; // Puedes cambiarlo a DateTime si lo procesas así en tu app
  final String contactoEmergencia;
  final String telefonoEmergencia;

  Paciente({
    required int id,
    required String email,
    required String password,
    required String nombre,
    required String app,
    required String apm,
    required String telefono,
    required String rol,
    required this.fechaNac,
    required this.contactoEmergencia,
    required this.telefonoEmergencia,
  }) : super(
          id: id,
          email: email,
          password: password,
          nombre: nombre,
          app: app,
          apm: apm,
          telefono: telefono,
          rol: rol,
        );

  factory Paciente.fromJson(Map<String, dynamic> json) {
    return Paciente(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id'].toString()) ?? 0,
      email: json['email'] ?? '',
      password: json['password'] ?? '',
      nombre: json['nombre'] ?? '',
      app: json['app'] ?? '',
      apm: json['apm'] ?? '',
      telefono: json['telefono'] ?? '',
      rol: json['rol'] ?? '',
      // Campos específicos de pacientes
      fechaNac: json['fecha_nac'] ?? '',
      contactoEmergencia: json['contacto_emergencia'] ?? '',
      telefonoEmergencia: json['telefono_emergencia'] ?? '',
    );
  }

  @override
  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = super.toJson();
    data['fecha_nac'] = fechaNac;
    data['contacto_emergencia'] = contactoEmergencia;
    data['telefono_emergencia'] = telefonoEmergencia;
    return data;
  }
}