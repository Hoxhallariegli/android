import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class Storage {
  static const _storage = FlutterSecureStorage();

  static Future<void> saveToken(String token) async {
    await _storage.write(key: 'api_token', value: token);
  }

  static Future<String?> getToken() async {
    return await _storage.read(key: 'api_token');
  }

  static Future<void> clear() async {
    await _storage.delete(key: 'api_token');
  }
}
