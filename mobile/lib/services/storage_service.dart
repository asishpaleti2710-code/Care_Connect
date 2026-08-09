import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class StorageService {
  final _storage = const FlutterSecureStorage();

  static const String _keyToken = 'careconnect_token';
  static const String _keyUser = 'careconnect_user';
  static const String _keyApiBaseUrl = 'careconnect_api_base_url';
  static const String _keyOnlineMode = 'careconnect_online_mode';

  Future<void> saveToken(String token) async {
    await _storage.write(key: _keyToken, value: token);
  }

  Future<String?> getToken() async {
    return await _storage.read(key: _keyToken);
  }

  Future<void> deleteToken() async {
    await _storage.delete(key: _keyToken);
  }

  Future<void> saveUser(String userJson) async {
    await _storage.write(key: _keyUser, value: userJson);
  }

  Future<String?> getUser() async {
    return await _storage.read(key: _keyUser);
  }

  Future<void> saveApiBaseUrl(String url) async {
    await _storage.write(key: _keyApiBaseUrl, value: url);
  }

  Future<String?> getApiBaseUrl() async {
    return await _storage.read(key: _keyApiBaseUrl);
  }

  Future<void> saveOnlineMode(bool isOnline) async {
    await _storage.write(key: _keyOnlineMode, value: isOnline ? 'true' : 'false');
  }

  Future<bool> getOnlineMode() async {
    final val = await _storage.read(key: _keyOnlineMode);
    return val == null || val == 'true';
  }

  Future<void> clearAll() async {
    await _storage.deleteAll();
  }
}
