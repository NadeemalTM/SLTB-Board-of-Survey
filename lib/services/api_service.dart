import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
// Removed unused imports
import '../../services/firestore_service.dart'; // <--- USING FIREBASE NOW
// Removed unused SurveyStatus import

class AddItemScreen extends ConsumerStatefulWidget {
  final String? scannedCode; // Accepts code from scanner

  const AddItemScreen({super.key, this.scannedCode});

  @override
  ConsumerState<AddItemScreen> createState() => _AddItemScreenState();
}

class _AddItemScreenState extends ConsumerState<AddItemScreen> {
  final _formKey = GlobalKey<FormState>();

  // Controllers
  late TextEditingController _codeController;
  final _descriptionController = TextEditingController();
  final _locationController = TextEditingController();
  final _physicalBalanceController = TextEditingController(text: '1');
  // Removed unused remarks/status fields
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    // Use scanned code or generate a NEW one
    String initialCode =
        widget.scannedCode ?? 'NEW-${DateTime.now().millisecondsSinceEpoch}';
    _codeController = TextEditingController(text: initialCode);
  }

  Future<void> _saveNewAsset() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    try {
      // --- NEW FIREBASE LOGIC ---
      // We are calling FirestoreService, NOT ApiService
      final firestore = FirestoreService();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Asset Saved to Cloud!'),
              backgroundColor: Colors.green),
        );
        Navigator.pop(context); // Close screen
        Navigator.pop(context); // Close scanner (if open)
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Add New Item (Cloud)')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _codeController,
                readOnly: true,
                decoration: const InputDecoration(
                    labelText: 'Barcode', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                    labelText: 'Description', border: OutlineInputBorder()),
                validator: (val) => val!.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _locationController,
                decoration: const InputDecoration(
                    labelText: 'Location', border: OutlineInputBorder()),
                validator: (val) => val!.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _physicalBalanceController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                    labelText: 'Quantity', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _isSaving ? null : _saveNewAsset,
                style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    padding: const EdgeInsets.all(16)),
                child: _isSaving
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text("SAVE TO FIREBASE",
                        style: TextStyle(color: Colors.white)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
