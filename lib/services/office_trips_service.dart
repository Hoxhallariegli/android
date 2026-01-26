import '../core/api.dart';

class OfficeTripsService {
  // ================= GET OFFICE TRIPS =================
  static Future<Map<String, List<dynamic>>> getOfficeTrips() async {
    final res = await Api.dio.get('/driver/office-trips');

    return {
      'free': List<Map<String, dynamic>>.from(res.data['free']),
      'my_active': List<Map<String, dynamic>>.from(res.data['my_active']),
    };
  }

  // ================= TAKE TRIP =================
  static Future<void> takeTrip(dynamic id) async {
    await Api.dio.post('/driver/trips/$id/take');
  }

  // ================= UPDATE TRIP =================
  static Future<void> updateTrip(
      dynamic id, {
        required String pickupLocation,
        required String dropoffLocation,
        required int persons,
        required double basePrice,
      }) async {
    await Api.dio.put(
      '/driver/trips/$id',
      data: {
        'pickup_location': pickupLocation,
        'dropoff_location': dropoffLocation,
        'persons': persons,
        'base_price': basePrice,
      },
    );
  }

  // ================= COMPLETE TRIP =================
  static Future<void> completeTrip(dynamic id) async {
    await Api.dio.post('/driver/trips/$id/complete');
  }
}

