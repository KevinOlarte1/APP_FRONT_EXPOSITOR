import 'dart:convert';
import 'dart:typed_data';
import 'package:expositor_app/core/constants/api_constants.dart';
import 'package:expositor_app/data/models/cliente.dart';
import 'package:expositor_app/data/services/http_client_jwt.dart';

class ClienteService {
  /// Obtener todos los clientes (modo admin)
  Future<List<Cliente>> getAllClientes() async {
    final url = Uri.parse("${ApiConstants.clientes}/admin");

    final response = await HttpClientJwt.get(url);

    if (response.statusCode == 200) {
      final List data = jsonDecode(response.body);
      return data.map((e) => Cliente.fromJson(e)).toList();
    }

    print("❌ Error getAllClientes: ${response.statusCode}");
    return [];
  }

  /// Obtener cliente por ID
  Future<Cliente?> getClienteById(int idCliente) async {
    final url = Uri.parse("${ApiConstants.clientes}/admin/$idCliente");

    final response = await HttpClientJwt.get(url);

    if (response.statusCode == 200) {
      final jsonData = jsonDecode(response.body);
      return Cliente.fromJson(jsonData);
    }

    print("❌ Error getClienteById: ${response.statusCode}");
    return null;
  }

  /// Obtener ingreso anual del cliente
  Future<Map<String, double>> getIngresoAnual(int idCliente) async {
    final url = Uri.parse("${ApiConstants.clientes}/admin/$idCliente/stats");

    final response = await HttpClientJwt.get(url);

    if (response.statusCode == 200) {
      final Map<String, dynamic> json = jsonDecode(response.body);

      // Pasar dinámicos a double
      final Map<String, double> map = json.map(
        (k, v) => MapEntry(k, (v as num).toDouble()),
      );

      // Ordenar por año
      final sortedKeys = map.keys.toList()
        ..sort((a, b) => int.parse(a).compareTo(int.parse(b)));

      final sorted = {for (var k in sortedKeys) k: map[k]!};

      return sorted;
    }

    print("❌ Error getIngresoAnual: ${response.statusCode}");
    return {};
  }

  /// Descargar CSV de clientes
  Future<Uint8List?> getClientesCsv() async {
    final url = Uri.parse("${ApiConstants.clientes}/csv");

    final response = await HttpClientJwt.get(url);

    if (response.statusCode == 200) {
      return response.bodyBytes; // CSV completo
    }

    print("❌ Error getClientesCsv: ${response.statusCode}");
    return null;
  }
}
