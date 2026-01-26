import 'package:dio/dio.dart';
import '../utils/storage.dart';
import '../core/api.dart';

class AuthService {
  static Future<bool> login(String email, String password) async {
    try {
      final Response res = await Api.dio.post(
        '/login',
        data: {
          'email': email,
          'password': password,
          'device_id': 'flutter-device',
        },
      );

      final token = res.data['token'];
      if (token == null) return false;

      await Storage.saveToken(token);

      Api.dio.options.headers['Authorization'] = 'Bearer $token';

      return true;
    } catch (e) {
      if (e is DioException && e.response != null) {
        print('❌ Login failed: ${e.response?.data}');
      } else {
        print('❌ Login error: $e');
      }
      return false;
    }
  }


  static Future<void> logout() async {
    try {
      await Api.dio.post('/logout');
    } catch (_) {
      // ignore
    }

    await Storage.clear();
  }
}
