import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:expositor_app/core/constants/api_constants.dart';
import 'package:expositor_app/core/services/secure_storage_service.dart';
import 'package:expositor_app/data/models/vendedor.dart';

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
}
