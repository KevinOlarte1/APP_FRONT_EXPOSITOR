import 'dart:convert';
import 'dart:typed_data';
import 'package:expositor_app/core/constants/api_constants.dart';
import 'package:expositor_app/core/session/session.dart';
import 'package:expositor_app/data/models/cliente.dart';
import 'package:expositor_app/data/services/http_client_jwt.dart';
import 'package:expositor_app/exceptions/import_error.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';

class ClienteService {
  Future<Cliente?> addCliente(
    String nombre,
    String cif,
    int? idVendedor,
    String telefono,
    String email,
  ) async {
    final url = Uri.parse(ApiConstants.clientes);
    final body = jsonEncode({
      "nombre": nombre,
      "cif": cif,
      "idVendedor": idVendedor,
      "telefono": telefono,
      "email": email,
    });
    final response = await HttpClientJwt.post(url, body: body);

    if (response.statusCode == 201) {
      final data = jsonDecode(response.body);
      return Cliente.fromJson(data);
    } else {
      print("Error ${response.statusCode}: ${response.body}");
      return null;
    }
  }

  /// Obtener todos los clientes (modo admin)
  Future<List<Cliente>> getAllClientes() async {
    final url;
    if (Session.isAdmin) {
      url = Uri.parse("${ApiConstants.clientes}/admin");
    } else {
      url = Uri.parse(ApiConstants.clientes);
    }

    final response = await HttpClientJwt.get(url);

    if (response.statusCode == 200) {
      final List data = jsonDecode(response.body);
      return data.map((e) => Cliente.fromJson(e)).toList();
    }

    print("❌ Error getAllClientes: ${response.statusCode}");
    return [];
  }

  /// Obtener cliente por ID
  Future<Cliente?> getClienteById(int idCliente) async {
    final url = Uri.parse("${ApiConstants.clientes}/$idCliente");

    final response = await HttpClientJwt.get(url);

    if (response.statusCode == 200) {
      final jsonData = jsonDecode(response.body);
      return Cliente.fromJson(jsonData);
    }

    print("❌ Error getClienteById: ${response.statusCode}");
    return null;
  }

  /// Obtener ingreso anual del cliente
  Future<Map<String, double>> getIngresoAnual(int idCliente) async {
    final url = Uri.parse("${ApiConstants.clientes}/$idCliente/stats");
    print("--------------------------");
    print("Estats");

    final response = await HttpClientJwt.get(url);

    if (response.statusCode == 200) {
      final Map<String, dynamic> json = jsonDecode(response.body);

      // Pasar dinámicos a double
      final Map<String, double> map = json.map(
        (k, v) => MapEntry(k, (v as num).toDouble()),
      );

      // Ordenar por año
      final sortedKeys = map.keys.toList()
        ..sort((a, b) => int.parse(a).compareTo(int.parse(b)));

      final sorted = {for (var k in sortedKeys) k: map[k]!};

      return sorted;
    }

    print("❌ Error getIngresoAnual: ${response.statusCode}");
    return {};
  }

  /// Descargar CSV de clientes
  Future<Uint8List?> getClientesCsv() async {
    final url = Uri.parse("${ApiConstants.config}/export/clientes");

    final response = await HttpClientJwt.get(url);

    if (response.statusCode == 200) {
      return response.bodyBytes; // CSV completo
    }

    print("❌ Error getClientesCsv: ${response.statusCode}");
    return null;
  }

  Future<ImportError?> importarClientesCsv(
    Uint8List bytes,
    String filename,
  ) async {
    final request = http.MultipartRequest(
      'POST',
      Uri.parse('${ApiConstants.config}/import/clientes'),
    );
    request.headers['Authorization'] = 'Bearer ${Session.token}';
    request.headers['Accept'] = 'application/json';

    request.files.add(
      http.MultipartFile.fromBytes(
        'file',
        bytes,
        filename: filename,
        contentType: MediaType('text', 'csv'),
      ),
    );

    final streamed = await request.send();
    final body = await streamed.stream.bytesToString();

    final ok = streamed.statusCode == 200;

    if (streamed.statusCode == 200) {
      return null;
    } else {
      try {
        final decoded = jsonDecode(body);
        return ImportError.fromJson(decoded);
      } catch (e) {
        return ImportError(id: "unknown", nombre: "Error desconocido");
      }
    }
  }

  Future<bool> deleteDatos() async {
    final uri = Uri.parse('${ApiConstants.config}/import/delete');

    final response = await http.delete(
      uri,
      headers: {
        'Authorization': 'Bearer ${Session.token}',
        'Accept': 'application/json',
      },
    );

    final ok = response.statusCode == 200 || response.statusCode == 204;

    if (!ok) {
      print('❌ ${response.statusCode}: ${response.body}');
    } else {
      print('✅ ${response.statusCode}: ${response.body}');
    }

    return ok;
  }

  Future<Cliente?> update(Cliente actualizado) async {
    final url = Uri.parse("${ApiConstants.clientes}/${actualizado.id}");
    print("object------");
    print(actualizado.telefono);
    final body = jsonEncode({
      "id": actualizado.id,
      "nombre": actualizado.nombre,
      "cif": actualizado.cif,
      "telefono": actualizado.telefono,
      "email": actualizado.email,
      "idVendedor": actualizado.idVendedor,
    });

    final response = await HttpClientJwt.put(url, body: body);

    if (response.statusCode == 200 || response.statusCode == 201) {
      final data = jsonDecode(response.body);
      return Cliente.fromJson(data);
    }

    // Algunos backends responden 204 sin body
    if (response.statusCode == 204) {
      // recarga el cliente actualizado desde el backend para refrescar
      return await getClienteById(actualizado.id);
    }

    print("❌ Error updateCliente: ${response.statusCode} - ${response.body}");
    return null;
  }
}
