import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:share_plus/share_plus.dart';
import '../../core/utils/csv_helper.dart';

import '../../data/models/asset_model.dart';
import '../../core/constants/survey_status.dart';

/// Export Report Screen - Generate and download survey reports
class ExportReportScreen extends ConsumerStatefulWidget {
  const ExportReportScreen({super.key});

  @override
  ConsumerState<ExportReportScreen> createState() =>
      _ExportReportScreenState();
}

class _ExportReportScreenState extends ConsumerState<ExportReportScreen> {
  bool _isExporting = false;
  String? _resultMessage;
  bool _isSuccess = false;

  String _selectedYear = 'All';
  List<String> _availableYears = ['All'];
  bool _isLoadingYears = true;

  String _selectedStatus = 'All';
  late final List<String> _availableStatuses;

  @override
  void initState() {
    super.initState();
    _availableStatuses = ['All', ...SurveyStatus.allValues];
    _loadAvailableYears();
  }

  Future<void> _loadAvailableYears() async {
    try {
      final snapshot = await FirebaseFirestore.instance.collectionGroup('assets').get();
      final assets = snapshot.docs.map((doc) {
        final data = doc.data();
        if (!data.containsKey('newCode')) {
          data['newCode'] = doc.id;
        }
        return AssetModel.fromFirestore(data);
      }).toList();

      final Set<String> years = {'2023', '2024', '2025', '2026'}; // Always include these base years
      for (var asset in assets) {
        if (asset.lastUpdatedDate != null && asset.lastUpdatedDate!.length >= 4) {
          years.add(asset.lastUpdatedDate!.substring(0, 4));
        } else if (asset.enteredDate != null && asset.enteredDate!.length >= 4) {
          years.add(asset.enteredDate!.substring(0, 4));
        }
      }
      final sortedYears = years.toList()..sort((a, b) => b.compareTo(a)); // Descending
      setState(() {
        _availableYears = ['All', ...sortedYears];
        _isLoadingYears = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingYears = false;
        });
      }
    }
  }

  Future<void> _exportReport() async {
    setState(() {
      _isExporting = true;
      _resultMessage = null;
    });

    try {
      List<AssetModel> assetsForExport = [];

      // Check if we are exporting historical Firebase data directly
      if (['2023', '2024'].contains(_selectedYear)) {
        final snapshot = await FirebaseFirestore.instance
            .collection('assets')
            .doc(_selectedYear)
            .collection('SLTB')
            .doc('BOS')
            .collection('MT')
            .get();

        assetsForExport = snapshot.docs.map((doc) {
          final data = doc.data();
          // Provide some standard mapping if historical data lacks newCode field, use ID
          if (!data.containsKey('newCode')) {
            data['newCode'] = doc.id; 
          }
          return AssetModel.fromFirestore(data);
        }).toList();
        
      } else {
        // Fetch directly from Firebase
        final snapshot = await FirebaseFirestore.instance.collectionGroup('assets').get();
        var assets = snapshot.docs.map((doc) {
          final data = doc.data();
          if (!data.containsKey('newCode')) {
            data['newCode'] = doc.id;
          }
          return AssetModel.fromFirestore(data);
        }).toList();

        if (_selectedYear != 'All') {
          assets = assets.where((asset) {
            final dateStr = asset.lastUpdatedDate ?? asset.enteredDate ?? '';
            return dateStr.startsWith(_selectedYear);
          }).toList();
        }
        assetsForExport = assets;
      }

      if (_selectedStatus != 'All') {
        assetsForExport = assetsForExport.where((asset) {
          final statusStr = asset.surveyStatus ?? 'Good';
          return statusStr.toLowerCase() == _selectedStatus.toLowerCase();
        }).toList();
      }

      if (assetsForExport.isEmpty) {
        setState(() {
          _isExporting = false;
          _isSuccess = false;
          _resultMessage = 'No data available to export';
        });
        return;
      }

      // Generate report CSV
      final csvContent = CsvHelper.generateAdminReportCsv(assetsForExport);

      // Export to Downloads folder
      final filePath = await CsvHelper.exportToDownloads(
        csvContent,
        'SLTB_Survey_Report_${_selectedYear}_${DateTime.now().millisecondsSinceEpoch}',
      );

      setState(() {
        _isExporting = false;
        _isSuccess = true;
        _resultMessage =
            'Successfully exported ${assetsForExport.length} records\n\nFile saved to:\n$filePath';
      });

      // Show system popup to easily check or share the report
      await Share.shareXFiles([XFile(filePath)], subject: 'SLTB Survey Report - $_selectedYear');
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
      // Fetch directly from Firebase
      final snapshot = await FirebaseFirestore.instance.collectionGroup('assets').get();
      var assets = snapshot.docs.map((doc) {
        final data = doc.data();
        if (!data.containsKey('newCode')) {
          data['newCode'] = doc.id;
        }
        return AssetModel.fromFirestore(data);
      }).toList();

      if (_selectedYear != 'All') {
        assets = assets.where((asset) {
          final dateStr = asset.lastUpdatedDate ?? asset.enteredDate ?? '';
          return dateStr.startsWith(_selectedYear);
        }).toList();
      }

      if (_selectedStatus != 'All') {
        assets = assets.where((asset) {
          final statusStr = asset.surveyStatus ?? 'Good';
          return statusStr.toLowerCase() == _selectedStatus.toLowerCase();
        }).toList();
      }

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

      // Show system popup to easily check or share the template
      await Share.shareXFiles([XFile(filePath)], subject: 'Field Officer Template - $officerUsername');
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
            // Filters Section
            Card(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                child: Column(
                  children: [
                    // Year Filter
                    Row(
                      children: [
                        const Icon(Icons.calendar_today, color: Colors.blue),
                        const SizedBox(width: 16),
                        const Expanded(
                          flex: 2,
                          child: Text(
                            'Filter by Year:',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        Expanded(
                          flex: 3,
                          child: _isLoadingYears 
                              ? const Align(
                                  alignment: Alignment.centerRight,
                                  child: SizedBox(
                                    height: 20, 
                                    width: 20, 
                                    child: CircularProgressIndicator(strokeWidth: 2)
                                  ),
                                ) 
                              : DropdownButton<String>(
                                  value: _selectedYear,
                                  isExpanded: true,
                                  underline: const SizedBox(),
                                  items: _availableYears.map((String year) {
                                    return DropdownMenuItem<String>(
                                      value: year,
                                      child: Text(year == 'All' ? 'All Years' : year),
                                    );
                                  }).toList(),
                                  onChanged: (String? newValue) {
                                    if (newValue != null) {
                                      setState(() {
                                        _selectedYear = newValue;
                                      });
                                    }
                                  },
                                ),
                        ),
                      ],
                    ),
                    const Divider(),
                    // Status Filter
                    Row(
                      children: [
                        Icon(Icons.assignment_turned_in, color: Colors.green[700]),
                        const SizedBox(width: 16),
                        const Expanded(
                          flex: 2,
                          child: Text(
                            'Filter by Status:',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        Expanded(
                          flex: 3,
                          child: DropdownButton<String>(
                            value: _selectedStatus,
                            isExpanded: true,
                            underline: const SizedBox(),
                            items: _availableStatuses.map((String status) {
                              return DropdownMenuItem<String>(
                                value: status,
                                child: Text(status == 'All' ? 'All Statuses' : status),
                              );
                            }).toList(),
                            onChanged: (String? newValue) {
                              if (newValue != null) {
                                setState(() {
                                  _selectedStatus = newValue;
                                });
                              }
                            },
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

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
                            color: const Color(0xFF0C3B2E),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.person,
                            size: 32,
                            color: Colors.white,
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
                        backgroundColor: const Color(0xFF0C3B2E),
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
