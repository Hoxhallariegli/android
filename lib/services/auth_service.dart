import 'package:dio/dio.dart';
import '../utils/storage.dart';
import '../core/api.dart';
import '../core/api_exception.dart';

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
      if (token == null) {
        throw ApiException(message: "Server returned no token");
      }

      await Storage.saveToken(token);
      Api.dio.options.headers['Authorization'] = 'Bearer $token';

      return true;
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    } catch (e) {
      throw ApiException(message: "An unexpected error occurred during login");
    }
  }

  static Future<void> logout() async {
    try {
      await Api.dio.post('/logout');
    } catch (_) {
      // ignore
    } finally {
      await Storage.clear();
    }
  }
}
