import 'dart:convert';
import 'package:expositor_app/core/constants/api_constants.dart';
import 'package:expositor_app/core/session/session.dart';
import 'package:expositor_app/data/models/linea_pedido.dart';
import 'package:expositor_app/data/services/http_client_jwt.dart';


class LineaPedidoService {
  /// Obtener todas las líneas de un pedido
  Future<List<LineaPedido>> getLineasPedido(int idCliente, int idPedido) async {
    final url = Uri.parse(
      "${ApiConstants.clientes}/$idCliente/pedido/$idPedido/linea",
    );

    final response = await HttpClientJwt.get(url);

    if (response.statusCode == 200) {
      final List json = jsonDecode(response.body);
      return json.map((e) => LineaPedido.fromJson(e)).toList();
    }

    print("❌ Error getLineasPedido: ${response.statusCode}");
    return [];
  }

  /// Crear una nueva línea
  Future<LineaPedido?> addLineaPedido(
    int idCliente,
    int idPedido,
    int idProducto,
    int cantidad,
    double precio,
    int grupo,
  ) async {
    final url = Uri.parse(
      "${ApiConstants.clientes}/$idCliente/pedido/$idPedido/linea",
    );
    print("Obtener Lineas de los pedidos");
    final body = jsonEncode({
      "idProducto": idProducto,
      "cantidad": cantidad,
      "precio": precio,
      "grupo": grupo,
    });

    final response = await HttpClientJwt.post(url, body: body);

    print("Antes del codigo ");
    if (response.statusCode == 200 || response.statusCode == 201) {
      final data = jsonDecode(response.body);
      print("Code");
      print(data);
      return LineaPedido.fromJson(data);
    }

    print("❌ Error addLineaPedido: ${response.statusCode}");
    return null;
  }

  /// Eliminar una línea
  Future<bool> deleteLineaPedido(
    int idCliente,
    int idPedido,
    int idLinea,
  ) async {
    final url = Uri.parse(
      "${ApiConstants.clientes}/$idCliente/pedido/$idPedido/linea/$idLinea",
    );

    final response = await HttpClientJwt.delete(url);

    return response.statusCode == 204;
  }

  /// Actualizar cantidad/precio de una línea
  Future<LineaPedido?> updateLineaPedido(
    int idCliente,
    int idPedido,
    int idLinea,
    int cantidad,
    double precio,
  ) async {
    final url = Uri.parse(
      "${ApiConstants.clientes}/$idCliente/pedido/$idPedido/linea/$idLinea",
    );

    final body = jsonEncode({"cantidad": cantidad, "precio": precio});

    final response = await HttpClientJwt.put(url, body: body);

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return LineaPedido.fromJson(data);
    }

    print("❌ Error updateLineaPedido: ${response.statusCode}");
    return null;
  }

  static Future<bool> actualizarStockFinal({
    required int idCliente,
    required int idPedido,
    required int idLinea,
    required int stockFinal,
  }) async {
    final url = Uri.parse(
      "${ApiConstants.clientes}/$idCliente/pedido/$idPedido/linea/$idLinea/stock",
    );

    // Si tu backend espera JSON con clave:
    final body = jsonEncode({"stockFinal": stockFinal});

    try {
      final response = await HttpClientJwt.put(url, body: body);

      // Ajusta esto según lo que devuelva tu HttpClientJwt (statusCode, bool, etc.)
      if (response.statusCode == 200 || response.statusCode == 204) {
        return true;
      }

      print("❌ actualizarStockFinal ${response.statusCode}: ${response.body}");
      return false;
    } catch (e) {
      print("❌ actualizarStockFinal error: $e");
      return false;
    }
  }

 
}
