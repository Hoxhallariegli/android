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
        UiUtils.showError(context, "Dështoi ngarkimi i udhëtimeve");
      }
    }
  }

  // ================= ACTIONS =================

  Future<void> _takeTrip(dynamic trip) async {
    try {
      setState(() => actionLoading = true);
      await OfficeTripsService.takeTrip(trip['id']);
      if (mounted) UiUtils.showSuccess(context, "Udhëtimi juaj u caktua");
      await _loadTrips();
    } on ApiException catch (e) {
      if (mounted) {
        UiUtils.showError(context, e.message);
        if (e.statusCode == 422) await _loadTrips();
      }
    } finally {
      if (mounted) setState(() => actionLoading = false);
    }
  }

  Future<void> _handleComplete(dynamic trip, {
    required String pickup,
    required String dropoff,
    required int persons,
    required double price,
  }) async {
    try {
      setState(() => actionLoading = true);
      await OfficeTripsService.updateTrip(
        trip['id'],
        pickupLocation: pickup,
        dropoffLocation: dropoff,
        persons: persons,
        basePrice: price,
      );
      await OfficeTripsService.completeTrip(trip['id']);
      if (mounted) {
        Navigator.pop(context);
        UiUtils.showSuccess(context, "Udhëtimi u mbyll me sukses");
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
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(25))),
      builder: (modalContext) => StatefulBuilder(
        builder: (context, setModalState) => Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
          child: Container(
            constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.85),
            child: SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 10, 20, 35),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(width: 40, height: 5, margin: const EdgeInsets.only(bottom: 20), decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(10))),
                    const Text('Detajet e Udhëtimit', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 25),
                    _modalField('Nisja', pickup, icon: Icons.location_on),
                    _modalField('Mbërritja', dropoff, icon: Icons.flag),
                    Row(
                      children: [
                        Expanded(child: _modalField('Persona', persons, isNumber: true, icon: Icons.people)),
                        const SizedBox(width: 12),
                        Expanded(child: _modalField('Çmimi (ALL)', price, isNumber: true, icon: Icons.money)),
                      ],
                    ),
                    const SizedBox(height: 30),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 15), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                            onPressed: () => Navigator.pop(context),
                            child: const Text('Anulo'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 15), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                            onPressed: actionLoading ? null : () async {
                              try {
                                setModalState(() => actionLoading = true);
                                await OfficeTripsService.updateTrip(trip['id'], pickupLocation: pickup.text, dropoffLocation: dropoff.text, persons: int.tryParse(persons.text) ?? 1, basePrice: double.tryParse(price.text) ?? 0.0);
                                if (mounted) { Navigator.pop(context); UiUtils.showSuccess(context, "Udhëtimi u përditësua"); }
                                await _loadTrips();
                              } on ApiException catch (e) {
                                if (mounted) UiUtils.showError(context, e.message);
                              } finally {
                                setModalState(() => actionLoading = false);
                              }
                            },
                            child: actionLoading ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Text('Ruaj'),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 15), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                        onPressed: actionLoading ? null : () => _handleComplete(trip, pickup: pickup.text, dropoff: dropoff.text, persons: int.tryParse(persons.text) ?? 1, price: double.tryParse(price.text) ?? 0.0),
                        child: actionLoading ? const CircularProgressIndicator(color: Colors.white) : const Text('PËRFUNDO UDHËTIMIN', style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
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
      backgroundColor: const Color(0xFFF8F8F8),
      body: RefreshIndicator(
        onRefresh: _loadTrips,
        child: loading
            ? const Center(child: CircularProgressIndicator())
            : ListView(
          padding: const EdgeInsets.all(16),
          children: [
            if (myActiveTrips.isNotEmpty) ...[
              const _SectionHeader(title: 'Udhëtimet e Mia Aktive', icon: Icons.directions_car),
              const SizedBox(height: 10),
              ...myActiveTrips.map((trip) => _TripCard(trip: trip, isActive: true, onTap: () => _openTripModal(trip))),
              const SizedBox(height: 25),
            ],
            const _SectionHeader(title: 'Udhëtime të Lira', icon: Icons.list_alt),
            const SizedBox(height: 10),
            if (freeTrips.isEmpty)
              const _EmptyState(message: 'Nuk ka udhëtime të lira për momentin')
            else
              ...freeTrips.map((trip) => _TripCard(trip: trip, isActive: false, onAction: () => _takeTrip(trip), actionLoading: actionLoading)),
          ],
        ),
      ),
    );
  }

  Widget _modalField(String label, TextEditingController c, {bool isNumber = false, IconData? icon}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextField(
        controller: c,
        keyboardType: isNumber ? TextInputType.number : TextInputType.text,
        decoration: InputDecoration(
          prefixIcon: Icon(icon, size: 20, color: const Color(0xFFD4AF37)),
          labelText: label,
          filled: true,
          fillColor: Colors.grey.shade50,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
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
    return Row(children: [Icon(icon, size: 20, color: Colors.black87), const SizedBox(width: 8), Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87))]);
  }
}

class _TripCard extends StatelessWidget {
  final dynamic trip;
  final bool isActive;
  final VoidCallback? onTap;
  final VoidCallback? onAction;
  final bool actionLoading;
  const _TripCard({required this.trip, required this.isActive, this.onTap, this.onAction, this.actionLoading = false});
  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      color: Colors.white,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(15),
        child: Padding(
          padding: const EdgeInsets.all(15),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('${trip['pickup_location']} → ${trip['dropoff_location']}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  if (isActive) const Icon(Icons.edit, color: Color(0xFFD4AF37), size: 20),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  const Icon(Icons.people_outline, size: 16, color: Colors.grey),
                  const SizedBox(width: 4),
                  Text('${trip['persons']} Persona', style: const TextStyle(color: Colors.grey, fontSize: 13)),
                  const SizedBox(width: 15),
                  const Icon(Icons.account_balance_wallet_outlined, size: 16, color: Colors.grey),
                  const SizedBox(width: 4),
                  Text('${trip['base_price']} ALL', style: const TextStyle(color: Colors.grey, fontSize: 13)),
                ],
              ),
              const Divider(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(DateFormat('HH:mm | dd/MM/yy').format(DateTime.parse(trip['created_at'])), style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                  if (!isActive) 
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFD4AF37), foregroundColor: Colors.black, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)), padding: const EdgeInsets.symmetric(horizontal: 20)),
                      onPressed: actionLoading ? null : onAction,
                      child: const Text('MERR', style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                ],
              ),
            ],
          ),
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
    return Center(child: Padding(padding: const EdgeInsets.symmetric(vertical: 40), child: Column(children: [Icon(Icons.info_outline, size: 48, color: Colors.grey.shade300), const SizedBox(height: 12), Text(message, style: TextStyle(color: Colors.grey.shade500))])));
  }
}
