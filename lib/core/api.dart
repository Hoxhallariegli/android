import 'dart:io';
import 'package:dio/dio.dart';
import '../utils/storage.dart';
import '../utils/app_navigator.dart';
import 'server_status.dart';

class Api {
  static final Dio dio = Dio(
    BaseOptions(
       baseUrl: 'https://m.classtours.al/api',
      // baseUrl: 'http://10.10.12.14:80/api',
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 15),
      headers: {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
      },
    ),
  )..interceptors.add(
    InterceptorsWrapper(
      onRequest: (options, handler) async {
        final token = await Storage.getToken();
        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        handler.next(options);
      },
      onResponse: (response, handler) {
        ServerStatusService.setOnline();
        handler.next(response);
      },
      onError: (e, handler) async {
        // Server Down Detection
        if (e.type == DioExceptionType.connectionError ||
            e.type == DioExceptionType.unknown ||
            e.error is HandshakeException ||
            e.error is SocketException) {
          ServerStatusService.setOffline();
        }

        // Auth Error
        if (e.response?.statusCode == 401) {
          await Storage.clear();
          AppNavigator.logout();
        }

        handler.next(e);
      },
    ),
  );
}
