import 'package:dio/dio.dart';
import '../core/api.dart';
import '../core/api_exception.dart';

class TripService {
  static Future<void> createTrip({
    required String from,
    required String to,
    required String type,
    required int price,
    required int persons,
  }) async {
    try {
      await Api.dio.post(
        '/driver/trips',
        data: {
          'type': type,
          'pickup_location': from,
          'dropoff_location': to,
          'base_price': price,
          'persons': persons,
        },
      );
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    } catch (e) {
      throw ApiException(message: "An unexpected error occurred");
    }
  }
}
