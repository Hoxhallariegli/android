import 'package:flutter/material.dart';
import '../services/dashboard_service.dart';
import 'add_trip_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int tripsToday = 0;
  double totalAmount = 0.0;
  bool isLoading = true;

  final Color goldColor = const Color(0xFFD4AF37);

  @override
  void initState() {
    super.initState();
    _loadSummary();
  }

  Future<void> _loadSummary() async {
    setState(() => isLoading = true);
    try {
      final data = await DashboardService.getTodaySummary();
      if (mounted) {
        setState(() {
          tripsToday = data['tripsCount'];
          totalAmount = data['totalAmount'];
        });
      }
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: Column(
        children: [
          // PREMIUM GRADIENT HEADER
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(20, 40, 20, 30),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF1A1A1A), Color(0xFF333333)],
              ),
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(30),
                bottomRight: Radius.circular(30),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Këtu është përmbledhja juaj për sot.',
                  style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 14),
                ),
              ],
            ),
          ),

          const SizedBox(height: 25),

          // ADD NEW TRIP BUTTON
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: ElevatedButton.icon(
              icon: const Icon(Icons.add_circle_outline, color: Colors.black),
              label: const Text(
                'SHTO UDHËTIM TË RI',
                style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, letterSpacing: 1.1),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: goldColor,
                minimumSize: const Size(double.infinity, 55),
                elevation: 4,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
              ),
              onPressed: () async {
                final added = await Navigator.push<bool>(
                  context,
                  MaterialPageRoute(builder: (_) => const AddTripScreen()),
                );
                if (added == true) _loadSummary();
              },
            ),
          ),

          const SizedBox(height: 25),

          // STATS CARDS
          Expanded(
            child: isLoading
                ? const Center(child: CircularProgressIndicator())
                : ListView(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    children: [
                      _buildStatCard(
                        'Udhëtime Sot',
                        tripsToday.toString(),
                        Icons.directions_car_filled_outlined,
                        goldColor,
                      ),
                      const SizedBox(height: 15),
                      _buildStatCard(
                        'Shuma Total',
                        '${totalAmount.toStringAsFixed(2)} ALL',
                        Icons.account_balance_wallet_outlined,
                        Colors.green.shade600,
                      ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color accentColor) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 5)),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: accentColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(15),
            ),
            child: Icon(icon, color: accentColor, size: 30),
          ),
          const SizedBox(width: 20),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(color: Colors.grey, fontSize: 14)),
              const SizedBox(height: 5),
              Text(
                value,
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF1A1A1A)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
