import 'dart:convert';
import 'package:http/http.dart' as http;

import 'package:expositor_app/core/constants/api_constants.dart';
import 'package:expositor_app/core/services/secure_storage_service.dart';

import '../dto/login_request.dart';
import '../dto/login_response.dart';

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

        print("🔐 Tokens guardados correctamente.");
        return loginResponse;
      } else {
        print("❌ Error ${response.statusCode}: ${response.body}");
        return null;
      }
    } catch (e) {
      print("⚠️ Error de conexión: $e");
      return null;
    }
  }

  // ============================================================
  // 💠 FORGOT PASSWORD
  // ============================================================
  Future<bool> forgotPassword(String email) async {
    final url = Uri.parse("${ApiConstants.auth}/forgot-password");

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
  // 💠 REFRESH TOKEN (AHORA ESTÁTICO PARA HttpClientJwt)
  // ============================================================
  static Future<bool> refresh() async {
    final refreshToken = await _staticStorage.getRefreshToken();

    if (refreshToken == null) {
      print("⚠️ No hay refresh token guardado");
      return false;
    }

    final url = Uri.parse("${ApiConstants.auth}/refresh");

    try {
      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"refreshToken": refreshToken}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        final newAccess = data["accessToken"];
        final newRefresh = data["refreshToken"];

        if (newAccess != null && newRefresh != null) {
          await _staticStorage.saveTokens(newAccess, newRefresh);
          print("🔄 Tokens refrescados correctamente.");
          return true;
        }
      } else {
        print(
          "❌ Error al refrescar token: ${response.statusCode} — ${response.body}",
        );
      }
    } catch (e) {
      print("⚠️ Error de conexión al refrescar token: $e");
    }

    return false;
  }
}
