import 'dart:convert';
import 'package:expositor_app/core/constants/api_constants.dart';
import 'package:expositor_app/core/services/secure_storage_service.dart';
import 'package:expositor_app/data/models/pedido.dart';
import 'package:http/http.dart' as http;

class PedidoService {
  final SecureStorageService _storage = SecureStorageService();

  Future<Pedido?> addPedido({
    required int idCliente,
    required int descuento,
    required int iva,
  }) async {
    final token = await _storage.getAccessToken();
    if (token == null) return null;

    final url = Uri.parse("${ApiConstants.clientes}/$idCliente/pedido");

    final body = jsonEncode({"descuento": descuento, "iva": iva});

    final response = await http.post(
      url,
      headers: {
        "Authorization": "Bearer $token",
        "Content-Type": "application/json",
      },
      body: body,
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      final jsonData = json.decode(response.body);
      return Pedido.fromJson(jsonData);
    }

    return null;
  }

  Future<Pedido?> getPedido({
    required int idCliente,
    required int idPedido,
  }) async {
    final token = await _storage.getAccessToken();
    if (token == null) return null;

    final String url = "${ApiConstants.clientes}/$idCliente/pedido/$idPedido";

    final response = await http.get(
      Uri.parse(url),
      headers: {
        "Authorization": "Bearer $token",
        "Content-Type": "application/json",
      },
    );

    if (response.statusCode == 200) {
      final jsonData = json.decode(response.body);
      return Pedido.fromJson(jsonData);
    }

    if (response.statusCode == 404) {
      return null; // no existe o no tienes permisos
    }

    throw Exception("Error al obtener pedido: ${response.statusCode}");
  }

  Future<List<Pedido>> getPedidosByClienteAdmin(int idCliente) async {
    final token = await _storage.getAccessToken();
    if (token == null) return [];

    final String url = "${ApiConstants.clientes}/$idCliente/pedido/admin";

    final response = await http.get(
      Uri.parse(url),
      headers: {
        "Authorization": "Bearer $token",
        "Content-Type": "application/json",
      },
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);

      return data.map((jsonItem) => Pedido.fromJson(jsonItem)).toList();
    }

    if (response.statusCode == 404) {
      return []; // cliente sin pedidos o no encontrado
    }

    throw Exception(
      "Error al obtener pedidos del cliente: ${response.statusCode}",
    );
  }
}
