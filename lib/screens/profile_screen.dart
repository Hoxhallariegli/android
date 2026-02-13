import 'dart:async';
import 'package:flutter/material.dart';
import '../services/driver_service.dart';
import '../services/auth_service.dart';
import 'login_screen.dart';
import 'package:intl/intl.dart';
import '../core/api_exception.dart';
import '../utils/ui_utils.dart';
import '../services/push_service.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  Map<String, dynamic>? driver;
  List<dynamic> trips = [];

  bool loadingProfile = true;
  bool loadingTrips = true;
  bool actionLoading = false;

  String? period;
  StreamSubscription? _refreshSub;

  @override
  void initState() {
    super.initState();
    _loadProfile();
    _loadTrips();

    _refreshSub = PushService.refreshStream.listen((event) {
      if (event == 'trips' && mounted) {
        _loadTrips();
        _loadProfile();
      }
    });
  }

  @override
  void dispose() {
    _refreshSub?.cancel();
    super.dispose();
  }

  Future<void> _loadProfile() async {
    try {
      if (mounted) setState(() => loadingProfile = true);
      final data = await DriverService.getProfile();
      if (mounted) {
        setState(() {
          driver = data;
          loadingProfile = false;
        });
      }
    } on ApiException catch (e) {
      if (mounted) {
        setState(() => loadingProfile = false);
        UiUtils.showError(context, e.message);
      }
    } catch (e) {
      if (mounted) setState(() => loadingProfile = false);
    }
  }

  Future<void> _loadTrips() async {
    try {
      if (mounted) setState(() => loadingTrips = true);
      final data = await DriverService.getTrips(period: period);
      if (mounted) {
        setState(() {
          trips = data;
          loadingTrips = false;
        });
      }
    } on ApiException catch (e) {
      if (mounted) {
        setState(() => loadingTrips = false);
        UiUtils.showError(context, e.message);
      }
    } catch (e) {
      if (mounted) setState(() => loadingTrips = false);
    }
  }

  Future<void> _refreshAllData() async {
    await Future.wait([_loadTrips(), _loadProfile()]);
  }

  void _openUpdateTripModal(Map<String, dynamic> trip) {
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
                padding: const EdgeInsets.fromLTRB(20, 10, 20, 40),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(width: 40, height: 5, margin: const EdgeInsets.only(bottom: 20), decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(10))),
                    const Text('Përditëso Udhëtimin', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 25),
                    _modalField('Nisja', pickup, icon: Icons.location_on),
                    _modalField('Mbërritja', dropoff, icon: Icons.flag),
                    Row(
                      children: [
                        Expanded(child: _modalField('Persona', persons, isNumber: true, icon: Icons.people)),
                        const SizedBox(width: 12),
                        Expanded(child: _modalField('Çmimi', price, isNumber: true, icon: Icons.money)),
                      ],
                    ),
                    const SizedBox(height: 30),
                    Row(
                      children: [
                        Expanded(child: OutlinedButton(onPressed: () => Navigator.pop(context), child: const Text('Anulo'))),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: actionLoading ? null : () async {
                              try {
                                setModalState(() => actionLoading = true);
                                await DriverService.updateTrip(trip['id'], pickupLocation: pickup.text, dropoffLocation: dropoff.text, persons: int.tryParse(persons.text) ?? 1, basePrice: double.tryParse(price.text) ?? 0.0);
                                if (mounted) { Navigator.pop(context); UiUtils.showSuccess(context, "Trip updated"); }
                                await _refreshAllData();
                              } on ApiException catch (e) {
                                if (mounted) UiUtils.showError(context, e.message);
                              } finally {
                                setModalState(() => actionLoading = false);
                              }
                            },
                            child: actionLoading ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2)) : const Text('Ruaj'),
                          ),
                        ),
                      ],
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
    if (loadingProfile && driver == null) return const Center(child: CircularProgressIndicator());
    final d = driver ?? {};

    return Scaffold(
      backgroundColor: const Color(0xFFF8F8F8),
      body: RefreshIndicator(
        onRefresh: _refreshAllData,
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: const BoxDecoration(
                  color: Colors.black,
                  borderRadius: BorderRadius.only(bottomLeft: Radius.circular(30), bottomRight: Radius.circular(30)),
                ),
                child: Column(
                  children: [
                    const CircleAvatar(radius: 40, backgroundColor: Color(0xFFD4AF37), child: Icon(Icons.person, size: 45, color: Colors.black)),
                    const SizedBox(height: 15),
                    Text(d['name'] ?? 'Shoferi', style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
                    Text(d['email'] ?? '', style: TextStyle(color: Colors.white.withOpacity(0.6))),
                    const SizedBox(height: 25),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _statItem('Sot', d['today_trips'] ?? 0, Icons.today),
                        _statItem('Total', d['total_trips'] ?? 0, Icons.history),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.all(20),
              sliver: SliverToBoxAdapter(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Historiku i Udhëtimeve', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    _FilterChip(currentPeriod: period, onSelected: (p) { setState(() => period = p); _loadTrips(); }),
                  ],
                ),
              ),
            ),
            loadingTrips 
              ? const SliverFillRemaining(child: Center(child: CircularProgressIndicator()))
              : trips.isEmpty 
                ? const SliverFillRemaining(child: Center(child: Text('Nuk u gjet asnjë udhëtim', style: TextStyle(color: Colors.grey))))
                : SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) => _TripListCard(trip: trips[index], onEdit: () => _openUpdateTripModal(Map<String, dynamic>.from(trips[index]))),
                        childCount: trips.length,
                      ),
                    ),
                  ),
            const SliverToBoxAdapter(child: SizedBox(height: 60)),
          ],
        ),
      ),
    );
  }

  Widget _statItem(String label, dynamic value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: const Color(0xFFD4AF37), size: 22),
        const SizedBox(height: 5),
        Text(value.toString(), style: const TextStyle(fontSize: 20, color: Colors.white, fontWeight: FontWeight.bold)),
        Text(label, style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 12)),
      ],
    );
  }

  Widget _modalField(String label, TextEditingController c, {bool isNumber = false, IconData? icon}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
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

  Future<void> _logout(BuildContext context) async {
    await AuthService.logout();
    if (!mounted) return;
    Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (_) => const LoginScreen()), (_) => false);
  }
}

class _TripListCard extends StatelessWidget {
  final dynamic trip;
  final VoidCallback onEdit;
  const _TripListCard({required this.trip, required this.onEdit});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 1,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      color: Colors.white,
      child: ListTile(
        onTap: onEdit,
        contentPadding: const EdgeInsets.all(15),
        title: Text('${trip['pickup_location']} → ${trip['dropoff_location']}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Text('Persona: ${trip['persons']} | ${trip['base_price']} ALL', style: const TextStyle(color: Colors.grey, fontSize: 13)),
        ),
        trailing: const Icon(Icons.chevron_right, color: Color(0xFFD4AF37)),
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String? currentPeriod;
  final Function(String?) onSelected;
  const _FilterChip({this.currentPeriod, required this.onSelected});
  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String?>(
      icon: const Icon(Icons.filter_list, color: Color(0xFFD4AF37)),
      onSelected: onSelected,
      itemBuilder: (context) => [
        const PopupMenuItem(value: null, child: Text('Të gjitha')),
        const PopupMenuItem(value: 'day', child: Text('Sot')),
        const PopupMenuItem(value: 'week', child: Text('Këtë Javë')),
        const PopupMenuItem(value: 'month', child: Text('Këtë Muaj')),
      ],
    );
  }
}
