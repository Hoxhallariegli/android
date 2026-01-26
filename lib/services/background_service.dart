import 'dart:async';
import 'package:flutter/widgets.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'location_service.dart';

@pragma('vm:entry-point')
void onStart(ServiceInstance service) async {
  WidgetsFlutterBinding.ensureInitialized();

  print('[BG] Background service STARTED');

  Timer.periodic(const Duration(seconds: 30), (_) async {
    print('[BG] Tick - sending location');
    await LocationService.sendCurrentLocation();
  });
}
