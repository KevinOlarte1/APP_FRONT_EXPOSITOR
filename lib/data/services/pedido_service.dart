import 'dart:convert';
import 'package:expositor_app/core/constants/api_constants.dart';
import 'package:expositor_app/data/models/pedido.dart';
import 'package:expositor_app/data/services/http_client_jwt.dart';

class PedidoService {
  /// Crear un nuevo pedido
  Future<Pedido?> addPedido({
    required int idCliente,
    required int descuento,
    required int iva,
  }) async {
    final url = Uri.parse("${ApiConstants.clientes}/$idCliente/pedido/admin");

    final body = jsonEncode({"descuento": descuento, "iva": iva});

    final response = await HttpClientJwt.post(url, body: body);

    if (response.statusCode == 200 || response.statusCode == 201) {
      final jsonData = jsonDecode(response.body);
      return Pedido.fromJson(jsonData);
    }

    print("❌ Error addPedido: ${response.statusCode}");
    return null;
  }

  /// Obtener un pedido concreto
  Future<Pedido?> getPedido({
    required int idCliente,
    required int idPedido,
  }) async {
    final url = Uri.parse(
      "${ApiConstants.clientes}/$idCliente/pedido/$idPedido",
    );

    final response = await HttpClientJwt.get(url);

    if (response.statusCode == 200) {
      final jsonData = jsonDecode(response.body);
      return Pedido.fromJson(jsonData);
    }

    if (response.statusCode == 404) {
      return null; // Pedido no encontrado o no autorizado
    }

    print("❌ Error getPedido: ${response.statusCode}");
    return null;
  }

  /// Obtener todos los pedidos de un cliente (modo admin)
  Future<List<Pedido>> getPedidosByClienteAdmin(int idCliente) async {
    final url = Uri.parse("${ApiConstants.clientes}/$idCliente/pedido/admin");

    final response = await HttpClientJwt.get(url);

    if (response.statusCode == 200) {
      final List data = jsonDecode(response.body);
      return data.map((e) => Pedido.fromJson(e)).toList();
    }

    if (response.statusCode == 404) {
      return []; // Cliente sin pedidos / no autorizado
    }

    print("❌ Error getPedidosByClienteAdmin: ${response.statusCode}");
    return [];
  }

  Future<Pedido?> updatePedido({
    required int idCliente,
    required int idPedido,
    required int descuento,
    required int iva,
  }) async {
    final url = Uri.parse(
      "${ApiConstants.clientes}/$idCliente/pedido/$idPedido",
    );

    final body = jsonEncode({"descuento": descuento, "iva": iva});

    final response = await HttpClientJwt.put(url, body: body);

    if (response.statusCode == 200) {
      return Pedido.fromJson(jsonDecode(response.body));
    }

    return null;
  }

  Future<bool> cerrarPedido(int idCliente, int idPedido) async {
    final url = Uri.parse(
      "${ApiConstants.clientes}/$idCliente/pedido/$idPedido/cerrar",
    );

    final response = await HttpClientJwt.put(url);

    return response.statusCode == 200;
  }
}
