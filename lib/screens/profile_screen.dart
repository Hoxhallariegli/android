import 'package:flutter/material.dart';
import '../services/driver_service.dart';
import '../services/auth_service.dart';
import 'login_screen.dart';
import 'package:intl/intl.dart';

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

  String? period;

  @override
  void initState() {
    super.initState();
    _loadProfile();
    _loadTrips();
  }

  // ================= DATA =================

  Future<void> _loadProfile() async {
    try {
      final data = await DriverService.getProfile();
      if (!mounted) return;
      setState(() {
        driver = data;
        loadingProfile = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => loadingProfile = false);
    }
  }

  Future<void> _loadTrips() async {
    try {
      setState(() => loadingTrips = true);
      final data = await DriverService.getTrips(period: period);
      if (!mounted) return;
      setState(() {
        trips = data;
        loadingTrips = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => loadingTrips = false);
    }
  }

  Future<void> _refreshAllData() async {
    try {
      await Future.wait([
        _loadTrips(),
        _loadProfile(),
      ]);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error refreshing data: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _logout(BuildContext context) async {
    await AuthService.logout();
    if (!context.mounted) return;

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
          (_) => false,
    );
  }

  // ================= FILTER MODAL =================

  void _openTripsFilterModal() async {
    final selected = await showModalBottomSheet<String?>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                height: 4,
                width: 40,
                margin: const EdgeInsets.only(top: 8, bottom: 8),
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              _filterItem('All', null),
              _filterItem('Today', 'day'),
              _filterItem('This Week', 'week'),
              _filterItem('This Month', 'month'),
              _filterItem('This Year', 'year'),
              const SizedBox(height: 20),
            ],
          ),
        );
      },
    );

    if (selected != null) {
      setState(() => period = selected);
      _loadTrips();
    }
  }

  Widget _filterItem(String label, String? value) {
    return ListTile(
      title: Text(label),
      trailing: period == value ? const Icon(Icons.check) : null,
      onTap: () => Navigator.pop(context, value),
    );
  }

  // ================= TRIP ACTIONS MODAL =================

  void _openTripActionsModal(Map<String, dynamic> trip) async {
    final action = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) {
        return DraggableScrollableSheet(
          initialChildSize: 0.45,
          minChildSize: 0.3,
          maxChildSize: 0.6,
          builder: (_, controller) {
            return Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
              ),
              child: ListView(
                controller: controller,
                padding: const EdgeInsets.all(16),
                children: [
                  Container(
                    height: 4,
                    width: 40,
                    margin: const EdgeInsets.only(bottom: 16),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade400,
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  Text(
                    '${trip['pickup_location']} → ${trip['dropoff_location']}',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text('Persons: ${trip['persons']}'),
                  Text('Price: ${trip['base_price']} ALL'),
                  Text('Date: ${_formatDate(trip['created_at'])}'),
                  const Divider(height: 32),
                  ListTile(
                    leading: const Icon(Icons.edit, color: Colors.blue),
                    title: const Text('Update trip'),
                    onTap: () => Navigator.pop(context, 'update'),
                  ),
                  ListTile(
                    leading: const Icon(Icons.delete, color: Colors.red),
                    title: const Text('Delete trip'),
                    onTap: () => Navigator.pop(context, 'delete'),
                  ),
                  ListTile(
                    leading: const Icon(Icons.close),
                    title: const Text('Cancel'),
                    onTap: () => Navigator.pop(context),
                  ),
                ],
              ),
            );
          },
        );
      },
    );

    if (action == 'update') {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _openUpdateTripModal(trip);
      });
    } else if (action == 'delete') {
      _confirmDeleteTrip(trip['id']);
    }
  }

  // ================= UPDATE TRIP MODAL =================

  void _openUpdateTripModal(Map<String, dynamic> trip) async {
    final pickupController =
    TextEditingController(text: trip['pickup_location']);
    final dropoffController =
    TextEditingController(text: trip['dropoff_location']);
    final personsController =
    TextEditingController(text: trip['persons'].toString());
    final priceController =
    TextEditingController(text: trip['base_price'].toString());

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (BuildContext modalContext) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(modalContext).viewInsets.bottom,
          ),
          child: SingleChildScrollView(
            child: Container(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      height: 4,
                      width: 40,
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const Text(
                    'Update Trip',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: pickupController,
                    decoration: const InputDecoration(
                      labelText: 'Pickup location',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: dropoffController,
                    decoration: const InputDecoration(
                      labelText: 'Dropoff location',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: personsController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Persons',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: priceController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Base price',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(modalContext),
                          child: const Text('Cancel'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () async {
                            try {
                              await DriverService.updateTrip(
                                trip['id'],
                                pickupLocation: pickupController.text,
                                dropoffLocation: dropoffController.text,
                                persons: int.parse(personsController.text),
                                basePrice: double.parse(priceController.text),
                              );

                              if (!mounted) return;
                              Navigator.pop(modalContext);
                              await _refreshAllData();
                            } catch (e) {
                              if (!mounted) return;
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Error updating trip: $e'),
                                  backgroundColor: Colors.red,
                                ),
                              );
                            }
                          },
                          child: const Text('Save'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // ================= DELETE CONFIRM =================

  void _confirmDeleteTrip(int tripId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete trip'),
        content: const Text('Are you sure you want to delete this trip?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await DriverService.deleteTrip(tripId);
        await _refreshAllData();
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error deleting trip: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  // ================= UI =================

  @override
  Widget build(BuildContext context) {
    if (loadingProfile) {
      return const Center(child: CircularProgressIndicator());
    }

    if (driver == null) {
      return const SizedBox.shrink();
    }

    final d = driver!;

    return RefreshIndicator(
      onRefresh: _refreshAllData,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          d['name'] ?? '',
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.logout),
                        onPressed: () => _logout(context),
                      ),
                    ],
                  ),
                  Text(d['email'] ?? ''),
                  const Divider(height: 24),
                  Row(
                    children: [
                      Expanded(child: _stat('Today', d['today_trips'] ?? 0)),
                      Expanded(child: _stat('Total', d['total_trips'] ?? 0)),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Trips',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              IconButton(
                icon: const Icon(Icons.filter_list),
                onPressed: _openTripsFilterModal,
              ),
            ],
          ),
          const Divider(),
          if (loadingTrips)
            const Center(child: CircularProgressIndicator())
          else if (trips.isEmpty)
            const Center(child: Text('No trips found'))
          else
            ...trips.map(
                  (t) => Card(
                child: ListTile(
                  onTap: () => _openTripActionsModal(t),
                  title: Text(
                    '${t['pickup_location']} → ${t['dropoff_location']}',
                  ),
                  subtitle: Text(
                    'Persons: ${t['persons']} | ${_formatDate(t['created_at'])}',
                  ),
                  trailing: const Icon(Icons.more_vert),
                ),
              ),
            ),
        ],
      ),
    );
  }

  static String _formatDate(String date) {
    try {
      return DateFormat('HH:mm | dd/MM/yy').format(DateTime.parse(date));
    } catch (e) {
      return 'Invalid date';
    }
  }

  Widget _stat(String label, dynamic value) {
    return Column(
      children: [
        Text(
          value.toString(),
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(label),
      ],
    );
  }
}