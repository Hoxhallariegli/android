import '../core/api.dart';

class DriverService {
  static Future<Map<String, dynamic>> getProfile() async {
    final res = await Api.dio.get('/driver/profile');
    return Map<String, dynamic>.from(res.data);
  }

  static Future<List<dynamic>> getTrips({String? period}) async {
    final res = await Api.dio.get(
      '/driver/trips',
      queryParameters: period != null ? {'period': period} : null,
    );
    return List<dynamic>.from(res.data);
  }

  static Future<void> updateTrip(
      int id, {
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


  static Future<void> deleteTrip(int id) async {
    await Api.dio.delete('/driver/trips/$id');
  }
}
