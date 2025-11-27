import 'dart:convert';
import 'package:expositor_app/core/constants/api_constants.dart';
import 'package:expositor_app/data/models/cliente.dart';
import 'package:http/http.dart' as http;
import 'package:expositor_app/core/services/secure_storage_service.dart';

class ClienteService {
  final SecureStorageService _storage = SecureStorageService();

  Future<List<Cliente>> getAllClientes() async {
    final token = await _storage.getAccessToken();
    if (token == null) return [];

    final url = "${ApiConstants.clientes}/admin"; // 👉 /api/cliente/admin

    final response = await http.get(
      Uri.parse(url),
      headers: {
        "Authorization": "Bearer $token",
        "Content-Type": "application/json",
      },
    );

    if (response.statusCode == 200) {
      final List data = jsonDecode(response.body);
      return data.map((e) => Cliente.fromJson(e)).toList();
    }

    return [];
  }

  Future<Map<String, double>> getIngresoAnual(int idCliente) async {
    final token = await _storage.getAccessToken();
    if (token == null) return {};

    final url = Uri.parse("${ApiConstants.clientes}/admin/$idCliente/stats");

    try {
      final response = await http.get(
        url,
        headers: {
          "Authorization": "Bearer $token",
          "Content-Type": "application/json",
        },
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> json = jsonDecode(response.body);

        // Convertimos dinámicos a double
        final Map<String, double> map = json.map(
          (k, v) => MapEntry(k, (v as num).toDouble()),
        );

        // ⚡️ Añadir manualmente el 2026
        map["2026"] = 29000.0;

        // ⭐ ORDENAR POR AÑO (clave numérica)
        final sortedKeys = map.keys.toList()
          ..sort((a, b) => int.parse(a).compareTo(int.parse(b)));

        final sortedMap = {for (var key in sortedKeys) key: map[key]!};

        return sortedMap;
      } else {
        print("❌ Error obteniendo ingreso anual: ${response.body}");
        return {};
      }
    } catch (e) {
      print("⚠️ Error getIngresoAnual: $e");
      return {};
    }
  }
}
