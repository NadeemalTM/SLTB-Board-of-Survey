import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/utils/csv_helper.dart';
import '../../data/database/database_helper.dart';

/// Export Report Screen - Generate and download survey reports
class ExportReportScreen extends ConsumerStatefulWidget {
  const ExportReportScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<ExportReportScreen> createState() =>
      _ExportReportScreenState();
}

class _ExportReportScreenState extends ConsumerState<ExportReportScreen> {
  bool _isExporting = false;
  String? _resultMessage;
  bool _isSuccess = false;

  Future<void> _exportReport() async {
    setState(() {
      _isExporting = true;
      _resultMessage = null;
    });

    try {
      // Get all assets from database
      final db = DatabaseHelper.instance;
      final assets = await db.getAssetsFiltered();

      if (assets.isEmpty) {
        setState(() {
          _isExporting = false;
          _isSuccess = false;
          _resultMessage = 'No data available to export';
        });
        return;
      }

      // Generate report CSV
      final csvContent = CsvHelper.generateAdminReportCsv(assets);

      // Export to Downloads folder
      final filePath = await CsvHelper.exportToDownloads(
        csvContent,
        'SLTB_Survey_Report_${DateTime.now().millisecondsSinceEpoch}',
      );

      setState(() {
        _isExporting = false;
        _isSuccess = true;
        _resultMessage =
            'Successfully exported ${assets.length} records\n\nFile saved to:\n$filePath';
      });
    } catch (e) {
      setState(() {
        _isExporting = false;
        _isSuccess = false;
        _resultMessage = 'Error: ${e.toString()}';
      });
    }
  }

  Future<void> _exportFieldOfficerTemplate(String officerUsername) async {
    setState(() {
      _isExporting = true;
      _resultMessage = null;
    });

    try {
      final db = DatabaseHelper.instance;
      
      // Get all assets (for field officer to survey)
      final assets = await db.getAssetsFiltered();

      if (assets.isEmpty) {
        setState(() {
          _isExporting = false;
          _isSuccess = false;
          _resultMessage = 'No assets available for field work';
        });
        return;
      }

      // Generate field officer CSV
      final csvContent = CsvHelper.generateFieldOfficerCsv(assets);

      // Export to Downloads
      final filePath = await CsvHelper.exportToDownloads(
        csvContent,
        'Field_Officer_${officerUsername}_${DateTime.now().millisecondsSinceEpoch}',
      );

      setState(() {
        _isExporting = false;
        _isSuccess = true;
        _resultMessage =
            'Successfully exported ${assets.length} assets for field work\n\nFile saved to:\n$filePath';
      });
    } catch (e) {
      setState(() {
        _isExporting = false;
        _isSuccess = false;
        _resultMessage = 'Error: ${e.toString()}';
      });
    }
  }

  void _showFieldOfficerDialog() {
    final List<String> officers = List.generate(
      10,
      (index) => 'officer${(index + 1).toString().padLeft(2, '0')}',
    );

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select Field Officer'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: officers.length,
            itemBuilder: (context, index) {
              final officer = officers[index];
              return ListTile(
                leading: CircleAvatar(
                  child: Text('${index + 1}'),
                ),
                title: Text(officer.toUpperCase()),
                subtitle: Text('Field Officer ${index + 1}'),
                onTap: () {
                  Navigator.pop(context);
                  _exportFieldOfficerTemplate(officer);
                },
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Export Reports'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Admin Report Export
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.green[100],
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            Icons.table_chart,
                            size: 32,
                            color: Colors.green[700],
                          ),
                        ),
                        const SizedBox(width: 16),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Full Survey Report',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              SizedBox(height: 4),
                              Text(
                                'Export complete survey data with all fields',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.grey,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Includes:',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 8),
                    _buildIncludesItem('All asset details and codes'),
                    _buildIncludesItem('Book vs Physical balance'),
                    _buildIncludesItem('Excess/Shortage calculations'),
                    _buildIncludesItem('Survey status and remarks'),
                    _buildIncludesItem('Image paths and timestamps'),
                    const SizedBox(height: 20),
                    ElevatedButton.icon(
                      onPressed: _isExporting ? null : _exportReport,
                      icon: _isExporting
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor:
                                    AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : const Icon(Icons.download),
                      label: Text(_isExporting
                          ? 'Exporting...'
                          : 'Export Survey Report'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        backgroundColor: Colors.green[700],
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Field Officer Template Export
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.blue[100],
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            Icons.person,
                            size: 32,
                            color: Colors.blue[700],
                          ),
                        ),
                        const SizedBox(width: 16),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Field Officer Template',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              SizedBox(height: 4),
                              Text(
                                'Generate CSV template for field officers',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.grey,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Purpose:',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 8),
                    _buildIncludesItem('Pre-filled with master data'),
                    _buildIncludesItem('Ready for field survey work'),
                    _buildIncludesItem('Officer can update physical balance'),
                    _buildIncludesItem('Add photos, remarks, and status'),
                    const SizedBox(height: 20),
                    ElevatedButton.icon(
                      onPressed: _isExporting ? null : _showFieldOfficerDialog,
                      icon: const Icon(Icons.person_add),
                      label: const Text('Generate for Field Officer'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        backgroundColor: Colors.blue[700],
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ],
                ),
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
                  crossAxisAlignment: CrossAxisAlignment.start,
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

            // Info Card
            const SizedBox(height: 32),
            Card(
              color: Colors.amber[50],
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.info, color: Colors.amber[900]),
                        const SizedBox(width: 8),
                        const Text(
                          'Export Information',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      '• Files are saved to your device\'s Downloads folder\n'
                      '• Filename includes timestamp for easy identification\n'
                      '• CSV format compatible with Excel and Google Sheets\n'
                      '• Field officer templates can be edited and re-imported',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey[800],
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

  Widget _buildIncludesItem(String text) {
    return Padding(
      padding: const EdgeInsets.only(left: 8, top: 4),
      child: Row(
        children: [
          Icon(Icons.check_circle, size: 16, color: Colors.green[700]),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }
}
