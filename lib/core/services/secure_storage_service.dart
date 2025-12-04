import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecureStorageService {
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  // ============================================================
  // TOKENS
  // ============================================================

  static const String _keyAccessToken = 'access_token';
  static const String _keyRefreshToken = 'refresh_token';

  Future<void> saveTokens(String accessToken, String refreshToken) async {
    await _storage.write(key: _keyAccessToken, value: accessToken);
    await _storage.write(key: _keyRefreshToken, value: refreshToken);
  }

  Future<String?> getAccessToken() async {
    return await _storage.read(key: _keyAccessToken);
  }

  Future<String?> getRefreshToken() async {
    return await _storage.read(key: _keyRefreshToken);
  }

  Future<void> clearTokens() async {
    await _storage.deleteAll();
  }

  // ============================================================
  // CONFIGURACIÓN DE PEDIDOS (DESCUENTO / IVA)
  // ============================================================

  static const String _keyDefaultDescuento = "default_descuento";
  static const String _keyDefaultIVA = "default_iva";

  /// Guarda descuento e IVA (0–100)
  Future<void> savePedidoDefaults({
    required double descuento,
    required double iva,
  }) async {
    await _storage.write(
      key: _keyDefaultDescuento,
      value: descuento.toString(),
    );
    await _storage.write(key: _keyDefaultIVA, value: iva.toString());
  }

  /// Obtiene los valores guardados.
  /// Si no existe nada devuelve: descuento=0, iva=21
  Future<Map<String, double>> getPedidoDefaults() async {
    final d = await _storage.read(key: _keyDefaultDescuento);
    final i = await _storage.read(key: _keyDefaultIVA);

    return {
      "descuento": double.tryParse(d ?? "0") ?? 0,
      "iva": double.tryParse(i ?? "21") ?? 21,
    };
  }
}
