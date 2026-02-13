import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class Storage {
  static const _storage = FlutterSecureStorage();

  static Future<void> saveToken(String token) async {
    await _storage.write(key: 'api_token', value: token);
  }

  static Future<String?> getToken() async {
    return await _storage.read(key: 'api_token');
  }

  static Future<void> saveRoles(List<dynamic> roles) async {
    await _storage.write(key: 'user_roles', value: jsonEncode(roles));
  }

  static Future<List<String>> getRoles() async {
    final rolesStr = await _storage.read(key: 'user_roles');
    if (rolesStr == null) return [];
    return List<String>.from(jsonDecode(rolesStr));
  }

  // Remember Me Methods
  static Future<void> saveCredentials(String email, String password) async {
    await _storage.write(key: 'remember_email', value: email);
    await _storage.write(key: 'remember_password', value: password);
    await _storage.write(key: 'remember_me', value: 'true');
  }

  static Future<void> clearSavedCredentials() async {
    await _storage.delete(key: 'remember_email');
    await _storage.delete(key: 'remember_password');
    await _storage.write(key: 'remember_me', value: 'false');
  }

  static Future<Map<String, String?>> getSavedCredentials() async {
    final email = await _storage.read(key: 'remember_email');
    final password = await _storage.read(key: 'remember_password');
    final isRemembered = await _storage.read(key: 'remember_me');
    return {
      'email': email,
      'password': password,
      'isRemembered': isRemembered,
    };
  }

  static Future<void> clear() async {
    await _storage.delete(key: 'api_token');
    await _storage.delete(key: 'user_roles');
  }
}
