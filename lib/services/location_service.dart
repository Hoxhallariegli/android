// import 'package:geolocator/geolocator.dart';
// import 'background_api.dart';
//
// class LocationService {
//   static Future<void> sendCurrentLocation() async {
//     // try {
//     //   // GPS ON?
//     //   final enabled = await Geolocator.isLocationServiceEnabled();
//     //   if (!enabled) {
//     //     print('[BG] GPS disabled – skip');
//     //     return;
//     //   }
//     //
//     //   // Permission ekziston?
//     //   final permission = await Geolocator.checkPermission();
//     //   if (permission == LocationPermission.denied ||
//     //       permission == LocationPermission.deniedForever) {
//     //     print('[BG] Permission missing – skip');
//     //     return;
//     //   }
//     //
//     //   // SAFE për background
//     //   final Position? position =
//     //   await Geolocator.getLastKnownPosition();
//     //
//     //   if (position == null) {
//     //     print('[BG] No last known position – skip');
//     //     return;
//     //   }
//     //
//     //   final dio = await BackgroundApi.create();
//     //
//     //   await dio.post(
//     //     '/driver/location',
//     //     data: {
//     //       'lat': position.latitude,
//     //       'lng': position.longitude,
//     //       'speed': position.speed,
//     //     },
//     //   );
//     //
//     //   print('[BG] Location sent');
//     // } catch (e, stack) {
//     //   // ⛔ KURRË crash
//     //   print('[BG] SAFE ERROR: $e');
//     //   print(stack);
//     // }
//   }
// }
class LocationService {
  static Future<void> sendCurrentLocation() async {
    return;
  }
}
