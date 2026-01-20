import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecureStorageService {
  // Si ya lo tienes así, perfecto:
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  // Keys (usa las tuyas si ya existen)
  static const String _kAccessToken = 'accessToken';
  static const String _kRefreshToken = 'refreshToken';
  static const String _kRole = 'role';

  // ============================================================
  // TOKENS
  // ============================================================
  Future<void> saveTokens(String accessToken, String refreshToken) async {
    await _storage.write(key: _kAccessToken, value: accessToken);
    await _storage.write(key: _kRefreshToken, value: refreshToken);
  }

  Future<String?> getAccessToken() async {
    return _storage.read(key: _kAccessToken);
  }

  Future<String?> getRefreshToken() async {
    return _storage.read(key: _kRefreshToken);
  }

  Future<void> deleteTokens() async {
    await _storage.delete(key: _kAccessToken);
    await _storage.delete(key: _kRefreshToken);
  }

  // ============================================================
  // ROLE
  // ============================================================
  Future<void> saveRole(String role) async {
    // Normaliza por si llega "[ADMIN]"
    final normalized = role.replaceAll('[', '').replaceAll(']', '').trim();
    await _storage.write(key: _kRole, value: normalized);
  }

  Future<String?> getRole() async {
    return _storage.read(key: _kRole);
  }

  Future<void> deleteRole() async {
    await _storage.delete(key: _kRole);
  }

  // ============================================================
  // CLEAR (logout completo)
  // ============================================================
  Future<void> clearAll() async {
    await deleteTokens();
    await deleteRole();
  }
}
