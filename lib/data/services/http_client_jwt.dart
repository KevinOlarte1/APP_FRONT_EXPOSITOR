import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:expositor_app/core/services/secure_storage_service.dart';
import 'package:expositor_app/data/services/auth_service.dart';

class HttpClientJwt {
  static final SecureStorageService _storage = SecureStorageService();

  /// Método genérico para GET
  static Future<http.Response> get(Uri url) async {
    return _send(() async => http.get(url, headers: await _headers()));
  }

  /// Método genérico para POST
  static Future<http.Response> post(Uri url, {Object? body}) async {
    return _send(
      () async => http.post(url, headers: await _headers(), body: body),
    );
  }

  /// Método genérico para PUT
  static Future<http.Response> put(Uri url, {Object? body}) async {
    return _send(
      () async => http.put(url, headers: await _headers(), body: body),
    );
  }

  /// Método genérico DELETE
  static Future<http.Response> delete(Uri url) async {
    return _send(() async => http.delete(url, headers: await _headers()));
  }

  /// ------------------------------
  /// LÓGICA CENTRAL DE REFRESH TOKEN
  /// ------------------------------
  static Future<http.Response> _send(
    Future<http.Response> Function() requestFunction,
  ) async {
    final token = await _storage.getAccessToken();

    // Primera llamada
    http.Response response = await requestFunction();

    // Si NO es 401 → devolver directamente
    if (response.statusCode != 401) {
      return response;
    }

    // Intentar refresh
    final refreshed = await AuthService().refresh();

    if (!refreshed) {
      // ❌ Refresh falló → devolver la respuesta original
      return response;
    }

    // ✔ Refresh correcto → reintentar petición con el nuevo token
    return await requestFunction();
  }

  /// Headers con token actualizado
  static Future<Map<String, String>> _headers() async {
    final token = await _storage.getAccessToken();

    return {
      "Authorization": "Bearer $token",
      "Content-Type": "application/json",
    };
  }
}
