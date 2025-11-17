import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:expositor_app/core/constants/api_constants.dart';
import 'package:expositor_app/core/services/secure_storage_service.dart';
import '../dto/login_request.dart';
import '../dto/login_response.dart';

class AuthService {
  final SecureStorageService _storage = SecureStorageService();

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

        // 🧠 Guardar tokens de forma segura
        await _storage.saveTokens(
          loginResponse.accessToken,
          loginResponse.refreshToken,
        );
        print("Guarda datos");
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

  Future<bool> forgotPassword(String email) async {
    final url = Uri.parse("${ApiConstants.auth}/forgot-password");

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email}),
      );

      if (response.statusCode == 200) {
        print("✅ Correo de recuperación enviado correctamente");
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
        print("✅ Contraseña restablecida correctamente");
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
}
