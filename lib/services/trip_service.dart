import '../core/api.dart';

class TripService {
  static Future<bool> createTrip({
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
      return true;
    } catch (_) {
      return false;
    }
  }
}
