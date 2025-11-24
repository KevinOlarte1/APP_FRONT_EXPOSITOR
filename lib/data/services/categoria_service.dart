import 'dart:convert';
import 'package:http/http.dart' as http;

import '../models/categoria.dart';
import 'package:expositor_app/core/constants/api_constants.dart';
import 'package:expositor_app/core/services/secure_storage_service.dart';

class CategoriaService {
  final SecureStorageService _storage = SecureStorageService();

  /// Obtener todas las categorías
  Future<List<Categoria>> getCategorias() async {
    final token = await _storage.getAccessToken();
    if (token == null) return [];

    final url = "${ApiConstants.categorias}";

    try {
      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final List data = jsonDecode(response.body);
        return data.map((e) => Categoria.fromJson(e)).toList();
      } else {
        print("Error al obtener categorías: ${response.body}");
        return [];
      }
    } catch (e) {
      print("Excepción obteniendo categorías: $e");
      return [];
    }
  }

  Future<Categoria?> updateCategoria(int id, String nuevoNombre) async {
    final token = await _storage.getAccessToken();

    final response = await http.put(
      Uri.parse("${ApiConstants.categorias}/$id"),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({"nombre": nuevoNombre}),
    );

    if (response.statusCode == 200) {
      final json = jsonDecode(response.body);
      return Categoria.fromJson(json);
    }

    return null; // Error
  }

  Future<Categoria?> addCategoria(String nombre) async {
    final token = await _storage.getAccessToken();
    if (token == null) return null;

    final url = "${ApiConstants.categorias}"; // /api/categoria

    final response = await http.post(
      Uri.parse(url),
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $token",
      },
      body: jsonEncode({"nombre": nombre}),
    );

    if (response.statusCode == 201 || response.statusCode == 200) {
      return Categoria.fromJson(jsonDecode(response.body));
    }

    return null;
  }
}
