import 'dart:convert';
import 'package:expositor_app/core/constants/api_constants.dart';
import 'package:http/http.dart' as http;
import '../dto/login_request.dart';
import '../dto/login_response.dart';

class AuthService {
  Future<LoginResponse?> login(LoginRequest request) async {
    final url = Uri.parse("${ApiConstants.auth}/login");

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': "application/json"},
        body: jsonEncode(request.toJson()),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return LoginResponse.fromJson(data);
      } else {
        print("Error en el login!");
        return null;
      }
    } catch (e) {
      print("Error conexion");
      return null;
    }
  }
}
