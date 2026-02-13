import 'package:dio/dio.dart';
import 'package:device_info_plus/device_info_plus.dart';
import '../utils/storage.dart';
import '../core/api.dart';
import '../core/api_exception.dart';

class AuthService {
  static Future<bool> login(String email, String password) async {
    try {
      final info = DeviceInfoPlugin();
      String deviceId = 'unknown_device';
      
      try {
        final android = await info.androidInfo;
        deviceId = android.id; // Sigurohemi që nuk është null
      } catch (e) {
        // Fallback nëse dështon leximi i device info
      }

      final Response res = await Api.dio.post(
        '/login',
        data: {
          'email': email,
          'password': password,
          'device_id': deviceId,
        },
      );

      final data = res.data;
      if (data == null) throw ApiException(message: "Serveri nuk ktheu përgjigje");

      final token = data['token'];
      if (token == null) {
        throw ApiException(message: "Serveri nuk ktheu asnjë token");
      }

      // Sigurohemi që 'user' dhe 'roles' nuk janë null
      final user = data['user'] ?? {};
      final roles = user['roles'] as List<dynamic>? ?? [];

      await Storage.saveToken(token.toString());
      await Storage.saveRoles(roles);
      
      Api.dio.options.headers['Authorization'] = 'Bearer $token';

      return true;
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    } catch (e) {
      // Ky bllok kap gabimet e tipit 'Null' subtype
      throw ApiException(message: "Gabim në përpunimin e të dhënave: ${e.toString()}");
    }
  }

  static Future<void> logout() async {
    try {
      await Api.dio.post('/logout');
    } catch (_) {
    } finally {
      await Storage.clear();
    }
  }
}
