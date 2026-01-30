import 'dart:convert';
import 'package:http/http.dart' as http;

import 'package:expositor_app/core/constants/api_constants.dart';
import 'package:expositor_app/core/services/secure_storage_service.dart';
import 'package:expositor_app/core/session/session.dart';

import '../dto/login_request.dart';
import '../dto/login_response.dart';
import 'package:expositor_app/main.dart';

class AuthService {
  // Storage de instancia (login usa este)
  final SecureStorageService _storage = SecureStorageService();

  // Storage estático (para refresh automático)
  static final SecureStorageService _staticStorage = SecureStorageService();

  // ============================================================
  // 💠 LOGIN
  // ============================================================
  Future<LoginResponse?> login(LoginRequest request) async {
    final url = Uri.parse("${ApiConstants.auth}/login");

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(request.toJson()),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final loginResponse = LoginResponse.fromJson(data);

        // Guardar tokens
        await _storage.saveTokens(
          loginResponse.accessToken,
          loginResponse.refreshToken,
        );

        // ✅ Guardar token en Session
        Session.token = loginResponse.accessToken;

        // ✅ Sacar role del JWT (si existe) y guardarlo
        final role = _extractRoleFromJwt(loginResponse.accessToken);
        Session.role = role;

        if (role != null && role.isNotEmpty) {
          await _storage.saveRole(role);
        }

        print("🔐 Tokens guardados correctamente.");
        print("👤 Role detectado: ${Session.role}");

        return loginResponse;
      } else {
        print("❌ Error ${response.statusCode}: ${response.body}");
        ApiConstants.msgtmp =
            "11❌ Error ${response.statusCode}: ${response.body}";
        return null;
      }
    } catch (e) {
      print("11⚠️ Error de conexión: $e");
      ApiConstants.msgtmp = "11⚠️ Error de conexión: $e";
      return null;
    }
  }

  // ============================================================
  // ✅ NUEVO: Restaurar role (y token si quieres) en Session desde storage
  // Útil para Splash / arranque de la app
  // ============================================================
  static Future<void> hydrateSession() async {
    final access = await _staticStorage.getAccessToken();
    final role = await _staticStorage.getRole();

    if (access != null && access.isNotEmpty) {
      Session.token = access;
      // Si role no está guardado, intentamos extraerlo del JWT
      Session.role = (role != null && role.isNotEmpty)
          ? role
          : _extractRoleFromJwt(access);
    } else {
      Session.clear();
    }
  }

  // ============================================================
  // 💠 FORGOT PASSWORD
  // ============================================================
  Future<bool> forgotPassword(String email) async {
    final url = Uri.parse("${ApiConstants.auth}/forgot-password");
    print(url);

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email}),
      );

      if (response.statusCode == 200) {
        print("📨 Email de recuperación enviado");
        return true;
      } else {
        print("❌ Error ${response.statusCode}: ${response.body}");
        return false;
      }
    } catch (e) {
      print("⚠️ Error al conectar con el servidor: $e");
      return false;
    }
  }

  // ============================================================
  // 💠 RESET PASSWORD
  // ============================================================
  Future<bool> resetPassword({
    required String email,
    required String code,
    required String newPassword,
  }) async {
    final url = Uri.parse("${ApiConstants.auth}/reset_password");

    final body = {"email": email, "code": code, "newPassword": newPassword};

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(body),
      );

      if (response.statusCode == 200) {
        print("🔄 Contraseña cambiada correctamente");
        return true;
      } else {
        print("❌ Error ${response.statusCode}: ${response.body}");
        return false;
      }
    } catch (e) {
      print("⚠️ Error de conexión: $e");
      return false;
    }
  }

  // ============================================================
  // 💠 REFRESH TOKEN (ESTÁTICO PARA HttpClientJwt)
  // ============================================================
  static Future<bool> refresh() async {
    final refreshToken = await _staticStorage.getRefreshToken();

    if (refreshToken == null || refreshToken.isEmpty) {
      print("⚠️ No hay refresh token guardado");
      return false;
    }

    try {
      final url = Uri.parse("${ApiConstants.auth}/refresh");

      final response = await http
          .post(
            url,
            headers: {"Content-Type": "application/json"},
            body: jsonEncode({"refreshToken": refreshToken}),
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode != 200) {
        print(
          "❌ Error al refrescar token: ${response.statusCode} — ${response.body}",
        );
        return false;
      }

      final data = jsonDecode(response.body);

      final newAccess = data["accessToken"];
      final newRefresh = data["refreshToken"];

      if (newAccess == null || newAccess.isEmpty) return false;

      await _staticStorage.saveTokens(newAccess, newRefresh);
      print("🔄 Tokens refrescados correctamente.");
      // ✅ Actualizar Session
      Session.token = newAccess;

      // ✅ Actualizar role (si viene en el JWT) y persistirlo
      final role = _extractRoleFromJwt(newAccess);
      Session.role = role;

      if (role != null && role.isNotEmpty) {
        await _staticStorage.saveRole(role);
      }
      return true;
    } catch (e) {
      print("⚠️ Error de conexión al refrescar token: $e");
    }

    return false;
  }

  // ============================================================
  // ✅ Helpers JWT -> role (mínimo, sin librerías)
  // ============================================================
  static String? _extractRoleFromJwt(String jwt) {
    try {
      final parts = jwt.split('.');
      if (parts.length != 3) return null;

      final payloadBase64 = parts[1];
      final normalized = base64Url.normalize(payloadBase64);
      final payloadString = utf8.decode(base64Url.decode(normalized));
      final Map<String, dynamic> payload = jsonDecode(payloadString);

      final roles = payload["roles"];
      if (roles is List && roles.isNotEmpty) {
        return roles.first.toString(); // "ADMIN"
      }

      return null;
    } catch (e) {
      return null;
    }
  }

  static String? _normalizeRole(dynamic raw) {
    if (raw == null) return null;

    // roles: ["ADMIN"]
    if (raw is List && raw.isNotEmpty) {
      return raw.first
          .toString()
          .trim()
          .replaceAll('[', '')
          .replaceAll(']', '');
    }

    // role: "[ADMIN]" o "ADMIN"
    final r = raw.toString().trim();
    if (r.isEmpty) return null;

    return r.replaceAll('[', '').replaceAll(']', '').trim();
  }

  static Future<void> logout() async {
    Session.clear();
    _staticStorage.deleteRole();
    _staticStorage.deleteTokens();

    // o si tienes algo tipo:
    // await FlutterSecureStorage().delete(key: 'refreshToken');

    // 3️⃣ (Opcional pero recomendado) limpiar cualquier estado cacheado
    // ejemplo:
    // ApiCache.clear();
  }
}
