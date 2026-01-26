import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart'; // Kjo skedë duhet të gjenerohet
import 'services/local_notification_service.dart';
import 'screens/dashboard_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/office_trips_screen.dart';
import 'utils/app_navigator.dart';
import 'services/push_service.dart';
import '../core/server_status.dart';


void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await LocalNotificationService.init();
  // Inicializo Firebase para se të nisim aplikacionin
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  ErrorWidget.builder = (FlutterErrorDetails details) {
    return const SizedBox.shrink();
  };
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: AppNavigator.navigatorKey,
      debugShowCheckedModeBanner: false,
      home: const MainHome(),
    );
  }
}

class MainHome extends StatefulWidget {
  const MainHome({super.key});

  @override
  State<MainHome> createState() => _MainHomeState();
}

class _MainHomeState extends State<MainHome> {
  int _currentIndex = 1;

  final _pages = const [
    OfficeTripsScreen(),
    DashboardScreen(),
    ProfileScreen(),
  ];

  @override
  void initState() {
    super.initState();

    // 🔥 INIT PUSH + IN-APP NOTIFICATIONS (GLOBAL)
    PushService.init();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Paneli Shoferit'),
            const SizedBox(width: 8),

            // 🔴🟢 SERVER STATUS DOT
            ValueListenableBuilder<ServerStatus>(
              valueListenable: ServerStatusService.status,
              builder: (_, status, __) {
                return Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: status == ServerStatus.online
                        ? Colors.green
                        : Colors.red,
                  ),
                );
              },
            ),
          ],
        ),
      ),

      body: _pages[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (i) => setState(() => _currentIndex = i),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.business),
            label: 'Office',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.directions_car),
            label: 'Trips',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}
