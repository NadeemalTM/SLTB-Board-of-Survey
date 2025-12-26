import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import '../../core/utils/csv_helper.dart';
import '../../data/database/database_helper.dart';

/// Import Master Screen - Upload and import master CSV data
class ImportMasterScreen extends ConsumerStatefulWidget {
  const ImportMasterScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<ImportMasterScreen> createState() =>
      _ImportMasterScreenState();
}

class _ImportMasterScreenState extends ConsumerState<ImportMasterScreen> {
  String? _selectedFilePath;
  bool _isLoading = false;
  String? _resultMessage;
  bool _isSuccess = false;

  Future<void> _pickFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['csv'],
    );

    if (result != null && result.files.single.path != null) {
      setState(() {
        _selectedFilePath = result.files.single.path;
        _resultMessage = null;
      });
    }
  }

  Future<void> _importData() async {
    if (_selectedFilePath == null) return;

    setState(() {
      _isLoading = true;
      _resultMessage = null;
    });

    try {
      // Validate CSV format
      final isValid = await CsvHelper.validateMasterCsv(_selectedFilePath!);

      if (!isValid) {
        setState(() {
          _isLoading = false;
          _isSuccess = false;
          _resultMessage = 'Invalid CSV format. Please check the file structure.';
        });
        return;
      }

      // Parse CSV
      final assets = await CsvHelper.parseMasterCsv(_selectedFilePath!);

      // Insert into database
      final db = DatabaseHelper.instance;
      await db.batchInsertFromMasterCsv(assets);

      setState(() {
        _isLoading = false;
        _isSuccess = true;
        _resultMessage =
            'Successfully imported ${assets.length} assets into database';
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
        title: const Text('Import Master Data'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Instructions Card
            Card(
              color: Colors.blue[50],
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.info, color: Colors.blue[700]),
                        const SizedBox(width: 8),
                        const Text(
                          'CSV Format Requirements',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'The master CSV file must contain these columns:',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 8),
                    _buildFormatItem('1. Serial No'),
                    _buildFormatItem('2. Description'),
                    _buildFormatItem('3. Old Code'),
                    _buildFormatItem('4. New Code (unique identifier)'),
                    _buildFormatItem('5. Book Balance'),
                    const SizedBox(height: 12),
                    Text(
                      '⚠️ Warning: Importing will replace existing master data',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.orange[800],
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
              'Select CSV File',
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

            // Import Button
            ElevatedButton.icon(
              onPressed: _selectedFilePath != null && !_isLoading
                  ? _importData
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
                  : const Icon(Icons.cloud_upload),
              label: Text(_isLoading ? 'Importing...' : 'Import Data'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                backgroundColor: Colors.blue[700],
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

            // Sample Format
            const SizedBox(height: 32),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.table_chart, size: 20),
                        SizedBox(width: 8),
                        Text(
                          'Sample CSV Format',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text(
                        'Serial No,Description,Old Code,New Code,Book Balance\n'
                        '1,Desktop Computer,OLD-001,NEW-001,5\n'
                        '2,Office Chair,OLD-002,NEW-002,20\n'
                        '3,Printer HP LaserJet,OLD-003,NEW-003,3',
                        style: TextStyle(
                          fontSize: 12,
                          fontFamily: 'monospace',
                        ),
                      ),
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
          Text(text, style: const TextStyle(fontSize: 13)),
        ],
      ),
    );
  }
}
