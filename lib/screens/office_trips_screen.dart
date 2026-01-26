import 'package:flutter/material.dart';
import '../services/office_trips_service.dart';
import 'package:intl/intl.dart';

class OfficeTripsScreen extends StatefulWidget {
  const OfficeTripsScreen({super.key});

  @override
  State<OfficeTripsScreen> createState() => _OfficeTripsScreenState();
}

class _OfficeTripsScreenState extends State<OfficeTripsScreen> {
  bool loading = true;

  List<dynamic> freeTrips = [];
  List<dynamic> myActiveTrips = [];

  @override
  void initState() {
    super.initState();
    _loadTrips();
  }

  Future<void> _loadTrips() async {
    try {
      setState(() => loading = true);
      final data = await OfficeTripsService.getOfficeTrips();
      if (!mounted) return;

      setState(() {
        freeTrips = data['free'] ?? [];
        myActiveTrips = data['my_active'] ?? [];
        loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => loading = false);
      _error(e);
    }
  }

  // ================= ACTIONS =================

  Future<void> _takeTrip(dynamic trip) async {
    try {
      await OfficeTripsService.takeTrip(trip['id']);
      await _loadTrips();
    } catch (e) {
      _error(e);
    }
  }

  Future<void> _completeTrip(dynamic trip) async {
    try {
      await OfficeTripsService.completeTrip(trip['id']);
      Navigator.pop(context);
      await _loadTrips();
    } catch (e) {
      _error(e);
    }
  }

  void _openTripModal(dynamic trip) {
    final pickup = TextEditingController(text: trip['pickup_location']);
    final dropoff = TextEditingController(text: trip['dropoff_location']);
    final persons = TextEditingController(text: trip['persons'].toString());
    final price = TextEditingController(text: trip['base_price'].toString());

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Trip Details',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),

                _field('Pickup', pickup),
                _field('Dropoff', dropoff),
                _field('Persons', persons, isNumber: true),
                _field('Base Price', price, isNumber: true),

                const SizedBox(height: 24),

                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Cancel'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () async {
                          try {
                            await OfficeTripsService.updateTrip(
                              trip['id'],
                              pickupLocation: pickup.text,
                              dropoffLocation: dropoff.text,
                              persons: int.parse(persons.text),
                              basePrice: double.parse(price.text),
                            );
                            Navigator.pop(context);
                            await _loadTrips();
                          } catch (e) {
                            _error(e);
                          }
                        },
                        child: const Text('Update'),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                    ),
                    onPressed: () => _completeTrip(trip),
                    child: const Text('COMPLETE'),
                  ),
                ),

                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ================= UI =================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Office Trips')),
      body: RefreshIndicator(
        onRefresh: _loadTrips,
        child: loading
            ? const Center(child: CircularProgressIndicator())
            : ListView(
          padding: const EdgeInsets.all(16),
          children: [

            // MY ACTIVE
            if (myActiveTrips.isNotEmpty) ...[
              const Text(
                'My Active Trips',
                style:
                TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              ...myActiveTrips.map((trip) => Card(
                color: Colors.green.shade50,
                child: ListTile(
                  title: Text(
                    '${trip['pickup_location']} → ${trip['dropoff_location']}',
                  ),
                  subtitle: Text(
                    'Persons: ${trip['persons']} | ${trip['base_price']} ALL\n'
                        '${_formatDate(trip['created_at'])}',
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => _openTripModal(trip),
                ),
              )),
              const SizedBox(height: 32),
            ],

            // FREE
            const Text(
              'Free Trips',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),

            if (freeTrips.isEmpty)
              const Text('No free trips')
            else
              ...freeTrips.map((trip) => Card(
                child: ListTile(
                  title: Text(
                    '${trip['pickup_location']} → ${trip['dropoff_location']}',
                  ),
                  subtitle: Text(
                    'Persons: ${trip['persons']} | ${trip['base_price']} ALL\n'
                        '${_formatDate(trip['created_at'])}',
                  ),
                  trailing: ElevatedButton(
                    onPressed: () => _takeTrip(trip),
                    child: const Text('TAKE'),
                  ),
                ),
              )),
          ],
        ),
      ),
    );
  }

  // ================= HELPERS =================

  Widget _field(String label, TextEditingController c,
      {bool isNumber = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(
        controller: c,
        keyboardType: isNumber ? TextInputType.number : TextInputType.text,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
        ),
      ),
    );
  }

  static String _formatDate(String date) {
    try {
      return DateFormat('HH:mm | dd/MM/yy')
          .format(DateTime.parse(date));
    } catch (_) {
      return '';
    }
  }

  void _error(dynamic e) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(e.toString()),
        backgroundColor: Colors.red,
      ),
    );
  }
}
