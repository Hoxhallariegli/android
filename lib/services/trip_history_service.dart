import '../core/api.dart';

class TripHistoryService {
  static Future<List<dynamic>> getTodayTrips() async {
    final res = await Api.dio.get('/driver/trips/today');
    return List<dynamic>.from(res.data);
  }
}
