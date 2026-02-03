import 'dart:async';
import 'package:flutter/material.dart';
import '../services/office_trips_service.dart';
import 'package:intl/intl.dart';
import '../core/api_exception.dart';
import '../utils/ui_utils.dart';
import '../services/push_service.dart';

class OfficeTripsScreen extends StatefulWidget {
  const OfficeTripsScreen({super.key});

  @override
  State<OfficeTripsScreen> createState() => _OfficeTripsScreenState();
}

class _OfficeTripsScreenState extends State<OfficeTripsScreen> {
  bool loading = true;
  bool actionLoading = false;

  List<dynamic> freeTrips = [];
  List<dynamic> myActiveTrips = [];
  
  StreamSubscription? _refreshSub;

  @override
  void initState() {
    super.initState();
    _loadTrips();

    _refreshSub = PushService.refreshStream.listen((event) {
      if (event == 'trips' && mounted) {
        debugPrint('[REAL-TIME] Office screen refreshing data...');
        _loadTrips();
      }
    });
  }

  @override
  void dispose() {
    _refreshSub?.cancel();
    super.dispose();
  }

  Future<void> _loadTrips() async {
    try {
      if (mounted) setState(() => loading = true);
      final data = await OfficeTripsService.getOfficeTrips();
      if (mounted) {
        setState(() {
          freeTrips = data['free'] ?? [];
          myActiveTrips = data['my_active'] ?? [];
          loading = false;
        });
      }
    } on ApiException catch (e) {
      if (mounted) {
        setState(() => loading = false);
        UiUtils.showError(context, e.message);
      }
    } catch (e) {
      if (mounted) {
        setState(() => loading = false);
        UiUtils.showError(context, "Failed to load office trips");
      }
    }
  }

  // ================= ACTIONS =================

  Future<void> _takeTrip(dynamic trip) async {
    try {
      setState(() => actionLoading = true);
      await OfficeTripsService.takeTrip(trip['id']);
      if (mounted) UiUtils.showSuccess(context, "Trip assigned to you");
      await _loadTrips();
    } on ApiException catch (e) {
      if (mounted) {
        UiUtils.showError(context, e.message);
        // 🔥 REFRESH IF TRIP WAS ALREADY TAKEN (422)
        if (e.statusCode == 422) {
          debugPrint('[SYNC] Trip unavailable, refreshing list...');
          await _loadTrips();
        }
      }
    } finally {
      if (mounted) setState(() => actionLoading = false);
    }
  }

