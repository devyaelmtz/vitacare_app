import 'users.dart';

class Cuidador extends User {
  final String numeroLicencia;
  final String parentescoRelacion;

  Cuidador({
    required int id,
    required String email,
    required String password,
    required String nombre,
    required String app,
    required String apm,
    required String telefono,
    required String rol,
    required this.numeroLicencia,
    required this.parentescoRelacion,
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

  factory Cuidador.fromJson(Map<String, dynamic> json) {
    return Cuidador(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id'].toString()) ?? 0,
      email: json['email'] ?? '',
      password: json['password'] ?? '',
      nombre: json['nombre'] ?? '',
      app: json['app'] ?? '',
      apm: json['apm'] ?? '',
      telefono: json['telefono'] ?? '',
      rol: json['rol'] ?? '',
      // Campos específicos de cuidadores
      numeroLicencia: json['numero_licencia'] ?? '',
      parentescoRelacion: json['parentesco_relacion'] ?? '',
    );
  }

  @override
  Map<String, dynamic> toJson() {
    // Obtenemos el map de la clase padre (User) y le agregamos los datos nuevos
    final Map<String, dynamic> data = super.toJson();
    data['numero_licencia'] = numeroLicencia;
    data['parentesco_relacion'] = parentescoRelacion;
    return data;
  }
}