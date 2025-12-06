import 'dart:convert';
import 'dart:typed_data';
import 'package:expositor_app/core/constants/api_constants.dart';
import 'package:expositor_app/data/models/producto.dart';
import 'package:expositor_app/data/services/http_client_jwt.dart';

class ProductoService {
  /// Obtener todos los productos
  Future<List<Producto>> getAllProductos() async {
    final url = Uri.parse(ApiConstants.products);

    final response = await HttpClientJwt.get(url);

    if (response.statusCode == 200) {
      final List<dynamic> jsonList = jsonDecode(response.body);
      return jsonList.map((e) => Producto.fromJson(e)).toList();
    }

    print("❌ Error getAllProductos: ${response.statusCode}");
    return [];
  }

  /// Crear producto
  Future<bool> createProducto(Producto producto) async {
    final url = Uri.parse(ApiConstants.products);

    final body = jsonEncode(producto.toJson());

    final response = await HttpClientJwt.post(url, body: body);

    if (response.statusCode == 201 || response.statusCode == 200) {
      print("✅ Producto creado correctamente");
      return true;
    }

    print("❌ Error createProducto: ${response.statusCode}");
    print(response.body);
    return false;
  }

  /// Actualizar producto
  Future<bool> updateProducto(Producto producto) async {
    final url = Uri.parse("${ApiConstants.products}/${producto.id}/update");

    final body = jsonEncode(producto.toJson());

    final response = await HttpClientJwt.put(url, body: body);

    if (response.statusCode == 200) {
      print("✅ Producto actualizado correctamente");
      return true;
    }

    print("❌ Error updateProducto: ${response.statusCode}");
    print(response.body);
    return false;
  }

  /// Obtener producto por ID
  Future<Producto?> getProducto(int idProducto) async {
    final url = Uri.parse("${ApiConstants.products}/$idProducto");

    final response = await HttpClientJwt.get(url);

    if (response.statusCode == 200) {
      return Producto.fromJson(jsonDecode(response.body));
    }

    print("❌ Error getProducto: ${response.statusCode}");
    return null;
  }

  /// Descargar CSV de productos
  Future<Uint8List?> getProductosCsv() async {
    final url = Uri.parse("${ApiConstants.products}/csv");

    final response = await HttpClientJwt.get(url);

    if (response.statusCode == 200) {
      return response.bodyBytes;
    }

    print("❌ Error getProductosCsv: ${response.statusCode}");
    return null;
  }
}