  Future<void> _completeTrip(dynamic trip) async {
    try {
      setState(() => actionLoading = true);
      await OfficeTripsService.completeTrip(trip['id']);
      if (mounted) {
        Navigator.pop(context); // Close modal
        UiUtils.showSuccess(context, "Trip completed successfully");
      }
      await _loadTrips();
    } on ApiException catch (e) {
      if (mounted) UiUtils.showError(context, e.message);
    } finally {
      if (mounted) setState(() => actionLoading = false);
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
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (modalContext) => StatefulBuilder(
        builder: (context, setModalState) => Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: Container(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.85,
            ),
            child: SafeArea(
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 10, 20, 35),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 40,
                        height: 5,
                        margin: const EdgeInsets.only(bottom: 20),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade300,
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      const Text(
                        'Edit Trip Details',
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 20),

                      _field('Pickup Location', pickup, icon: Icons.location_on),
                      _field('Dropoff Location', dropoff, icon: Icons.flag),
                      Row(
                        children: [
                          Expanded(child: _field('Persons', persons, isNumber: true, icon: Icons.people)),
                          const SizedBox(width: 12),
                          Expanded(child: _field('Price (ALL)', price, isNumber: true, icon: Icons.money)),
                        ],
                      ),

                      const SizedBox(height: 24),

                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 15),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              ),
                              onPressed: () => Navigator.pop(context),
                              child: const Text('Cancel'),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 15),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              ),
                              onPressed: actionLoading ? null : () async {
                                try {
                                  setModalState(() => actionLoading = true);
                                  await OfficeTripsService.updateTrip(
                                    trip['id'],
                                    pickupLocation: pickup.text,
                                    dropoffLocation: dropoff.text,
                                    persons: int.tryParse(persons.text) ?? 1,
                                    basePrice: double.tryParse(price.text) ?? 0.0,
                                  );
                                  if (mounted) {
                                    Navigator.pop(context);
                                    UiUtils.showSuccess(context, "Trip updated");
                                  }
                                  await _loadTrips();
                                } on ApiException catch (e) {
                                  if (mounted) UiUtils.showError(context, e.message);
                                } finally {
                                  setModalState(() => actionLoading = false);
                                }
                              },
                              child: actionLoading 
                                ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                                : const Text('Update'),
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
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 15),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                          onPressed: actionLoading ? null : () => _completeTrip(trip),
                          child: actionLoading 
                            ? const CircularProgressIndicator(color: Colors.white)
                            : const Text('MARK AS COMPLETED', style: TextStyle(fontWeight: FontWeight.bold)),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Office Trips'),
        actions: [
          IconButton(onPressed: _loadTrips, icon: const Icon(Icons.refresh))
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadTrips,
        child: loading
            ? const Center(child: CircularProgressIndicator())
            : ListView(
          padding: const EdgeInsets.all(16),
          children: [
            if (myActiveTrips.isNotEmpty) ...[
              const _SectionHeader(title: 'My Active Trips', icon: Icons.directions_car),
              const SizedBox(height: 8),
              ...myActiveTrips.map((trip) => _TripCard(
                trip: trip,
                isActive: true,
                onTap: () => _openTripModal(trip),
              )),
              const SizedBox(height: 24),
            ],

            const _SectionHeader(title: 'Free Trips Available', icon: Icons.list_alt),
            const SizedBox(height: 8),

            if (freeTrips.isEmpty)
              const _EmptyState(message: 'No free trips available right now')
            else
              ...freeTrips.map((trip) => _TripCard(
                trip: trip,
                isActive: false,
                onAction: () => _takeTrip(trip),
                actionLoading: actionLoading,
              )),
          ],
        ),
      ),
    );
  }

  Widget _field(String label, TextEditingController c,
      {bool isNumber = false, IconData? icon}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextField(
        controller: c,
        keyboardType: isNumber ? TextInputType.number : TextInputType.text,
        textInputAction: TextInputAction.next,
        decoration: InputDecoration(
          prefixIcon: icon != null ? Icon(icon, size: 20) : null,
          labelText: label,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final IconData icon;
  const _SectionHeader({required this.title, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 20, color: Colors.blueGrey),
        const SizedBox(width: 8),
        Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.blueGrey)),
      ],
    );
  }
}

class _TripCard extends StatelessWidget {
  final dynamic trip;
  final bool isActive;
  final VoidCallback? onTap;
  final VoidCallback? onAction;
  final bool actionLoading;

  const _TripCard({
    required this.trip,
    required this.isActive,
    this.onTap,
    this.onAction,
    this.actionLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: isActive ? 4 : 1,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: isActive ? Colors.green.shade50 : Colors.white,
      child: ListTile(
        contentPadding: const EdgeInsets.all(12),
        onTap: onTap,
        title: Text(
          '${trip['pickup_location']} → ${trip['dropoff_location']}',
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.people_outline, size: 16, color: Colors.grey),
                  const SizedBox(width: 4),
                  Text('${trip['persons']} Persons', style: const TextStyle(color: Colors.grey)),
                  const SizedBox(width: 12),
                  const Icon(Icons.account_balance_wallet_outlined, size: 16, color: Colors.grey),
                  const SizedBox(width: 4),
                  Text('${trip['base_price']} ALL', style: const TextStyle(color: Colors.grey)),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                DateFormat('HH:mm | dd/MM/yy').format(DateTime.parse(trip['created_at'])),
                style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
              ),
            ],
          ),
        ),
        trailing: isActive 
          ? const Icon(Icons.edit, color: Colors.green)
          : ElevatedButton(
              style: ElevatedButton.styleFrom(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              onPressed: actionLoading ? null : onAction,
              child: const Text('TAKE'),
            ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final String message;
  const _EmptyState({required this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 40),
        child: Column(
          children: [
            Icon(Icons.info_outline, size: 48, color: Colors.grey.shade300),
            const SizedBox(height: 12),
            Text(message, style: TextStyle(color: Colors.grey.shade500)),
          ],
        ),
      ),
    );
  }
}
