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
    return SafeArea(
      child: Column(
        children: [
          // HEADER IMAGE SI FOTOJA
          Container(
            height: 180,
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Image.asset(
                  'assets/images/taxy.png',
                  height: 70,
                  fit: BoxFit.contain,
                ),
                const SizedBox(height: 12),
                const Text(
                  'My Trips',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),


          const SizedBox(height: 12),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: ElevatedButton.icon(
              icon: const Icon(Icons.add),
              label: const Text('Add New Trip'),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 48),
              ),
              onPressed: () async {
                final added = await Navigator.push<bool>(
                  context,
                  MaterialPageRoute(builder: (_) => const AddTripScreen()),
                );

                if (added == true) {
                  _loadSummary(); // 🔥 RIFRESKIM REAL
                }
              },

            ),
          ),

          const SizedBox(height: 16),

          Expanded(
            child: isLoading
                ? const Center(child: CircularProgressIndicator())
                : ListView(
              children: [
                _statCard('Trips Today', tripsToday.toString()),
                _statCard(
                  'Total Amount',
                  '${totalAmount.toStringAsFixed(2)} ALL',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _statCard(String title, String value) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: ListTile(
        title: Text(title),
        trailing: Text(
          value,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}
