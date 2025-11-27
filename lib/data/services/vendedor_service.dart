import 'dart:collection';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:expositor_app/core/constants/api_constants.dart';
import 'package:expositor_app/core/services/secure_storage_service.dart';
import 'package:expositor_app/data/models/vendedor.dart';
import 'package:expositor_app/data/models/stats/ingreso_cliente.dart';

class VendedorService {
  final SecureStorageService _storage = SecureStorageService();

  Future<Vendedor?> getMe() async {
    final token = await _storage.getAccessToken();
    if (token == null) return null;

    final url = Uri.parse("${ApiConstants.vendedor}/me");

    try {
      final response = await http.get(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return Vendedor.fromJson(data);
      } else {
        print("❌ Error ${response.statusCode}: ${response.body}");
        return null;
      }
    } catch (e) {
      print("⚠️ Error al obtener vendedor: $e");
      return null;
    }
  }

  Future<List<Vendedor>> getVendedores() async {
    final token = await _storage.getAccessToken();
    if (token == null) return [];

    final url = Uri.parse(ApiConstants.vendedor);
    try {
      final response = await http.get(
        url,
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> jsonList = jsonDecode(response.body);

        return jsonList.map((json) {
          return Vendedor.fromJson(json);
        }).toList();
      } else {
        print("❌ Error al obtener vendedores: ${response.statusCode}");
        print(response.body);
        return [];
      }
    } catch (e) {
      print("⚠️ Error de conexión al obtener vendedores: $e");
      return [];
    }
  }

  Future<Map<String, int>> getNumPedidos(int idVendedor) async {
    final token = await _storage.getAccessToken();
    if (token == null) return new HashMap();
    try {
      final response = await http.get(
        Uri.parse("${ApiConstants.vendedor}/$idVendedor/stats/numPedido"),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);

        // Convertimos los valores dinámicos a enteros
        return data.map((key, value) => MapEntry(key, value as int));
      } else {
        print("Error al obtener numPedidos: ${response.statusCode}");
        return new HashMap();
      }
    } catch (e) {
      print("⚠️ Error al obtener numPedidos: $e");
      return new HashMap();
    }
  }

  // ----------------------------------------------------------------------
  //  OBTENER VENTAS POR CATEGORÍA (Map<String, int>)
  // ----------------------------------------------------------------------
  Future<Map<String, int>> getStatsProductsByCategory(int idVendedor) async {
    print("Holaa");
    final token = await _storage.getAccessToken();
    if (token == null) return {};

    final String url =
        "${ApiConstants.vendedor}/$idVendedor/stats/numProductsCategoria";

    try {
      print("llega");
      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );
      print("------");

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);

        // Convertir dinámicos a int
        final Map<String, int> result = data.map(
          (key, value) => MapEntry(
            key,
            (value as num).toInt(), // por si viene como long
          ),
        );

        return result;
      } else {
        throw Exception("Error ${response.statusCode}: ${response.body}");
      }
    } catch (e) {
      throw Exception("Error al obtener categorías: $e");
    }
  }

  // ----------------------------------------------------------------------
  //  OBTENER ingresos anual de un vendedor (Map<String, int>)
  // ----------------------------------------------------------------------
  // ----------------------------------------------------------------------
  //  OBTENER GASTOS POR CLIENTE (List<IngresoCliente>)
  // ----------------------------------------------------------------------
  Future<List<IngresoCliente>> getIngresoAnualByCliente(int idVendedor) async {
    final token = await _storage.getAccessToken();
    if (token == null) return [];

    final String url =
        "${ApiConstants.vendedor}/$idVendedor/stats/gastoPorCliente";

    try {
      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);

        return data.map((e) => IngresoCliente.fromJson(e)).toList();
      } else {
        throw Exception("Error ${response.statusCode}: ${response.body}");
      }
    } catch (e) {
      throw Exception("Error al obtener gasto por cliente: $e");
    }
  }

  Future<bool> updateVendedor(Vendedor vendedor, {String? password}) async {
    final token = await _storage.getAccessToken();
    if (token == null) return false;

    final url = "${ApiConstants.vendedor}/${vendedor.id}";

    // Construimos el DTO según el backend
    final Map<String, dynamic> body = {
      "nombre": vendedor.nombre,
      "apellido": vendedor.apellido,
      "email": vendedor.email,
    };

    // Si password no es null, lo enviamos
    if (password != null && password.trim().isNotEmpty) {
      body["password"] = password;
    }

    try {
      final response = await http.put(
        Uri.parse(url),
        headers: {
          "Authorization": "Bearer $token",
          "Content-Type": "application/json",
        },
        body: jsonEncode(body),
      );

      if (response.statusCode == 200 || response.statusCode == 204) {
        return true;
      } else {
        print("Error actualizando vendedor: ${response.body}");
        return false;
      }
    } catch (e) {
      print("Excepción en updateVendedor: $e");
      return false;
    }
  }

  Future<Vendedor?> createVendedor({
    required String nombre,
    required String apellido,
    required String email,
    required String password,
  }) async {
    final token = await _storage.getAccessToken();
    if (token == null) return null;

    final String url = "${ApiConstants.vendedor}"; // /api/vendedor

    try {
      final response = await http.post(
        Uri.parse(url),
        headers: {
          "Authorization": "Bearer $token",
          "Content-Type": "application/json",
        },
        body: jsonEncode({
          "nombre": nombre,
          "apellido": apellido,
          "email": email,
          "password": password,
        }),
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        final json = jsonDecode(response.body);
        return Vendedor.fromJson(json);
      }

      print("Error creando vendedor: ${response.body}");
      return null;
    } catch (e) {
      print("Excepción creando vendedor: $e");
      return null;
    }
  }

  Future<Vendedor?> getById(int idVendedor) async {
    final token = await _storage.getAccessToken();
    if (token == null) return null;

    final url = Uri.parse("${ApiConstants.vendedor}/$idVendedor");

    try {
      final response = await http.get(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return Vendedor.fromJson(data);
      } else {
        print("❌ Error ${response.statusCode}: ${response.body}");
        return null;
      }
    } catch (e) {
      print("⚠️ Error al obtener vendedor por ID: $e");
      return null;
    }
  }
}
