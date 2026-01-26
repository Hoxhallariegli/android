import 'package:flutter/material.dart';
import '../screens/login_screen.dart';

class AppNavigator {
  static final navigatorKey = GlobalKey<NavigatorState>();

  static void logout() {
    navigatorKey.currentState?.pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
          (_) => false,
    );
  }
}
