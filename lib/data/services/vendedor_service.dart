import 'dart:convert';
import 'package:expositor_app/core/constants/api_constants.dart';
import 'package:expositor_app/data/models/vendedor.dart';
import 'package:expositor_app/data/models/stats/ingreso_cliente.dart';
import 'package:expositor_app/data/services/http_client_jwt.dart';

class VendedorService {
  /// Obtener el vendedor autenticado
  Future<Vendedor?> getMe() async {
    final url = Uri.parse("${ApiConstants.vendedor}/me");

    final response = await HttpClientJwt.get(url);

    if (response.statusCode == 200) {
      return Vendedor.fromJson(jsonDecode(response.body));
    }

    print("❌ Error getMe: ${response.statusCode}");
    print(response.body);
    return null;
  }

  /// Obtener todos los vendedores (admin)
  Future<List<Vendedor>> getVendedores() async {
    final url = Uri.parse(ApiConstants.vendedor);

    final response = await HttpClientJwt.get(url);

    if (response.statusCode == 200) {
      final List<dynamic> jsonList = jsonDecode(response.body);
      return jsonList.map((e) => Vendedor.fromJson(e)).toList();
    }

    print("❌ Error getVendedores: ${response.statusCode}");
    print(response.body);
    return [];
  }

  /// Obtener número de pedidos por vendedor - ADMIN
  Future<Map<String, int>> getNumPedidos({int? idVendedor}) async {
    final url = Uri.parse(
      idVendedor != null
          ? "${ApiConstants.vendedor}/$idVendedor/stats/numPedido"
          : "${ApiConstants.vendedor}/stats/numPedido",
    );

    final response = await HttpClientJwt.get(url);

    if (response.statusCode == 200) {
      final Map<String, dynamic> data = jsonDecode(response.body);
      return data.map((k, v) => MapEntry(k, (v as num).toInt()));
    }

    print("❌ Error getNumPedidos: ${response.statusCode}");
    print(response.body);
    return {};
  }

  /// Obtener productos vendidos por categoría - ADMIN
  Future<Map<String, int>> getStatsProductsByCategory({int? idVendedor}) async {
    final url = Uri.parse(
      idVendedor != null
          ? "${ApiConstants.vendedor}/$idVendedor/stats/numProductsCategoria"
          : "${ApiConstants.vendedor}/stats/numProductsCategoria",
    );

    final response = await HttpClientJwt.get(url);

    if (response.statusCode == 200) {
      final Map<String, dynamic> data = jsonDecode(response.body);
      return data.map((k, v) => MapEntry(k, (v as num).toInt()));
    }

    print("❌ Error getStatsProductsByCategory: ${response.statusCode}");
    print(response.body);
    return {};
  }

  /// Obtener ingreso anual por cliente (gasto) - ADMIN
  Future<List<IngresoCliente>> getIngresoAnualByCliente({
    int? idVendedor,
  }) async {
    final url = Uri.parse(
      idVendedor != null
          ? "${ApiConstants.vendedor}/$idVendedor/stats/gastoPorCliente"
          : "${ApiConstants.vendedor}/stats/gastoPorCliente",
    );

    final response = await HttpClientJwt.get(url);

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((e) => IngresoCliente.fromJson(e)).toList();
    }

    print("❌ Error getIngresoAnualByCliente: ${response.statusCode}");
    print(response.body);
    return [];
  }

  /// Actualizar datos del vendedor
  Future<bool> updateVendedor(Vendedor vendedor, {String? password}) async {
    final url = Uri.parse("${ApiConstants.vendedor}/${vendedor.id}");

    final Map<String, dynamic> body = {
      "nombre": vendedor.nombre,
      "apellido": vendedor.apellido,
      "email": vendedor.email,
    };

    if (password != null && password.trim().isNotEmpty) {
      body["password"] = password;
    }

    final response = await HttpClientJwt.put(url, body: jsonEncode(body));

    if (response.statusCode == 200 || response.statusCode == 204) {
      return true;
    }

    print("❌ Error updateVendedor: ${response.statusCode}");
    print(response.body);
    return false;
  }

  /// Crear nuevo vendedor
  Future<Vendedor?> createVendedor({
    required String nombre,
    required String apellido,
    required String email,
    required String password,
  }) async {
    final url = Uri.parse(ApiConstants.vendedor);

    final body = jsonEncode({
      "nombre": nombre,
      "apellido": apellido,
      "email": email,
      "password": password,
    });

    final response = await HttpClientJwt.post(url, body: body);

    if (response.statusCode == 200 || response.statusCode == 201) {
      return Vendedor.fromJson(jsonDecode(response.body));
    }

    print("❌ Error createVendedor: ${response.statusCode}");
    print(response.body);
    return null;
  }

  /// Obtener vendedor por ID
  Future<Vendedor?> getById(int idVendedor) async {
    final url = Uri.parse("${ApiConstants.vendedor}/$idVendedor");

    final response = await HttpClientJwt.get(url);

    if (response.statusCode == 200) {
      return Vendedor.fromJson(jsonDecode(response.body));
    }

    print("❌ Error getById: ${response.statusCode}");
    print(response.body);
    return null;
  }
}
