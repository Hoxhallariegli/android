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

    // 🔥 Real-time Listener: Refresh when backend sends signal
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

  // ================= DATA LOADING =================

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

  // ================= MODALS =================

  void _openUpdateTripModal(Map<String, dynamic> trip) {
    final pickup = TextEditingController(text: trip['pickup_location']);
    final dropoff = TextEditingController(text: trip['dropoff_location']);
    final persons = TextEditingController(text: trip['persons'].toString());
    final price = TextEditingController(text: trip['base_price'].toString());

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (modalContext) => StatefulBuilder(
        builder: (context, setModalState) => Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
          child: Container(
            constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.8),
            child: SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 10, 20, 40),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(width: 40, height: 5, margin: const EdgeInsets.only(bottom: 20), decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(10))),
                    const Text('Update Trip Details', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 20),
                    _modalField('Pickup', pickup, icon: Icons.location_on),
                    _modalField('Dropoff', dropoff, icon: Icons.flag),
                    Row(
                      children: [
                        Expanded(child: _modalField('Persons', persons, isNumber: true, icon: Icons.people)),
                        const SizedBox(width: 12),
                        Expanded(child: _modalField('Price', price, isNumber: true, icon: Icons.money)),
                      ],
                    ),
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        Expanded(child: OutlinedButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel'))),
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
                            child: actionLoading ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2)) : const Text('Save Changes'),
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

  void _confirmDeleteTrip(int tripId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete Trip'),
        content: const Text('This action cannot be undone. Are you sure?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white), onPressed: () => Navigator.pop(context, true), child: const Text('Delete')),
        ],
      ),
    );

    if (confirm == true) {
      try {
        setState(() => actionLoading = true);
        await DriverService.deleteTrip(tripId);
        if (mounted) UiUtils.showSuccess(context, "Trip removed");
        await _refreshAllData();
      } on ApiException catch (e) {
        if (mounted) UiUtils.showError(context, e.message);
      } finally {
        if (mounted) setState(() => actionLoading = false);
      }
    }
  }

  // ================= UI COMPONENTS =================

  @override
  Widget build(BuildContext context) {
    if (loadingProfile && driver == null) return const Center(child: CircularProgressIndicator());
    final d = driver ?? {};

    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      body: RefreshIndicator(
        onRefresh: _refreshAllData,
        child: CustomScrollView(
          slivers: [
            SliverAppBar(
              expandedHeight: 200,
              pinned: true,
              flexibleSpace: FlexibleSpaceBar(
                background: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Colors.blue.shade800, Colors.blue.shade600]),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const CircleAvatar(radius: 35, backgroundColor: Colors.white, child: Icon(Icons.person, size: 40, color: Colors.blue)),
                      const SizedBox(height: 10),
                      Text(d['name'] ?? 'Driver', style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                      Text(d['email'] ?? '', style: const TextStyle(color: Colors.white70)),
                    ],
                  ),
                ),
              ),
              actions: [IconButton(icon: const Icon(Icons.logout, color: Colors.white), onPressed: () => _logout(context))],
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Card(
                      elevation: 2,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 20),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            _statItem('Today', d['today_trips'] ?? 0, Icons.today),
                            _statItem('Total', d['total_trips'] ?? 0, Icons.history),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Trip History', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                        _FilterChip(currentPeriod: period, onSelected: (p) { setState(() => period = p); _loadTrips(); }),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            loadingTrips 
              ? const SliverFillRemaining(child: Center(child: CircularProgressIndicator()))
              : trips.isEmpty 
                ? const SliverFillRemaining(child: Center(child: Text('No trips found', style: TextStyle(color: Colors.grey))))
                : SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) => _TripListCard(
                          trip: trips[index],
                          onEdit: () => _openUpdateTripModal(Map<String, dynamic>.from(trips[index])),
                          onDelete: () => _confirmDeleteTrip(trips[index]['id']),
                        ),
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
        Icon(icon, color: Colors.blue, size: 20),
        const SizedBox(height: 4),
        Text(value.toString(), style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
        Text(label, style: const TextStyle(color: Colors.grey)),
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
          prefixIcon: icon != null ? Icon(icon, size: 20) : null,
          labelText: label,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
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
  final VoidCallback onDelete;

  const _TripListCard({required this.trip, required this.onEdit, required this.onDelete});

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'completed': return Colors.green;
      case 'taken':
      case 'active':
      case 'in_progress': return Colors.blue;
      case 'cancelled': return Colors.red;
      case 'pending':
      case 'open': return Colors.orange;
      default: return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final status = trip['status'] ?? 'open';
    final statusColor = _getStatusColor(status);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: InkWell(
        borderRadius: BorderRadius.circular(15),
        onTap: onEdit,
        child: Padding(
          padding: const EdgeInsets.all(15),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(color: statusColor.withOpacity(0.1), borderRadius: BorderRadius.circular(20)),
                    child: Text(status.toUpperCase(), style: TextStyle(color: statusColor, fontSize: 10, fontWeight: FontWeight.bold)),
                  ),
                  Text('${trip['base_price']} ALL', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blue)),
                ],
              ),
              const SizedBox(height: 12),
              Text('${trip['pickup_location']} → ${trip['dropoff_location']}', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.people_outline, size: 16, color: Colors.grey),
                  const SizedBox(width: 4),
                  Text('${trip['persons']} Persons', style: const TextStyle(color: Colors.grey, fontSize: 13)),
                  const Spacer(),
                  const Icon(Icons.access_time, size: 16, color: Colors.grey),
                  const SizedBox(width: 4),
                  Text(DateFormat('HH:mm | dd/MM/yy').format(DateTime.parse(trip['created_at'])), style: const TextStyle(color: Colors.grey, fontSize: 12)),
                ],
              ),
              if (trip['assigned_by'] != null) ...[
                const Divider(),
                Row(
                  children: [
                    const Icon(Icons.assignment_ind_outlined, size: 14, color: Colors.blueGrey),
                    const SizedBox(width: 4),
                    Text('Assigned by #${trip['assigned_by']}', style: const TextStyle(fontSize: 11, color: Colors.blueGrey, fontStyle: FontStyle.italic)),
                  ],
                )
              ]
            ],
          ),
        ),
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
      icon: const Icon(Icons.filter_list, color: Colors.blue),
      onSelected: onSelected,
      itemBuilder: (context) => [
        const PopupMenuItem(value: null, child: Text('All Time')),
        const PopupMenuItem(value: 'day', child: Text('Today')),
        const PopupMenuItem(value: 'week', child: Text('This Week')),
        const PopupMenuItem(value: 'month', child: Text('This Month')),
      ],
    );
  }
}
