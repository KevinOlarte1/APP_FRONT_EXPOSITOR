// session.dart
class Session {
  Session._();

  static String? token;
  static String? role; // "ADMIN" | "USER"
  static int? userId;
  static String? email;
  static String? nombre;
  static String? apellido;

  static bool get isLoggedIn => token != null && token!.isNotEmpty;

  static bool get isAdmin {
    final r = _normalizeRole(role);
    return r == "ADMIN";
  }

  static String? _normalizeRole(String? r) {
    if (r == null) return null;
    // Por tu backend: "[ADMIN]" -> "ADMIN"
    return r.replaceAll("[", "").replaceAll("]", "").trim();
  }

  static void clear() {
    token = null;
    role = null;
    userId = null;
    email = null;
    nombre = null;
    apellido = null;
  }
}
