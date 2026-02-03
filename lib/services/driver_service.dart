import 'package:dio/dio.dart';
import '../core/api.dart';
import '../core/api_exception.dart';

class DriverService {
  static Future<Map<String, dynamic>> getProfile() async {
    try {
      final res = await Api.dio.get('/driver/profile');
      return Map<String, dynamic>.from(res.data);
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    } catch (e) {
      throw ApiException(message: "Failed to load profile");
    }
  }

  static Future<List<dynamic>> getTrips({String? period}) async {
    try {
      final res = await Api.dio.get(
        '/driver/trips',
        queryParameters: period != null ? {'period': period} : null,
      );
      return List<dynamic>.from(res.data);
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    } catch (e) {
      throw ApiException(message: "Failed to load trips");
    }
  }

  static Future<void> updateTrip(
      int id, {
        required String pickupLocation,
        required String dropoffLocation,
        required int persons,
        required double basePrice,
      }) async {
    try {
      await Api.dio.put(
        '/driver/trips/$id',
        data: {
          'pickup_location': pickupLocation.trim(),
          'dropoff_location': dropoffLocation.trim(),
          'persons': persons,
          'base_price': basePrice,
        },
      );
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    } catch (e) {
      throw ApiException(message: "Failed to update trip");
    }
  }

  static Future<void> deleteTrip(int id) async {
    try {
      await Api.dio.delete('/driver/trips/$id');
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    } catch (e) {
      throw ApiException(message: "Failed to delete trip");
    }
  }
}
