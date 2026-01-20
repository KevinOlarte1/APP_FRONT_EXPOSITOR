import 'dart:convert';
import 'package:expositor_app/core/constants/api_constants.dart';
import 'package:expositor_app/data/services/http_client_jwt.dart';

class ParametrosGlobalesService {
  /// GET /api/config
  Future<Map<String, dynamic>> getParams() async {
    final url = Uri.parse(ApiConstants.config);

    final response = await HttpClientJwt.get(url);

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }

    throw Exception(
      "Error obteniendo parámetros globales: ${response.statusCode}",
    );
  }

  /// POST /api/config
  Future<bool> saveParams({
    required double iva,
    required double descuento,
    required int grupoMax,
  }) async {
    final url = Uri.parse("${ApiConstants.baseUrl}/config");

    final body = jsonEncode({
      "iva": iva,
      "descuento": descuento,
      "grupoMax": grupoMax,
    });

    final response = await HttpClientJwt.post(url, body: body);

    return response.statusCode == 200;
  }

  Future<int> getIVA() async {
    final url = Uri.parse("${ApiConstants.baseUrl}/config/iva");

    final response = await HttpClientJwt.get(url);

    if (response.statusCode == 200) {
      try {
        return int.parse(response.body);
      } catch (e) {
        return 0;
      }
    }

    throw Exception("Error obteniendo IVA");
  }

  Future<int> getDescuento() async {
    final url = Uri.parse("${ApiConstants.baseUrl}/config/descuento");

    final response = await HttpClientJwt.get(url);

    if (response.statusCode == 200) {
      try {
        return int.parse(response.body);
      } catch (e) {
        return 0;
      }
    }

    return 0;
  }

  Future<int> getGrupoMax() async {
    final url = Uri.parse("${ApiConstants.config}/grupoMax");

    final response = await HttpClientJwt.get(url);

    if (response.statusCode == 200) {
      try {
        return int.parse(response.body);
      } catch (e) {
        return 0;
      }
    }

    return 0;
  }
}
