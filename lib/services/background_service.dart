import 'dart:async';
import 'package:flutter/widgets.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'location_service.dart';

@pragma('vm:entry-point')
void onStart(ServiceInstance service) async {
  WidgetsFlutterBinding.ensureInitialized();

  // Handle service stop
  service.on('stopService').listen((event) {
    service.stopSelf();
  });

  // Location update loop
  Timer.periodic(const Duration(seconds: 30), (timer) async {
    try {
      await LocationService.sendCurrentLocation();
    } catch (e) {
      debugPrint('[BG][ERROR] Location update failed: $e');
    }
  });
}
