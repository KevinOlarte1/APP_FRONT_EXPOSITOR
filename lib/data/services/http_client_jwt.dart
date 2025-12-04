import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:expositor_app/core/services/secure_storage_service.dart';
import 'package:expositor_app/data/services/auth_service.dart';

class HttpClientJwt {
  static final SecureStorageService _storage = SecureStorageService();

  // ---- PETICIONES PÚBLICAS ----

  static Future<http.Response> get(Uri url) async {
    return _send(() async => http.get(url, headers: await _headers()));
  }

  static Future<http.Response> post(Uri url, {Object? body}) async {
    return _send(
      () async => http.post(url, headers: await _headers(), body: body),
    );
  }

  static Future<http.Response> put(Uri url, {Object? body}) async {
    return _send(
      () async => http.put(url, headers: await _headers(), body: body),
    );
  }

  static Future<http.Response> delete(Uri url) async {
    return _send(() async => http.delete(url, headers: await _headers()));
  }

  // =====================================================
  //   🔥 LÓGICA CENTRAL: REFRESH TOKEN AUTOMÁTICO
  // =====================================================
  static Future<http.Response> _send(
    Future<http.Response> Function() requestFunction,
  ) async {
    // 1️⃣ Ejecutamos la petición original
    http.Response response = await requestFunction();

    // 2️⃣ Si NO es 401 → devolvemos directamente
    if (response.statusCode != 401) return response;

    print("⚠️ TOKEN EXPIRED — Intentando refresh…");

    // 3️⃣ Intentar refrescar tokens
    final refreshed = await AuthService.refresh();

    if (!refreshed) {
      print("❌ Refresh falló. Sesión expirada.");
      return response;
    }

    print("🔄 Refresh OK — Reintentando petición…");

    // 4️⃣ Reintentar la petición original con token nuevo
    return await requestFunction();
  }

  // Headers con token actualizado
  static Future<Map<String, String>> _headers() async {
    final token = await _storage.getAccessToken();

    return {
      "Authorization": "Bearer $token",
      "Content-Type": "application/json",
    };
  }
}
