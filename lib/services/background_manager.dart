import 'package:flutter_background_service/flutter_background_service.dart';
import 'background_service.dart';

class BackgroundManager {
  static Future<void> start() async {
    final service = FlutterBackgroundService();

    await service.configure(
      androidConfiguration: AndroidConfiguration(
        onStart: onStart,
        isForegroundMode: true,
        autoStart: true,
        foregroundServiceNotificationId: 888,
      ),
      iosConfiguration: IosConfiguration(
        autoStart: false,
        onForeground: (_) {},
        onBackground: (_) => true,
      ),
    );

    await service.startService();
  }

  static Future<void> stop() async {
    final service = FlutterBackgroundService();
    service.invoke('stopService');
  }
}
