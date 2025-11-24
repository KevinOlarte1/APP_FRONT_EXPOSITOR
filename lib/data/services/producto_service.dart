import 'package:expositor_app/core/services/secure_storage_service.dart';
import 'package:expositor_app/data/enums/categoria_product.dart';
import 'package:expositor_app/data/models/producto.dart';
import 'package:expositor_app/core/constants/api_constants.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class ProductoService {
  final SecureStorageService _storage = SecureStorageService();

  Future<List<Producto>> getAllProductos() async {
    final token = await _storage.getAccessToken();
    final url = Uri.parse(ApiConstants.products);
    if (token == null) return [];
    try {
      final response = await http.get(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );
      print("Al menos llega aqui ");
      if (response.statusCode == 200) {
        final List<dynamic> jsonList = jsonDecode(response.body);

        // Convertimos cada item al modelo Producto
        return jsonList.map((jsonItem) {
          return Producto.fromJson(jsonItem);
        }).toList();
      } else {
        print("❌ Error al obtener productos: ${response.statusCode}");
        return [];
      }
    } catch (e) {
      print("⚠️ Error de conexión al obtener productos: $e");
      return [];
    }
  }

  Future<bool> createProducto(Producto producto) async {
    final url = Uri.parse(ApiConstants.products);
    final token = await _storage.getAccessToken();
    if (token == null) return false;
    try {
      final body = producto.toJson(); //TODO: MIRAR SI ESTO ETA BIEN
      final response = await http.post(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(body),
      );
      if (response.statusCode == 201) {
        print("✅ Producto creado correctamente");
        return true;
      } else {
        print("❌ Error al crear producto: ${response.statusCode}");
        print(response.body);
        return false;
      }
    } catch (e) {
      print("⚠️ Error de conexión al crear producto: $e");

      return false;
    }
  }

  Future<bool> updateProducto(Producto producto) async {
    try {
      final url = Uri.parse("${ApiConstants.products}/${producto.id}/update");
      final token = await _storage.getAccessToken();
      if (token == null) return false;

      final body = producto.toJson();
      final response = await http.put(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(body),
      );
      if (response.statusCode == 200) {
        print("✅ Producto actualizado correctamente");
        return true;
      } else {
        print("❌ Error al actualizar producto: ${response.statusCode}");
        print(response.body);
        return false;
      }
    } catch (e) {
      print("⚠️ Error de conexión al crear producto: $e");
      return false;
    }
  }
}
