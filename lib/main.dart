import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
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
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  
  ErrorWidget.builder = (details) => const SizedBox.shrink();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Definimi i Ngjyrës Gold nga Logoja
    const goldColor = Color(0xFFD4AF37);

    return MaterialApp(
      navigatorKey: AppNavigator.navigatorKey,
      debugShowCheckedModeBanner: false,
      title: 'Class Tours Driver',
      theme: ThemeData(
        useMaterial3: true,
        primaryColor: goldColor,
        colorScheme: ColorScheme.fromSeed(
          seedColor: goldColor,
          primary: goldColor,
          secondary: Colors.black,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.black,
          foregroundColor: goldColor,
          elevation: 0,
          centerTitle: true,
          titleTextStyle: TextStyle(
            color: goldColor,
            fontSize: 20,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.2,
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: goldColor,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            padding: const EdgeInsets.symmetric(vertical: 15),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: goldColor, width: 2),
          ),
        ),
      ),
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
    PushService.init();
  }

  @override
  Widget build(BuildContext context) {
    const goldColor = Color(0xFFD4AF37);

    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset('assets/images/taxy.png', height: 30), // Logoja e vogël në AppBar

            const SizedBox(width: 10),
            ValueListenableBuilder<ServerStatus>(
              valueListenable: ServerStatusService.status,
              builder: (_, status, __) {
                return Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: status == ServerStatus.online ? Colors.green : Colors.red,
                    boxShadow: [
                      BoxShadow(
                        color: (status == ServerStatus.online ? Colors.green : Colors.red).withOpacity(0.5),
                        blurRadius: 4,
                        spreadRadius: 2,
                      )
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      ),
      body: _pages[_currentIndex],
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10)],
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (i) => setState(() => _currentIndex = i),
          selectedItemColor: goldColor,
          unselectedItemColor: Colors.grey,
          showUnselectedLabels: true,
          type: BottomNavigationBarType.fixed,
          backgroundColor: Colors.white,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.business_center_outlined),
              activeIcon: Icon(Icons.business_center),
              label: 'Office',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.local_taxi_outlined),
              activeIcon: Icon(Icons.local_taxi),
              label: 'Trips',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person_outline),
              activeIcon: Icon(Icons.person),
              label: 'Profile',
            ),
          ],
        ),
      ),
    );
  }
}
