import 'dart:convert';
import 'package:expositor_app/core/session/session.dart';
import 'package:expositor_app/core/navigation/navigator_key.dart';
import 'package:expositor_app/presentation/pages/login/login_page.dart';
import 'package:http/http.dart' as http;
import 'package:expositor_app/core/services/secure_storage_service.dart';
import 'package:expositor_app/data/services/auth_service.dart';
import 'package:flutter/material.dart';

class HttpClientJwt {
  static final SecureStorageService _storage = SecureStorageService();

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
    var token = Session.token;
    request.headers["Authorization"] = "Bearer $token";

    http.StreamedResponse response = await request.send();

    if (response.statusCode != 401) return response;

    final refreshed = await AuthService.refresh();

    if (!refreshed) return response;

    token = Session.token;
    request.headers["Authorization"] = "Bearer $token";
    return await request.send();
  }

  // ── Lógica central: refresh token automático ──
  static Future<http.Response> _send(
    Future<http.Response> Function() requestFunction, {
    bool retried = false,
  }) async {
    final response = await requestFunction();

    if (response.statusCode != 401) return response;

    if (retried) {
      await AuthService.logout();
      navigatorKey.currentState?.pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const LoginPage()),
        (route) => false,
      );
    }

    final refreshed = await AuthService.refresh();
    if (!refreshed) {
      await AuthService.logout();
      navigatorKey.currentState?.pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const LoginPage()),
        (route) => false,
      );
    }

    return _send(requestFunction, retried: true);
  }

  static Map<String, String> _headers() {
    final token = Session.token;
    return {
      if (token != null) "Authorization": "Bearer $token",
      "Content-Type": "application/json",
    };
  }
}
