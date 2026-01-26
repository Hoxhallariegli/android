import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import '../core/api.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'local_notification_service.dart';
import '../widgets/in_app_notification.dart';
import '../utils/app_navigator.dart';



class PushService {
  static final _fcm = FirebaseMessaging.instance;

  static Future<void> init() async {
    // Android 13+
    await _fcm.requestPermission();

    // Register token
    final token = await _fcm.getToken();
    if (token != null) {
      await _registerToken(token);
    }

    FirebaseMessaging.instance.onTokenRefresh.listen(_registerToken);

    // APP OPEN (FOREGROUND)
    FirebaseMessaging.onMessage.listen(_handleForeground);

    // APP BACKGROUND / CLOSED (TAP)
    FirebaseMessaging.onMessageOpenedApp.listen(_handleClick);
  }
  static Future<String> _getDeviceId() async {
    final info = DeviceInfoPlugin();
    final android = await info.androidInfo;
    return android.id; // ANDROID_ID
  }

  static Future<void> _registerToken(String token) async {
    try {
      final deviceId = await _getDeviceId();

      await Api.dio.post('/device/register', data: {
        'device_id': deviceId,
        'platform': 'android',
        'fcm_token': token,
      });

      debugPrint('[FCM] Device registered');
    } catch (e) {
      debugPrint('[FCM][REGISTER ERROR] $e');
    }
  }
  static void _handleForeground(RemoteMessage message) {
    final type = message.data['type'];

    final title = message.notification?.title ?? 'Notification';
    final body = message.notification?.body ?? '';

    // 1️⃣ ANDROID SYSTEM NOTIFICATION (LOCAL)
    LocalNotificationService.show(
      title: title,
      body: body,
    );

    // 2️⃣ IN-APP SWEETALERT (OVERLAY)
    InAppNotification.show(
      title: title,
      message: body,
      type: type == 'success'
          ? InAppType.success
          : type == 'warning'
          ? InAppType.warning
          : InAppType.info,
    );
  }

  static void _handleClick(RemoteMessage message) {
    final type = message.data['type'];

    debugPrint('[PUSH][CLICK][$type]');

    // Navigation do shtohet më vonë
  }


}
