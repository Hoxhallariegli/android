import 'package:flutter/material.dart';
import '../services/trip_service.dart';
import '../core/api_exception.dart';
import '../utils/ui_utils.dart';

class AddTripScreen extends StatefulWidget {
  const AddTripScreen({super.key});

  @override
  State<AddTripScreen> createState() => _AddTripScreenState();
}

class _AddTripScreenState extends State<AddTripScreen> {
  final fromCtrl = TextEditingController();
  final toCtrl = TextEditingController();
  final personsCtrl = TextEditingController();
  final priceCtrl = TextEditingController();

  String tripType = 'custom';
  bool loading = false;

  Future<void> submit() async {
    if (fromCtrl.text.trim().isEmpty ||
        toCtrl.text.trim().isEmpty ||
        priceCtrl.text.trim().isEmpty ||
        personsCtrl.text.trim().isEmpty) {
      UiUtils.showError(context, 'Please fill all required fields');
      return;
    }

    final price = int.tryParse(priceCtrl.text);
    if (price == null || price <= 0) {
      UiUtils.showError(context, 'Please enter a valid price');
      return;
    }

    final persons = int.tryParse(personsCtrl.text);
    if (persons == null || persons < 1) {
      UiUtils.showError(context, 'Persons must be at least 1');
      return;
    }

    setState(() => loading = true);

    try {
      await TripService.createTrip(
        from: fromCtrl.text.trim(),
        to: toCtrl.text.trim(),
        type: tripType,
        price: price,
        persons: persons,
      );
      
      if (mounted) {
        UiUtils.showSuccess(context, 'Trip created successfully');
        Navigator.pop(context, true);
      }
    } on ApiException catch (e) {
      if (mounted) {
        UiUtils.showError(context, e.message);
      }
    } catch (e) {
      if (mounted) {
        UiUtils.showError(context, 'An unexpected error occurred');
      }
    } finally {
      if (mounted) {
        setState(() => loading = false);
      }
    }
  }

  @override
  void dispose() {
    fromCtrl.dispose();
    toCtrl.dispose();
    personsCtrl.dispose();
    priceCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Add Trip')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
            TextField(
              controller: fromCtrl,
              decoration: const InputDecoration(
                labelText: 'From *',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: toCtrl,
              decoration: const InputDecoration(
                labelText: 'To *',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: personsCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Number of Persons *',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: priceCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Price (ALL) *',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              height: 50,
              child: ElevatedButton(
                onPressed: loading ? null : submit,
                style: ElevatedButton.styleFrom(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                child: loading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Text('SAVE TRIP', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
