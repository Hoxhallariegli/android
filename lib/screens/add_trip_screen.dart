import 'package:flutter/material.dart';
import '../services/trip_service.dart';

class AddTripScreen extends StatefulWidget {
  const AddTripScreen({super.key});

  @override
  State<AddTripScreen> createState() => _AddTripScreenState();
}

class _AddTripScreenState extends State<AddTripScreen> {
  final fromCtrl = TextEditingController();
  final toCtrl = TextEditingController();
  final personsCtrl = TextEditingController(); // ✅ ADDED
  final priceCtrl = TextEditingController();

  String tripType = 'custom'; // custom | template
  bool loading = false;

  Future<void> submit() async {
    // BASIC VALIDATION
    if (fromCtrl.text.trim().isEmpty ||
        toCtrl.text.trim().isEmpty ||
        priceCtrl.text.trim().isEmpty ||
        personsCtrl.text.trim().isEmpty) { // ✅ include persons
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Fill all fields')),
      );
      return;
    }

    final price = int.tryParse(priceCtrl.text);
    if (price == null || price <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter valid price')),
      );
      return;
    }

    final persons = int.tryParse(personsCtrl.text);
    if (persons == null || persons < 1) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Persons must be at least 1')),
      );
      return;
    }
    if (persons > 20) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Persons cannot exceed 20')),
      );
      return;
    }

    setState(() => loading = true);

    final success = await TripService.createTrip(
      from: fromCtrl.text.trim(),
      to: toCtrl.text.trim(),
      type: tripType,
      price: price,
      persons: persons, // ✅ PASS IT HERE
    );

    setState(() => loading = false);

    if (success && mounted) {
      Navigator.pop(context, true);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to save trip')),
      );
    }
  }

  @override
  void dispose() {
    fromCtrl.dispose();
    toCtrl.dispose();
    personsCtrl.dispose(); // ✅ dispose
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
              decoration: const InputDecoration(labelText: 'From *'),
            ),
            const SizedBox(height: 12),

            TextField(
              controller: toCtrl,
              decoration: const InputDecoration(labelText: 'To *'),
            ),
            const SizedBox(height: 12),

            TextField(
              controller: personsCtrl, // ✅ NEW FIELD
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Persons * (e.g. 2)'),
            ),
            const SizedBox(height: 12),

            // DropdownButtonFormField<String>(
            //   value: tripType,
            //   decoration: const InputDecoration(labelText: 'Trip Type'),
            //   items: const [
            //     DropdownMenuItem(value: 'custom', child: Text('Custom')),
            //     DropdownMenuItem(value: 'template', child: Text('Package')),
            //   ],
            //   onChanged: (v) => setState(() => tripType = v!),
            // ),
            // const SizedBox(height: 12),

            TextField(
              controller: priceCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Price (ALL) *'),
            ),
            const SizedBox(height: 24),

            SizedBox(
              height: 48,
              child: ElevatedButton(
                onPressed: loading ? null : submit,
                child: loading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('SAVE TRIP'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}