// lib/screens/trip_history_screen.dart
import 'package:flutter/material.dart';
import '../services/trip_history_service.dart';

class TripHistoryScreen extends StatefulWidget {
  const TripHistoryScreen({super.key});

  @override
  State<TripHistoryScreen> createState() => _TripHistoryScreenState();
}

class _TripHistoryScreenState extends State<TripHistoryScreen> {
  List<dynamic> trips = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadTrips();
  }

  Future<void> _loadTrips() async {
    setState(() => isLoading = true);
    try {
      final data = await TripHistoryService.getTodayTrips();
      if (mounted) {
        setState(() => trips = data);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load trips: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Today\'s Trips')),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : trips.isEmpty
          ? const Center(child: Text('No trips today'))
          : ListView.builder(
        itemCount: trips.length,
        itemBuilder: (context, index) {
          final trip = trips[index];

          // Parse persons - handle null and String
          final personsValue = trip['persons'];
          String personsDisplay = 'N/A';
          if (personsValue != null) {
            if (personsValue is int) {
              personsDisplay = personsValue.toString();
            } else if (personsValue is String) {
              personsDisplay = personsValue;
            }
          }

          return Card(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: ListTile(
              title: Text('${trip['pickup_location']} → ${trip['dropoff_location']}'),
              subtitle: Text('Persons: $personsDisplay'),
              trailing: Text('${trip['base_price']} ALL'),
            ),
          );
        },
      ),
    );
  }
}