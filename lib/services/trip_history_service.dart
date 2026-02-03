import 'package:dio/dio.dart';
import '../core/api.dart';
import '../core/api_exception.dart';

class TripHistoryService {
  static Future<List<dynamic>> getTodayTrips() async {
    try {
      final res = await Api.dio.get('/driver/trips/today');
      return List<dynamic>.from(res.data);
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    } catch (e) {
      throw ApiException(message: "Failed to load today's trips");
    }
  }
}
