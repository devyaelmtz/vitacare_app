/// Sesión en memoria; un reinicio requiere iniciar sesión nuevamente.
class ApiSession {
  static String? token;
  static String? rol;
  static bool get isAdmin => token != null && rol == 'ADMIN';
  static Map<String, String> get headers => {
    'Content-Type': 'application/json',
    if (token != null) 'Authorization': 'Bearer $token',
  };
  static void clear() {
    token = null;
    rol = null;
  }
}
