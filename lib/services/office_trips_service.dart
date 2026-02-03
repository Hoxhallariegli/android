import '../core/api.dart';
import '../core/api_exception.dart';
import 'package:dio/dio.dart';

class OfficeTripsService {
  // ================= GET OFFICE TRIPS =================
  static Future<Map<String, List<dynamic>>> getOfficeTrips() async {
    try {
      final res = await Api.dio.get('/driver/office-trips');

      return {
        'free': List<Map<String, dynamic>>.from(res.data['free'] ?? []),
        'my_active': List<Map<String, dynamic>>.from(res.data['my_active'] ?? []),
      };
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    } catch (e) {
      throw ApiException(message: "Failed to load office trips");
    }
  }

  // ================= TAKE TRIP =================
  static Future<Map<String, dynamic>> takeTrip(dynamic id) async {
    try {
      final res = await Api.dio.post('/driver/trips/$id/take');

      return Map<String, dynamic>.from(res.data ?? {});
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    } catch (e) {
      throw ApiException(message: "Trip cannot be taken");
    }
  }

  // ================= UPDATE TRIP =================
  static Future<Map<String, dynamic>> updateTrip(
      dynamic id, {
        required String pickupLocation,
        required String dropoffLocation,
        required int persons,
        required double basePrice,
      }) async {
    try {
      final res = await Api.dio.put(
        '/driver/trips/$id',
        data: {
          'pickup_location': pickupLocation.trim(),
          'dropoff_location': dropoffLocation.trim(),
          'persons': persons,
          'base_price': basePrice,
        },
      );

      return Map<String, dynamic>.from(res.data ?? {});
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    } catch (e) {
      throw ApiException(message: "Trip update failed");
    }
  }

  // ================= COMPLETE TRIP =================
  static Future<Map<String, dynamic>> completeTrip(dynamic id) async {
    try {
      final res = await Api.dio.post('/driver/trips/$id/complete');

      return Map<String, dynamic>.from(res.data ?? {});
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    } catch (e) {
      throw ApiException(message: "Trip cannot be completed");
    }
  }
}
