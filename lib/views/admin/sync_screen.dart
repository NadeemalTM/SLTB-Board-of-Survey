import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import '../../data/database/database_helper.dart';
import '../../data/models/asset_model.dart'; // Ensure this path is correct
import 'package:flutter/foundation.dart'; // Needed for kIsWeb

class SyncScreen extends StatefulWidget {
  const SyncScreen({Key? key}) : super(key: key);

  @override
  State<SyncScreen> createState() => _SyncScreenState();
}

class _SyncScreenState extends State<SyncScreen> {
  bool _isLoading = false;
  String _statusMessage = "Ready to Sync";

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Sync Data")),
      body: Center(
        child: _isLoading
            ? const CircularProgressIndicator()
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Text(
                      _statusMessage,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: _statusMessage.contains("Success") ? Colors.green : Colors.black54),
                    ),
                  ),
                  const SizedBox(height: 30),
                  
                  // DOWNLOAD BUTTON
                  ElevatedButton.icon(
                    icon: const Icon(Icons.download),
                    label: const Text("DOWNLOAD FROM SERVER"),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 20),
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                    ),
                    onPressed: _downloadData,
                  ),
                  
                  const SizedBox(height: 20),

                  // UPLOAD BUTTON
                  ElevatedButton.icon(
                    icon: const Icon(Icons.upload),
                    label: const Text("UPLOAD CHANGES"),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 20),
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                    ),
                    onPressed: _uploadData,
                  ),
                ],
              ),
      ),
    );
  }

  Future<void> _downloadData() async {
    setState(() { _isLoading = true; _statusMessage = "Downloading..."; });

    try {
      final assets = await ApiService.fetchAllAssets();
      await DatabaseHelper.instance.clearAllAssets();
      
      for (var json in assets) {
        // We convert JSON to AssetModel and save
        // Make sure your AssetModel.fromJson handles the fields correctly
        // If fromJson doesn't exist, use fromMap or manual creation
        await DatabaseHelper.instance.insertAsset(AssetModel.fromMap(json));
      }

      setState(() => _statusMessage = "Success! Downloaded ${assets.length} items.");
    } catch (e) {
      setState(() => _statusMessage = "Error: $e");
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _uploadData() async {
    setState(() { _isLoading = true; _statusMessage = "Uploading..."; });

    try {
      final unsynced = await DatabaseHelper.instance.getUnsyncedAssets();
      
      if (unsynced.isEmpty) {
        setState(() => _statusMessage = "No changes to upload.");
        return;
      }

      // Convert List<AssetModel> to List<Map>
      final List<Map<String, dynamic>> jsonList = unsynced.map((a) => a.toMap()).toList();
      
      final success = await ApiService.uploadChanges(jsonList);

      if (success) {
        await DatabaseHelper.instance.markAsSynced();
        setState(() => _statusMessage = "Success! Uploaded ${unsynced.length} items.");
      } else {
        setState(() => _statusMessage = "Upload Failed.");
      }
    } catch (e) {
      setState(() => _statusMessage = "Error: $e");
    } finally {
      setState(() => _isLoading = false);
    }
  }
}