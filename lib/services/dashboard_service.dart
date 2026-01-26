import '../core/api.dart';

class DashboardService {
  static Future<Map<String, dynamic>> getTodaySummary() async {
    final res = await Api.dio.get('/driver/today-summary');

    return {
      'tripsCount': res.data['trips_count'] ?? 0,
      'totalAmount':
      double.tryParse(res.data['total_amount'].toString()) ?? 0.0,
    };
  }
}
