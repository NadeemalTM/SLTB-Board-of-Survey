import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
// import 'field_verification_screen.dart'; // REMOVED (Old)
import '../../services/firestore_service.dart';
import 'edit_asset_screen.dart'; // <--- ADDED
import 'add_item_screen.dart'; // <--- ADDED

/// Barcode Scanner Screen - Scan equipment barcodes for verification
class ScanScreen extends StatefulWidget {
  const ScanScreen({super.key});

  @override
  State<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends State<ScanScreen> {
  MobileScannerController cameraController = MobileScannerController(
    detectionSpeed: DetectionSpeed.normal,
    detectionTimeoutMs: 250,
  );
  bool _isProcessing = false;
  bool _hasPermission = true;
  final TextEditingController _manualCodeController = TextEditingController();
  // Optionally add more toggles if needed (e.g., format filters)

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
          const SnackBar(content: Text('Camera permission is required.')),
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

    setState(() => _isProcessing = true);

    try {
      // Pause camera to reduce background processing/log spam while navigating
      await cameraController.stop();
      final firestore = FirestoreService();

      // Check Firebase
      final doc = await firestore.getAsset(code);

      if (!mounted) return;

      if (doc.exists) {
        // --- CASE A: ITEM FOUND (VERIFY) ---
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;

        Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => EditAssetScreen(data: data, docId: code)))
            .then((_) {
          // Resume camera when returning to scan screen
          cameraController.start();
        });
      } else {
        // --- CASE B: NEW ITEM (ADD) ---
        Navigator.push(
            context,
            MaterialPageRoute(
                builder: (_) => AddItemScreen(scannedCode: code))).then((_) {
          cameraController.start();
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
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
            prefixIcon: Icon(Icons.qr_code),
            border: OutlineInputBorder(),
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              final code = _manualCodeController.text.trim();
              if (code.isNotEmpty) {
                Navigator.pop(context);
                _handleBarcode(code);
              }
            },
            child: const Text('Submit'),
          ),
        ],
      ),
    );
  }

  Future<void> _scanFromGallery() async {
    // Pick an image from gallery and analyze it
    try {
      // Lazy import to avoid web issues
      // ignore: avoid_dynamic_calls
      final picker = await Future.sync(() => ImagePicker());
      final image = await picker.pickImage(source: ImageSource.gallery);
      if (image == null) return;
      // In this mobile_scanner version, analyzeImage triggers onDetect
      // if a barcode is found; we don't receive a capture here.
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
        title: const Text('Scan Barcode'),
        actions: [
          IconButton(
            icon: ValueListenableBuilder(
              valueListenable: cameraController.torchState,
              builder: (context, state, child) {
                return Icon(
                    state == TorchState.off ? Icons.flash_off : Icons.flash_on);
              },
            ),
            onPressed: () => cameraController.toggleTorch(),
          ),
          IconButton(
            icon: const Icon(Icons.flip_camera_ios),
            onPressed: () => cameraController.switchCamera(),
          ),
          IconButton(
            tooltip: 'Scan from gallery',
            icon: const Icon(Icons.photo_library),
            onPressed: _scanFromGallery,
          ),
        ],
      ),
      body: !_hasPermission
          ? const Center(child: Text('Camera permission not granted'))
          : LayoutBuilder(
              builder: (context, constraints) {
                // Define a central scan window to improve detection stability
                final Rect scanWindow = Rect.fromCenter(
                  center:
                      Offset(constraints.maxWidth / 2, constraints.maxHeight / 2),
                  width: constraints.maxWidth * 0.8,
                  height: constraints.maxHeight * 0.28,
                );
                return Stack(
                  children: [
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
                // Overlay Text
                Positioned(
                  top: 24,
                  left: 16,
                  right: 16,
                  child: Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 24, vertical: 12),
                      decoration: BoxDecoration(
                          color: Colors.black54,
                          borderRadius: BorderRadius.circular(24)),
                      child: const Text('Point camera at barcode',
                          style: TextStyle(color: Colors.white)),
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
                // Manual Entry Button
                Positioned(
                  bottom: 40,
                  left: 24,
                  right: 24,
                  child: ElevatedButton.icon(
                    onPressed: _showManualEntryDialog,
                    icon: const Icon(Icons.keyboard),
                    label: const Text('Enter Barcode Manually'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      backgroundColor: const Color(0xFF0C3B2E),
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
                // Loading Spinner
                if (_isProcessing)
                  Container(
                    color: Colors.black54,
                    child: const Center(child: CircularProgressIndicator()),
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
    // Create a cutout effect
    canvas.drawPath(
      Path.combine(PathOperation.difference, path, Path()..addRRect(RRect.fromRectXY(scanWindow, 16, 16))),
      paint,
    );

    // Add white borders around the scan window
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
