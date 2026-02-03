import 'package:dio/dio.dart';

class ApiException implements Exception {
  final String message;
  final int? statusCode;
  final dynamic errors;

  ApiException({required this.message, this.statusCode, this.errors});

  factory ApiException.fromDioError(DioException error) {
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return ApiException(message: "Connection timed out. Please try again.");
      case DioExceptionType.badResponse:
        final data = error.response?.data;
        String message = "Something went wrong";
        dynamic errors;
        
        if (data is Map) {
          message = data['message'] ?? message;
          errors = data['errors'];
        }
        
        return ApiException(
          message: message,
          statusCode: error.response?.statusCode,
          errors: errors,
        );
      case DioExceptionType.cancel:
        return ApiException(message: "Request cancelled");
      case DioExceptionType.connectionError:
        return ApiException(message: "No internet connection or server unreachable");
      default:
        return ApiException(message: "An unexpected error occurred");
    }
  }

  @override
  String toString() => message;
}
