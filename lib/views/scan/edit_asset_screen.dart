import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../services/firestore_service.dart';
import '../../core/constants/survey_status.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/region_selector.dart';

class EditAssetScreen extends ConsumerStatefulWidget {
  final Map<String, dynamic> data;
  final String docId;

  const EditAssetScreen({super.key, required this.data, required this.docId});

  @override
  ConsumerState<EditAssetScreen> createState() => _EditAssetScreenState();
}

class _EditAssetScreenState extends ConsumerState<EditAssetScreen> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _qtyController;
  late TextEditingController _remarksController;
  late String _selectedStatus;
  bool _isSaving = false;

  // Region fields
  late String _selectedMainRegion;
  late String _selectedSubRegion;

  @override
  void initState() {
    super.initState();
    _qtyController =
        TextEditingController(text: widget.data['physicalBalance'].toString());
    _remarksController =
        TextEditingController(text: widget.data['remarks'] ?? '');
    _selectedStatus = widget.data['status'] ?? SurveyStatus.good;

    // Initialize region from existing data or from logged-in user
    _selectedMainRegion = widget.data['mainRegion'] ?? '';
    _selectedSubRegion = widget.data['subRegion'] ?? '';

    // If asset doesn't have region data, try filling from logged-in user
    final authState = ref.read(authProvider);
    final user = authState.user;
    if (user != null && !user.isAdmin) {
      if (_selectedMainRegion.isEmpty) {
        _selectedMainRegion = user.mainRegion;
      }
      if (_selectedSubRegion.isEmpty) {
        _selectedSubRegion = user.subRegion;
      }
    }
  }

  Future<void> _updateAsset() async {
    // Validate region selection
    if (_selectedMainRegion.isEmpty || _selectedSubRegion.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select both Region and Sub-Division'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _isSaving = true);
    try {
      await FirestoreService().updateAsset(
        widget.docId,
        int.parse(_qtyController.text),
        _selectedStatus,
        _remarksController.text,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Verification Saved!'),
            backgroundColor: Colors.green));
        Navigator.pop(context);
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final isOfficer = authState.user != null && !authState.user!.isAdmin;

    return Scaffold(
      appBar: AppBar(title: const Text('Verify Asset')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ASSET INFO CARD
              Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.check_circle_outline,
                              color: Colors.green, size: 30),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              widget.data['description'] ?? 'Unknown Item',
                              style: const TextStyle(
                                  fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ),
                      const Divider(height: 30),
                      _buildInfoRow(Icons.qr_code, "Barcode", widget.docId),
                      _buildInfoRow(Icons.location_on, "Location",
                          widget.data['location'] ?? 'N/A'),
                      _buildInfoRow(
                          Icons.history,
                          "Last Updated",
                          widget.data['lastUpdated']
                                  ?.toDate()
                                  .toString()
                                  .split(' ')[0] ??
                              'Never'),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // REGION SECTION
              Text(
                "REGION ASSIGNMENT",
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[700],
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 8),
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: RegionSelector(
                    lockedMainRegion:
                        isOfficer && _selectedMainRegion.isNotEmpty
                            ? _selectedMainRegion
                            : null,
                    initialMainRegion: _selectedMainRegion.isNotEmpty
                        ? _selectedMainRegion
                        : null,
                    initialSubRegion: _selectedSubRegion.isNotEmpty
                        ? _selectedSubRegion
                        : null,
                    onSelectionChanged: (main, sub) {
                      setState(() {
                        _selectedMainRegion = main;
                        _selectedSubRegion = sub;
                      });
                    },
                  ),
                ),
              ),
              const SizedBox(height: 24),

              const Text("Verification Details",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),

              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _qtyController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                          labelText: 'Physical Qty',
                          border: OutlineInputBorder()),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      initialValue: _selectedStatus,
                      decoration: const InputDecoration(
                          labelText: 'Condition', border: OutlineInputBorder()),
                      items: [
                        SurveyStatus.good,
                        SurveyStatus.broken,
                        SurveyStatus.missing
                      ]
                          .map((s) => DropdownMenuItem(
                              value: s, child: Text(s.toUpperCase())))
                          .toList(),
                      onChanged: (val) =>
                          setState(() => _selectedStatus = val!),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _remarksController,
                maxLines: 3,
                decoration: const InputDecoration(
                    labelText: 'Officer Remarks',
                    hintText: 'Any damage or discrepancies?',
                    border: OutlineInputBorder()),
              ),

              const SizedBox(height: 30),
              ElevatedButton.icon(
                onPressed: _isSaving ? null : _updateAsset,
                icon: const Icon(Icons.verified),
                label: Text(_isSaving ? "Saving..." : "CONFIRM & SAVE"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green[700],
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  textStyle: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        children: [
          Icon(icon, size: 16, color: Colors.grey),
          const SizedBox(width: 8),
          Text("$label: ", style: const TextStyle(color: Colors.grey)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}
