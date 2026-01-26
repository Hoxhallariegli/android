import 'package:flutter/material.dart';
import '../utils/app_navigator.dart';

enum InAppType { info, success, warning }

class InAppNotification {
  static void show({
    required String title,
    required String message,
    InAppType type = InAppType.info,
    Duration duration = const Duration(seconds: 3),
  }) {
    final overlayState = AppNavigator.navigatorKey.currentState?.overlay;
    if (overlayState == null) return;

    late OverlayEntry entry;

    entry = OverlayEntry(
      builder: (_) => _NotificationWidget(
        title: title,
        message: message,
        type: type,
        onClose: () => entry.remove(),
      ),
    );

    overlayState.insert(entry);

    Future.delayed(duration, () {
      if (entry.mounted) entry.remove();
    });
  }
}

class _NotificationWidget extends StatelessWidget {
  final String title;
  final String message;
  final InAppType type;
  final VoidCallback onClose;

  const _NotificationWidget({
    required this.title,
    required this.message,
    required this.type,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    final config = _style(type);

    return Positioned(
      top: MediaQuery.of(context).padding.top + 12,
      left: 16,
      right: 16,
      child: Material(
        color: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: config.color,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.25),
                blurRadius: 8,
              )
            ],
          ),
          child: Row(
            children: [
              Icon(config.icon, color: Colors.white),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      message,
                      style: const TextStyle(color: Colors.white),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close, color: Colors.white),
                onPressed: onClose,
              )
            ],
          ),
        ),
      ),
    );
  }

  static _Style _style(InAppType type) {
    switch (type) {
      case InAppType.success:
        return _Style(Colors.green, Icons.check_circle);
      case InAppType.warning:
        return _Style(Colors.orange, Icons.warning);
      case InAppType.info:
      default:
        return _Style(Colors.blue, Icons.info);
    }
  }
}

class _Style {
  final Color color;
  final IconData icon;
  _Style(this.color, this.icon);
}
