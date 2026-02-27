import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import '../../data/database/database_helper.dart';
import 'region_asset_entry_screen.dart';

/// Barcode Scanner Screen for Regional Officers
/// Regional officers scan barcodes to enter/update asset data
class RegionScanScreen extends StatefulWidget {
  const RegionScanScreen({super.key});

  @override
  State<RegionScanScreen> createState() => _RegionScanScreenState();
}

class _RegionScanScreenState extends State<RegionScanScreen> {
  MobileScannerController cameraController = MobileScannerController(
    detectionSpeed: DetectionSpeed.normal,
    detectionTimeoutMs: 250,
  );
  bool _isProcessing = false;
  bool _hasPermission = true;
  final TextEditingController _manualCodeController = TextEditingController();
  // Additional toggles can be added here if needed

  @override
  void initState() {
    super.initState();
    _ensurePermission();
  }

  Future<void> _ensurePermission() async {
    if (kIsWeb) return;
    final status = await Permission.camera.status;
    if (!status.isGranted) {
      final result = await Permission.camera.request();
      setState(() => _hasPermission = result.isGranted);
      if (!result.isGranted && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Camera permission is required to scan barcodes.'),
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    cameraController.dispose();
    _manualCodeController.dispose();
    super.dispose();
  }

  Future<void> _handleBarcode(String code) async {
    if (_isProcessing) return;

    setState(() {
      _isProcessing = true;
    });

    try {
      // Check if running on web
      if (kIsWeb) {
        // On web, just navigate to entry screen without database lookup
        if (mounted) {
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => RegionAssetEntryScreen(
                scannedCode: code,
              ),
            ),
          );
          if (mounted) {
            Navigator.pop(context);
          }
        }
        return;
      }

      // Query database for asset with this code (mobile only)
      final db = DatabaseHelper.instance;
      final asset = await db.getAssetByNewCode(code);

      if (mounted) {
        if (asset != null) {
          // Asset found - navigate to edit screen
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => RegionAssetEntryScreen(
                asset: asset,
                scannedCode: code,
              ),
            ),
          );
        } else {
          // Asset not found - create new entry
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => RegionAssetEntryScreen(
                scannedCode: code,
              ),
            ),
          );
        }

        // Return to dashboard after update
        if (mounted) {
          Navigator.pop(context);
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
      }
    }
  }

  void _showManualEntryDialog() {
    _manualCodeController.clear();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Enter Barcode Manually'),
        content: TextField(
          controller: _manualCodeController,
          decoration: const InputDecoration(
            labelText: 'Barcode Number',
            hintText: 'Type the barcode number',
            prefixIcon: Icon(Icons.qr_code),
            border: OutlineInputBorder(),
          ),
          autofocus: true,
          keyboardType: TextInputType.text,
          textCapitalization: TextCapitalization.characters,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final code = _manualCodeController.text.trim();
              if (code.isNotEmpty) {
                Navigator.pop(context);
                _handleBarcode(code);
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Please enter a barcode number'),
                  ),
                );
              }
            },
            child: const Text('Submit'),
          ),
        ],
      ),
    );
  }

  Future<void> _scanFromGallery() async {
    try {
      final picker = await Future.sync(() => ImagePicker());
      final image = await picker.pickImage(source: ImageSource.gallery);
      if (image == null) return;
      await cameraController.analyzeImage(image.path);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Analyzing selected image...')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Image scan failed: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Scan Asset Barcode'),
        actions: [
          IconButton(
            icon: ValueListenableBuilder(
              valueListenable: cameraController.torchState,
              builder: (context, state, child) {
                switch (state) {
                  case TorchState.off:
                    return const Icon(Icons.flash_off);
                  case TorchState.on:
                    return const Icon(Icons.flash_on);
                }
              },
            ),
            onPressed: () => cameraController.toggleTorch(),
            tooltip: 'Toggle Flash',
          ),
          IconButton(
            icon: const Icon(Icons.flip_camera_ios),
            onPressed: () => cameraController.switchCamera(),
            tooltip: 'Switch Camera',
          ),
          IconButton(
            tooltip: 'Scan from gallery',
            icon: const Icon(Icons.photo_library),
            onPressed: _scanFromGallery,
          ),
        ],
      ),
      body: !_hasPermission
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Camera permission not granted'),
                  const SizedBox(height: 8),
                  ElevatedButton(
                    onPressed: () async {
                      await openAppSettings();
                    },
                    child: const Text('Open Settings'),
                  ),
                ],
              ),
            )
          : LayoutBuilder(
              builder: (context, constraints) {
                final Rect scanWindow = Rect.fromCenter(
                  center:
                      Offset(constraints.maxWidth / 2, constraints.maxHeight / 2),
                  width: constraints.maxWidth * 0.8,
                  height: constraints.maxHeight * 0.28,
                );
                return Stack(
                  children: [
                    // Camera view with central scan window
                    MobileScanner(
                      controller: cameraController,
                      scanWindow: scanWindow,
                      onDetect: (capture) {
                        final List<Barcode> barcodes = capture.barcodes;
                        if (barcodes.isNotEmpty && !_isProcessing) {
                          final code = barcodes.first.rawValue;
                          if (code != null && code.isNotEmpty) {
                            _handleBarcode(code);
                          }
                        }
                      },
                    ),

                // Instructions at top
                Positioned(
                  top: 24,
                  left: 16,
                  right: 16,
                  child: Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.6),
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: const Text(
                        'Point camera at barcode to scan',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                ),

                // Scan window overlay mask
                Positioned.fill(
                  child: IgnorePointer(
                    child: CustomPaint(
                      painter: _ScanWindowPainter(scanWindow: scanWindow),
                    ),
                  ),
                ),

                // Manual Entry Button at bottom
                Positioned(
                  bottom: 40,
                  left: 24,
                  right: 24,
                  child: ElevatedButton.icon(
                    onPressed: _showManualEntryDialog,
                    icon: const Icon(Icons.keyboard),
                    label: const Text('Enter Barcode Manually'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0C3B2E),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 16,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),

                // Processing Indicator
                if (_isProcessing)
                  Container(
                    color: Colors.black.withOpacity(0.5),
                    child: const Center(
                      child: Card(
                        child: Padding(
                          padding: EdgeInsets.all(24),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              CircularProgressIndicator(),
                              SizedBox(height: 16),
                              Text('Loading asset...'),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  ],
                );
              },
            ),
    );
  }
}

class _ScanWindowPainter extends CustomPainter {
  final Rect scanWindow;
  _ScanWindowPainter({required this.scanWindow});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.black54;
    final path = Path()
      ..addRect(Rect.fromLTWH(0, 0, size.width, size.height))
      ..addRRect(RRect.fromRectXY(scanWindow, 16, 16));
    canvas.drawPath(
      Path.combine(PathOperation.difference, path, Path()..addRRect(RRect.fromRectXY(scanWindow, 16, 16))),
      paint,
    );

    final border = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;
    canvas.drawRRect(RRect.fromRectXY(scanWindow, 16, 16), border);
  }

  @override
  bool shouldRepaint(covariant _ScanWindowPainter oldDelegate) {
    return oldDelegate.scanWindow != scanWindow;
  }
}
