import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecureStorageService {
  final FlutterSecureStorage _secure = const FlutterSecureStorage();

  static const _kAccessToken = 'accessToken';
  static const _kRefreshToken = 'refreshToken';
  static const _kRole = 'role';

  Future<void> saveTokens(String access, String refresh) async {
    if (kIsWeb) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_kAccessToken, access);
      await prefs.setString(_kRefreshToken, refresh);
    } else {
      await _secure.write(key: _kAccessToken, value: access);
      await _secure.write(key: _kRefreshToken, value: refresh);
    }
  }

  Future<String?> getAccessToken() async {
    if (kIsWeb) {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_kAccessToken);
    }
    return _secure.read(key: _kAccessToken);
  }

  Future<String?> getRefreshToken() async {
    if (kIsWeb) {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_kRefreshToken);
    }
    return _secure.read(key: _kRefreshToken);
  }

  Future<void> saveRole(String role) async {
    final normalized = role.replaceAll('[', '').replaceAll(']', '').trim();

    if (kIsWeb) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_kRole, normalized);
    } else {
      await _secure.write(key: _kRole, value: normalized);
    }
  }

  Future<String?> getRole() async {
    if (kIsWeb) {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_kRole);
    }
    return _secure.read(key: _kRole);
  }

  Future<void> deleteTokens() async {
    if (kIsWeb) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_kAccessToken);
      await prefs.remove(_kRefreshToken);
    } else {
      await _secure.delete(key: _kAccessToken);
      await _secure.delete(key: _kRefreshToken);
    }
  }

  Future<void> deleteRole() async {
    if (kIsWeb) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_kRole);
    } else {
      await _secure.delete(key: _kRole);
    }
  }

  Future<void> clearAll() async {
    deleteRole();
    deleteTokens();
  }
}
