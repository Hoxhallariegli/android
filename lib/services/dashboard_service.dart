import 'package:dio/dio.dart';
import '../core/api.dart';
import '../core/api_exception.dart';

class DashboardService {
  static Future<Map<String, dynamic>> getTodaySummary() async {
    try {
      final res = await Api.dio.get('/driver/today-summary');

      return {
        'tripsCount': res.data['trips_count'] ?? 0,
        'totalAmount': double.tryParse(res.data['total_amount'].toString()) ?? 0.0,
      };
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    } catch (e) {
      throw ApiException(message: "Could not load dashboard summary");
    }
  }
}
