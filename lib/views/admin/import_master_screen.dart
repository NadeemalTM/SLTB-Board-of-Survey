import 'dart:convert';
import 'dart:io';
import 'package:csv/csv.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import '../../services/firestore_service.dart';
import '../../widgets/region_selector.dart';

class ImportMasterScreen extends StatefulWidget {
  const ImportMasterScreen({super.key});

  @override
  State<ImportMasterScreen> createState() => _ImportMasterScreenState();
}

class _ImportMasterScreenState extends State<ImportMasterScreen> {
  bool _isImporting = false;
  String _statusMessage = "Ready to import.";
  double _progress = 0.0;
  
  // Dropdown selection
  String _selectedMain = "";
  String _selectedSub = "";

  Future<void> _pickAndImport() async {
    // Validate Selection
    if (_selectedMain.isEmpty || _selectedSub.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select both Region and Sub-Region.')),
      );
      return;
    }

    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['csv'],
        allowMultiple: false,
      );

      if (result == null) return;

      setState(() {
        _isImporting = true;
        _statusMessage = "Reading file...";
        _progress = 0.1;
      });

      String csvContent;
      if (kIsWeb) {
        final bytes = result.files.first.bytes;
        if (bytes == null) throw "Empty file";
        csvContent = utf8.decode(bytes);
      } else {
        final file = File(result.files.single.path!);
        csvContent = await file.readAsString();
      }

      // Pass the separate regions to the processor
      await _processCsvData(csvContent, _selectedMain, _selectedSub);

    } catch (e) {
      setState(() {
        _isImporting = false;
        _statusMessage = "Error: $e";
      });
    }
  }

  // Updated to accept main and sub regions separately
  Future<void> _processCsvData(String csvString, String mainReg, String subReg) async {
    final firestore = FirestoreService();
    List<List<dynamic>> rows = const CsvToListConverter(eol: '\n').convert(csvString);

    if (rows.isEmpty) {
      setState(() => _statusMessage = "File is empty.");
      return;
    }

    int total = rows.length;
    int current = 0;
    int successCount = 0;

    for (int i = 1; i < rows.length; i++) {
      var row = rows[i];
      current++;
      setState(() {
        _progress = current / total;
        _statusMessage = "Uploading item $current of $total...";
      });

      try {
        if (row.length < 6) continue;

        String newCode = row[4].toString().trim();
        if (newCode.isEmpty || newCode.toLowerCase().contains('new code')) continue;
        String oldCode = row[3].toString().trim();
        String description = row[2].toString().trim().replaceAll('"', '');

        int bookBalance = 0;
        var balanceRaw = row[5];
        if (balanceRaw is int) {
          bookBalance = balanceRaw;
        } else if (balanceRaw is double) bookBalance = balanceRaw.toInt();
        else if (balanceRaw is String) bookBalance = int.tryParse(balanceRaw) ?? 0;

        await firestore.addAsset(
          newCode: newCode,
          oldCode: oldCode,
          description: description,
          
          mainRegion: mainReg, // <--- SEPARATE FIELD
          subRegion: subReg,   // <--- SEPARATE FIELD
          
          bookBalance: bookBalance,
          physicalBalance: 0,
          status: 'Pending',
          imagePaths: [],
        );
        successCount++;
      } catch (e) {
        debugPrint("Error on row $i: $e");
      }
    }

    setState(() {
      _isImporting = false;
      _statusMessage = "Success! Imported $successCount items.";
      _progress = 1.0;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Import Master Data")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            const Icon(Icons.upload_file, size: 80, color: Colors.blue),
            const SizedBox(height: 24),
            const Text("Import Old Database", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            
            // --- DROPDOWN WIDGET ---
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey),
                borderRadius: BorderRadius.circular(12),
              ),
              child: RegionSelector(
                onSelectionChanged: (main, sub) {
                  setState(() {
                    _selectedMain = main;
                    _selectedSub = sub;
                  });
                },
              ),
            ),
            
            const SizedBox(height: 40),
            
            if (_isImporting) ...[
              LinearProgressIndicator(value: _progress),
              const SizedBox(height: 16),
              Text(_statusMessage),
            ] else ...[
              ElevatedButton.icon(
                onPressed: _pickAndImport,
                icon: const Icon(Icons.file_open),
                label: const Text("Select CSV File"),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                  backgroundColor: const Color(0xFF0C3B2E),
                  foregroundColor: Colors.white,
                ),
              ),
            ]
          ],
        ),
      ),
    );
  }
}