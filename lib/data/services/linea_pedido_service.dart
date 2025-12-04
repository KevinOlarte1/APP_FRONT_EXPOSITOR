import 'dart:convert';

import 'package:expositor_app/core/constants/api_constants.dart';
import 'package:expositor_app/core/services/secure_storage_service.dart';
import 'package:expositor_app/data/models/linea_pedido.dart';
import 'package:http/http.dart' as http;

class LineaPedidoService {
  final SecureStorageService _storage = SecureStorageService();

  Future<List<LineaPedido>> getLineasPedido(int idCliente, int idPedido) async {
    final token = await _storage.getAccessToken();
    if (token == null) return [];
    final response = await http.get(
      Uri.parse("${ApiConstants.clientes}/$idCliente/pedido/$idPedido/linea"),
      headers: {
        "Authorization": "Bearer $token",
        "Content-Type": "application/json",
      },
    );

    final data = jsonDecode(response.body);
    return (data as List).map((e) => LineaPedido.fromJson(e)).toList();
  }

  Future<LineaPedido?> addLineaPedido(
    int idCliente,
    int idPedido,
    int idProducto,
    int cantidad,
    double precio,
  ) async {
    final token = await _storage.getAccessToken();
    if (token == null) return null;

    final url = Uri.parse(
      "${ApiConstants.clientes}/$idCliente/pedido/$idPedido/linea",
    );

    final body = jsonEncode({
      "idProducto": idProducto,
      "cantidad": cantidad,
      "precio": precio,
    });

    final response = await http.post(
      url,
      headers: {
        "Authorization": "Bearer $token",
        "Content-Type": "application/json",
      },
      body: body,
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      final data = jsonDecode(response.body);
      return LineaPedido.fromJson(data); // 🔥 devuelve la línea creada
    }

    return null;
  }

  Future<bool> deleteLineaPedido(
    int idCliente,
    int idPedido,
    int idLinea,
  ) async {
    final token = await _storage.getAccessToken();
    if (token == null) return false;

    final url = Uri.parse(
      "${ApiConstants.clientes}/$idCliente/pedido/$idPedido/linea/admin/$idLinea",
    );

    final response = await http.delete(
      url,
      headers: {
        "Authorization": "Bearer $token",
        "Content-Type": "application/json",
      },
    );

    return response.statusCode == 204;
  }

  Future<LineaPedido?> updateLineaPedido(
    int idCliente,
    int idPedido,
    int idLinea,
    int cantidad,
    double precio,
  ) async {
    final token = await _storage.getAccessToken();
    if (token == null) return null;

    final url = Uri.parse(
      "${ApiConstants.clientes}/$idCliente/pedido/$idPedido/linea/$idLinea/admin",
    );

    final body = jsonEncode({"cantidad": cantidad, "precio": precio});

    final response = await http.put(
      url,
      headers: {
        "Authorization": "Bearer $token",
        "Content-Type": "application/json",
      },
      body: body,
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return LineaPedido.fromJson(data);
    }

    return null;
  }
}
