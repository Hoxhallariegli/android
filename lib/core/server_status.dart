import 'package:flutter/foundation.dart';

enum ServerStatus {
  online,
  offline,
}

class ServerStatusService {
  static final ValueNotifier<ServerStatus> status =
  ValueNotifier(ServerStatus.online);

  static void setOffline() {
    if (status.value != ServerStatus.offline) {
      status.value = ServerStatus.offline;
    }
  }

  static void setOnline() {
    if (status.value != ServerStatus.online) {
      status.value = ServerStatus.online;
    }
  }
}
