import 'dart:async';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import '../core/api.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'local_notification_service.dart';
import '../widgets/in_app_notification.dart';

// Kjo duhet të jetë jashtë klasës për Background Messaging
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  debugPrint('[FCM][BACKGROUND] Mesazh i marrë në background: ${message.data}');
}

class PushService {
  static final _fcm = FirebaseMessaging.instance;
  
  static final StreamController<String> _refreshStream = StreamController<String>.broadcast();
  static Stream<String> get refreshStream => _refreshStream.stream;

  static Future<void> init() async {
    try {
      // 1. Regjistro Background Handler
      FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

      // 2. Setup Listeners MENJËHERË
      FirebaseMessaging.onMessage.listen(_handleGlobalNotification);
      FirebaseMessaging.onMessageOpenedApp.listen(_handleNotificationClick);

      // 3. Kërko Permission
      NotificationSettings settings = await _fcm.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );
      debugPrint('[FCM] Statusi i lejes: ${settings.authorizationStatus}');

      // 4. Topic Subscription
      await _fcm.subscribeToTopic('drivers');
      debugPrint('[FCM] Subscribed to topic: drivers');

      // 5. Token Management
      final token = await _fcm.getToken();
      if (token != null) await _registerToken(token);

      FirebaseMessaging.instance.onTokenRefresh.listen(_registerToken);

    } catch (e) {
      debugPrint('[FCM][INIT ERROR] $e');
    }
  }

  static void _handleGlobalNotification(RemoteMessage message) {
    final data = message.data;
    final notification = message.notification;

    debugPrint('[FCM][RECEIVED] Data: ${data.toString()}');

    if (data['action'] == 'refresh_trips') {
      debugPrint('[FCM][ACTION] Duke bërë refresh listën e udhëtimeve...');
      _refreshStream.add('trips');
    }

    if (notification != null) {
      debugPrint('[FCM][UI] Shfaqje njoftimi: ${notification.title}');
      LocalNotificationService.show(
        title: notification.title ?? 'Njoftim',
        body: notification.body ?? '',
      );

      InAppNotification.show(
        title: notification.title ?? 'Njoftim',
        message: notification.body ?? '',
        type: data['type'] == 'success' ? InAppType.success : InAppType.info,
      );
    }
  }

  static Future<void> _registerToken(String token) async {
    try {
      final info = DeviceInfoPlugin();
      final android = await info.androidInfo;
      
      await Api.dio.post('/device/register', data: {
        'device_id': android.id,
        'platform': 'android',
        'fcm_token': token,
      });
      debugPrint('[FCM] Token u regjistrua në server');
    } catch (e) {
      debugPrint('[FCM][REG ERROR] $e');
    }
  }

  static void _handleNotificationClick(RemoteMessage message) {
    debugPrint('[FCM][CLICK] Përdoruesi klikoi njoftimin: ${message.data}');
  }
}
