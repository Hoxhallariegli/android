import 'package:dio/dio.dart';
import '../utils/storage.dart';

class BackgroundApi {
  static Future<Dio> create() async {
    final token = await Storage.getToken();

    return Dio(
        BaseOptions(
          // baseUrl: 'http://10.10.12.14:80/api',
          baseUrl: 'https://m.classtours.al/api',
          connectTimeout: const Duration(seconds: 15),
          receiveTimeout: const Duration(seconds: 15),
          headers: {
            'Accept': 'application/json',
            'Connection': 'close',
          },
        );

    );
  }
}
