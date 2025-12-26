import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import '../../core/utils/csv_helper.dart';
import '../../data/database/database_helper.dart';

/// Merge Field Data Screen - Import field officer survey data
class MergeFieldDataScreen extends ConsumerStatefulWidget {
  const MergeFieldDataScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<MergeFieldDataScreen> createState() =>
      _MergeFieldDataScreenState();
}

class _MergeFieldDataScreenState extends ConsumerState<MergeFieldDataScreen> {
  String? _selectedFilePath;
  bool _isLoading = false;
  String? _resultMessage;
  bool _isSuccess = false;
  Map<String, dynamic>? _mergeResults;

  Future<void> _pickFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['csv'],
    );

    if (result != null && result.files.single.path != null) {
      setState(() {
        _selectedFilePath = result.files.single.path;
        _resultMessage = null;
        _mergeResults = null;
      });
    }
  }

  Future<void> _mergeData() async {
    if (_selectedFilePath == null) return;

    setState(() {
      _isLoading = true;
      _resultMessage = null;
      _mergeResults = null;
    });

    try {
      // Parse field officer CSV
      final fieldAssets =
          await CsvHelper.parseFieldOfficerCsv(_selectedFilePath!);

      if (fieldAssets.isEmpty) {
        setState(() {
          _isLoading = false;
          _isSuccess = false;
          _resultMessage = 'No valid data found in CSV file';
        });
        return;
      }

      // Merge into database
      final db = DatabaseHelper.instance;
      final results = await db.mergeFieldOfficerCsv(fieldAssets);

      setState(() {
        _isLoading = false;
        _isSuccess = true;
        _mergeResults = results;
        _resultMessage =
            'Successfully processed ${fieldAssets.length} records';
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _isSuccess = false;
        _resultMessage = 'Error: ${e.toString()}';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Merge Field Officer Data'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Instructions Card
            Card(
              color: Colors.orange[50],
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.info, color: Colors.orange[700]),
                        const SizedBox(width: 8),
                        const Text(
                          'Field Officer CSV Format',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'The field CSV must contain survey data with:',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 8),
                    _buildFormatItem('Serial No, Description, Codes'),
                    _buildFormatItem('Physical Balance (surveyed quantity)'),
                    _buildFormatItem('Survey Status (Verified/Damaged/Missing)'),
                    _buildFormatItem('Remarks and image paths'),
                    _buildFormatItem('Last updated by and date'),
                    const SizedBox(height: 12),
                    Text(
                      'ℹ️ Matching is done using New Code field',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.blue[800],
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // File Selection
            const Text(
              'Select Field Officer CSV',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Card(
              child: InkWell(
                onTap: _isLoading ? null : _pickFile,
                borderRadius: BorderRadius.circular(12),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      Icon(
                        Icons.upload_file,
                        size: 64,
                        color: _selectedFilePath != null
                            ? Colors.green
                            : Colors.grey,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        _selectedFilePath != null
                            ? _selectedFilePath!.split('\\').last
                            : 'Tap to select CSV file',
                        style: TextStyle(
                          fontSize: 14,
                          color: _selectedFilePath != null
                              ? Colors.black87
                              : Colors.grey,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      if (_selectedFilePath != null) ...[
                        const SizedBox(height: 8),
                        Chip(
                          avatar: const Icon(Icons.check_circle,
                              color: Colors.white, size: 18),
                          label: const Text('File Selected'),
                          backgroundColor: Colors.green,
                          labelStyle: const TextStyle(color: Colors.white),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Merge Button
            ElevatedButton.icon(
              onPressed: _selectedFilePath != null && !_isLoading
                  ? _mergeData
                  : null,
              icon: _isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Icon(Icons.merge_type),
              label: Text(_isLoading ? 'Merging...' : 'Merge Data'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                backgroundColor: Colors.orange[700],
                foregroundColor: Colors.white,
              ),
            ),

            // Result Message
            if (_resultMessage != null) ...[
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: _isSuccess ? Colors.green[50] : Colors.red[50],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color:
                        _isSuccess ? Colors.green[200]! : Colors.red[200]!,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      _isSuccess ? Icons.check_circle : Icons.error,
                      color: _isSuccess ? Colors.green[700] : Colors.red[700],
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _resultMessage!,
                        style: TextStyle(
                          color:
                              _isSuccess ? Colors.green[700] : Colors.red[700],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            // Merge Results
            if (_mergeResults != null) ...[
              const SizedBox(height: 16),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Merge Results',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Divider(height: 20),
                      _buildResultRow(
                        'Updated',
                        _mergeResults!['updated']?.toString() ?? '0',
                        Colors.green,
                        Icons.check_circle,
                      ),
                      _buildResultRow(
                        'Inserted (New Items)',
                        _mergeResults!['inserted']?.toString() ?? '0',
                        Colors.blue,
                        Icons.add_circle,
                      ),
                      _buildResultRow(
                        'Not Found in Master',
                        _mergeResults!['notFound']?.toString() ?? '0',
                        Colors.orange,
                        Icons.warning,
                      ),
                      _buildResultRow(
                        'Failed',
                        _mergeResults!['failed']?.toString() ?? '0',
                        Colors.red,
                        Icons.error,
                      ),
                    ],
                  ),
                ),
              ),
            ],

            // Help Section
            const SizedBox(height: 32),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.help_outline, size: 20),
                        SizedBox(width: 8),
                        Text(
                          'How Merge Works',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _buildHelpItem(
                      '1. Existing Assets',
                      'Survey data updates master records',
                    ),
                    _buildHelpItem(
                      '2. New Items',
                      'Items marked as "New" are added to database',
                    ),
                    _buildHelpItem(
                      '3. Calculations',
                      'Excess/Shortage auto-calculated',
                    ),
                    _buildHelpItem(
                      '4. Timestamps',
                      'Last updated by and date are preserved',
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFormatItem(String text) {
    return Padding(
      padding: const EdgeInsets.only(left: 8, top: 4),
      child: Row(
        children: [
          Icon(Icons.check, size: 16, color: Colors.green[700]),
          const SizedBox(width: 8),
          Expanded(child: Text(text, style: const TextStyle(fontSize: 13))),
        ],
      ),
    );
  }

  Widget _buildResultRow(
      String label, String value, Color color, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 20, color: color),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(fontSize: 14),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              value,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHelpItem(String title, String description) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.arrow_right, size: 20, color: Colors.white70),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
