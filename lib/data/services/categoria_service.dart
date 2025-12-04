import 'dart:convert';
import 'package:expositor_app/data/services/http_client_jwt.dart';
import 'package:http/http.dart' as http;

import '../models/categoria.dart';
import 'package:expositor_app/core/constants/api_constants.dart';

class CategoriaService {
  /// Obtener todas las categorías
  Future<List<Categoria>> getCategorias() async {
    final url = Uri.parse(ApiConstants.categorias);

    // ✔ Ahora sí: await al llamar
    final response = await HttpClientJwt.get(url);

    if (response.statusCode == 200) {
      final List data = jsonDecode(response.body);
      return data.map((e) => Categoria.fromJson(e)).toList();
    } else {
      print(
        "❌ Error al obtener categorías: ${response.statusCode} — ${response.body}",
      );
      return [];
    }
  }

  /// Actualizar categoría
  Future<Categoria?> updateCategoria(int id, String nuevoNombre) async {
    final url = Uri.parse("${ApiConstants.categorias}/$id");

    final response = await HttpClientJwt.put(
      url,
      body: jsonEncode({"nombre": nuevoNombre}),
    );

    if (response.statusCode == 200) {
      final json = jsonDecode(response.body);
      return Categoria.fromJson(json);
    }

    print("❌ Error al actualizar categoría: ${response.statusCode}");
    return null;
  }

  /// Crear nueva categoría
  Future<Categoria?> addCategoria(String nombre) async {
    final url = Uri.parse(ApiConstants.categorias);

    final response = await HttpClientJwt.post(
      url,
      body: jsonEncode({"nombre": nombre}),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      return Categoria.fromJson(jsonDecode(response.body));
    }

    print("❌ Error al crear categoría: ${response.statusCode}");
    return null;
  }
}
