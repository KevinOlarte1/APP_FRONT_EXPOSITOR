import 'dart:convert';
import 'package:expositor_app/core/session/session.dart';
import 'package:expositor_app/main.dart';
import 'package:expositor_app/presentation/pages/login/login_page.dart';
import 'package:http/http.dart' as http;
import 'package:expositor_app/core/services/secure_storage_service.dart';
import 'package:expositor_app/data/services/auth_service.dart';
import 'package:flutter/material.dart';

final GlobalKey<NavigatorState> appNavKey = GlobalKey<NavigatorState>();

class HttpClientJwt {
  static final SecureStorageService _storage = SecureStorageService();

  // ---- PETICIONES PÚBLICAS ----

  static Future<http.Response> get(Uri url) async {
    return _send(() async => http.get(url, headers: _headers()));
  }

  static Future<http.Response> post(Uri url, {Object? body}) async {
    return _send(() async => http.post(url, headers: _headers(), body: body));
  }

  static Future<http.Response> put(Uri url, {Object? body}) async {
    return _send(() async => http.put(url, headers: _headers(), body: body));
  }

  static Future<http.Response> delete(Uri url) async {
    return _send(() async => http.delete(url, headers: _headers()));
  }

  static Future<http.StreamedResponse> postMultipart(
    Uri url,
    http.MultipartRequest request,
  ) async {
    // Añadir token manualmente porque _headers() impone JSON
    var token = Session.token;
    request.headers["Authorization"] = "Bearer $token";

    // Ejecutar la petición
    http.StreamedResponse response = await request.send();

    // Si NO es 401 -> devolvemos
    if (response.statusCode != 401) return response;

    print("⚠️ TOKEN EXPIRED — Intentando refresh (multipart)…");

    // Intentar refrescar tokens
    final refreshed = await AuthService.refresh();

    if (!refreshed) {
      print("❌ Refresh falló. Sesión expirada.");
      return response;
    }

    print("🔄 Refresh OK — Reintentando petición multipart…");

    // 2) Reintento (request nuevo)
    token = Session.token;
    request.headers["Authorization"] = "Bearer $token";
    return await request.send();
  }

  // =====================================================
  //   🔥 LÓGICA CENTRAL: REFRESH TOKEN AUTOMÁTICO
  // =====================================================
  static Future<http.Response> _send(
    Future<http.Response> Function() requestFunction, {
    bool retried = false,
  }) async {
    final response = await requestFunction();
    print("Lanzando Peticion API....");
    if (response.statusCode != 401) return response;

    // Si ya reintentamos, NO más refresh -> logout y navegar
    if (retried) {
      await AuthService.logout();
      // o el método que tengas para limpiar token
      navigatorKey.currentState?.pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const LoginPage()),
        (route) => false,
      );
    }

    // 1 intento de refresh
    print("Lanzando el Refreshh");
    final refreshed = await AuthService.refresh();
    if (!refreshed) {
      await AuthService.logout();
      navigatorKey.currentState?.pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const LoginPage()),
        (route) => false,
      );
    }

    // Reintento 1 vez marcado
    return _send(requestFunction, retried: true);
  }

  // Headers con token actualizado
  static Map<String, String> _headers() {
    final token = Session.token;

    return {
      if (token != null) "Authorization": "Bearer $token",
      "Content-Type": "application/json",
    };
  }
}
