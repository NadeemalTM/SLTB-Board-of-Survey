import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import '../../services/firestore_service.dart';
import 'edit_asset_screen.dart';
import 'add_item_screen.dart';

/// Barcode Scanner Screen - Scan equipment barcodes for verification
class ScanScreen extends StatefulWidget {
  const ScanScreen({super.key});

  @override
  State<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends State<ScanScreen> {
  MobileScannerController cameraController = MobileScannerController(
    detectionSpeed: DetectionSpeed.unrestricted,
    detectionTimeoutMs: 100,
    facing: CameraFacing.back,
    formats: [
      BarcodeFormat.code128,
      BarcodeFormat.code39,
      BarcodeFormat.code93,
      BarcodeFormat.ean13,
      BarcodeFormat.ean8,
      BarcodeFormat.upcA,
      BarcodeFormat.upcE,
      BarcodeFormat.qrCode,
      BarcodeFormat.codabar,
      BarcodeFormat.itf,
      BarcodeFormat.dataMatrix,
      BarcodeFormat.pdf417,
    ],
  );
  bool _isProcessing = false;
  bool _hasPermission = true;
  double _zoomFactor = 0.0;
  final TextEditingController _manualCodeController = TextEditingController();

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
      await cameraController.stop();
      final firestore = FirestoreService();

      final doc = await firestore.getAsset(code);

      if (!mounted) return;

      if (doc.exists) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;

        Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => EditAssetScreen(data: data, docId: code)))
            .then((_) {
          cameraController.start();
        });
      } else {
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
          : Stack(
              children: [
                // Full-screen camera — NO scanWindow restriction for maximum detection
                MobileScanner(
                  controller: cameraController,
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

                // Visual guide overlay (not a detection constraint)
                Positioned.fill(
                  child: IgnorePointer(
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        final guideRect = Rect.fromCenter(
                          center: Offset(constraints.maxWidth / 2,
                              constraints.maxHeight / 2),
                          width: constraints.maxWidth * 0.85,
                          height: constraints.maxHeight * 0.15,
                        );
                        return CustomPaint(
                          painter: _ScanGuidePainter(guideRect: guideRect),
                        );
                      },
                    ),
                  ),
                ),

                // Instructions
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
                      child: const Text(
                        'Point camera at barcode',
                        style: TextStyle(color: Colors.white, fontSize: 14),
                      ),
                    ),
                  ),
                ),

                // Zoom Slider
                Positioned(
                  bottom: 120,
                  left: 24,
                  right: 24,
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.black54,
                      borderRadius: BorderRadius.circular(24),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Row(
                      children: [
                        const Icon(Icons.zoom_out, color: Colors.white),
                        Expanded(
                          child: Slider(
                            value: _zoomFactor,
                            activeColor: const Color(0xFF4CAF50),
                            inactiveColor: Colors.white54,
                            onChanged: (value) {
                              setState(() {
                                _zoomFactor = value;
                                cameraController.setZoomScale(value);
                              });
                            },
                          ),
                        ),
                        const Icon(Icons.zoom_in, color: Colors.white),
                      ],
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
            ),
    );
  }
}

/// Visual guide painter — shows a horizontal bar where the user should
/// align the barcode. This is only a UI hint, NOT a detection constraint.
class _ScanGuidePainter extends CustomPainter {
  final Rect guideRect;
  _ScanGuidePainter({required this.guideRect});

  @override
  void paint(Canvas canvas, Size size) {
    // Semi-transparent overlay
    final overlay = Paint()..color = Colors.black.withOpacity(0.4);
    final fullRect = Rect.fromLTWH(0, 0, size.width, size.height);
    final cutout = RRect.fromRectXY(guideRect, 12, 12);

    final path = Path()
      ..addRect(fullRect)
      ..addRRect(cutout);
    canvas.drawPath(
      Path.combine(PathOperation.difference, path, Path()..addRRect(cutout)),
      overlay,
    );

    // White border
    final border = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;
    canvas.drawRRect(cutout, border);

    // Green corner accents for a professional look
    final accent = Paint()
      ..color = const Color(0xFF4CAF50)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4.0
      ..strokeCap = StrokeCap.round;

    const cornerLen = 24.0;
    final r = guideRect;

    // Top-left
    canvas.drawLine(Offset(r.left, r.top + 12),
        Offset(r.left, r.top + 12 + cornerLen), accent);
    canvas.drawLine(Offset(r.left + 12, r.top),
        Offset(r.left + 12 + cornerLen, r.top), accent);
    // Top-right
    canvas.drawLine(Offset(r.right, r.top + 12),
        Offset(r.right, r.top + 12 + cornerLen), accent);
    canvas.drawLine(Offset(r.right - 12, r.top),
        Offset(r.right - 12 - cornerLen, r.top), accent);
    // Bottom-left
    canvas.drawLine(Offset(r.left, r.bottom - 12),
        Offset(r.left, r.bottom - 12 - cornerLen), accent);
    canvas.drawLine(Offset(r.left + 12, r.bottom),
        Offset(r.left + 12 + cornerLen, r.bottom), accent);
    // Bottom-right
    canvas.drawLine(Offset(r.right, r.bottom - 12),
        Offset(r.right, r.bottom - 12 - cornerLen), accent);
    canvas.drawLine(Offset(r.right - 12, r.bottom),
        Offset(r.right - 12 - cornerLen, r.bottom), accent);
  }

  @override
  bool shouldRepaint(covariant _ScanGuidePainter oldDelegate) {
    return oldDelegate.guideRect != guideRect;
  }
}
