class User {
  // CREATE TYPE user_role AS ENUM ('ADMIN', 'PACIENTE', 'CUIDADOR');

  final int id;
  final String email;
  final String password;
  final String nombre;
  final String app;
  final String apm;
  final String telefono;
  final String rol;
  // final String rutaImagen;

  User ({
    required this.id,
    required this.email,
    required this.password,
    required this.nombre,
    required this.app,
    required this.apm,
    required this.telefono,
    required this.rol,
    // required this.rutaImagen,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      // MODIFICACIÓN: Soluciona el error del BIGINT de PostgreSQL viniendo como String
      id: json['id'] is int ? json['id'] : int.tryParse(json['id'].toString()) ?? 0,
      
      email: json['email'] ?? '',
      password: json['password'] ?? '',
      nombre: json['nombre'] ?? '',
      app: json['app'] ?? '',
      apm: json['apm'] ?? '',
      telefono: json['telefono'] ?? '',
      rol: json['rol'] ?? '',
      // rutaImagen: json['rutaImagen'] ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
    'email': email,
    'password': password,
    'nombre': nombre,
    'app': app,
    'apm': apm,
    'telefono': telefono,
    'rol': rol,
    // 'rutaImagen': rutaImagen,
  };
}