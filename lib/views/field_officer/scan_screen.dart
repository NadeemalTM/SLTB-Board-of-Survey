import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../../data/database/database_helper.dart';
import 'asset_detail_screen.dart';

/// Barcode Scanner Screen - Scan equipment barcodes
class ScanScreen extends StatefulWidget {
  const ScanScreen({Key? key}) : super(key: key);

  @override
  State<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends State<ScanScreen> {
  MobileScannerController cameraController = MobileScannerController();
  bool _isProcessing = false;

  @override
  void dispose() {
    cameraController.dispose();
    super.dispose();
  }

  Future<void> _handleBarcode(String code) async {
    if (_isProcessing) return;

    setState(() {
      _isProcessing = true;
    });

    try {
      // Query database for asset with this code
      final db = DatabaseHelper.instance;
      final asset = await db.getAssetByNewCode(code);

      if (asset != null && mounted) {
        // Navigate to asset detail
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => AssetDetailScreen(asset: asset),
          ),
        );
        
        // Return to dashboard after update
        if (mounted) {
          Navigator.pop(context);
        }
      } else if (mounted) {
        // Asset not found
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Asset not found: $code'),
            backgroundColor: Colors.orange,
            action: SnackBarAction(
              label: 'Dismiss',
              textColor: Colors.white,
              onPressed: () {},
            ),
          ),
        );
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
      setState(() {
        _isProcessing = false;
      });
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
            icon: ValueListenableBuilder(
              valueListenable: cameraController.cameraFacingState,
              builder: (context, state, child) {
                return const Icon(Icons.flip_camera_ios);
              },
            ),
            onPressed: () => cameraController.switchCamera(),
            tooltip: 'Switch Camera',
          ),
        ],
      ),
      body: Stack(
        children: [
          // Camera View
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

          // Scan Overlay
          Positioned.fill(
            child: CustomPaint(
              painter: ScannerOverlayPainter(),
            ),
          ),

          // Instructions
          Positioned(
            top: 24,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.7),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: const Text(
                  'Align barcode within frame',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                  ),
                  textAlign: TextAlign.center,
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
      ),
    );
  }
}

/// Scanner Overlay Painter - Draws scan frame
class ScannerOverlayPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final double scanAreaSize = size.width * 0.7;
    final Rect scanRect = Rect.fromCenter(
      center: Offset(size.width / 2, size.height / 2),
      width: scanAreaSize,
      height: scanAreaSize * 0.6,
    );

    // Draw dark overlay
    final Path overlayPath = Path()
      ..addRect(Rect.fromLTWH(0, 0, size.width, size.height))
      ..addRRect(RRect.fromRectAndRadius(scanRect, const Radius.circular(16)))
      ..fillType = PathFillType.evenOdd;

    canvas.drawPath(
      overlayPath,
      Paint()..color = Colors.black.withOpacity(0.5),
    );

    // Draw scan frame corners
    final Paint cornerPaint = Paint()
      ..color = Colors.blue
      ..strokeWidth = 4
      ..style = PaintingStyle.stroke;

    final double cornerLength = 30;

    // Top-left corner
    canvas.drawLine(
      scanRect.topLeft,
      scanRect.topLeft.translate(cornerLength, 0),
      cornerPaint,
    );
    canvas.drawLine(
      scanRect.topLeft,
      scanRect.topLeft.translate(0, cornerLength),
      cornerPaint,
    );

    // Top-right corner
    canvas.drawLine(
      scanRect.topRight,
      scanRect.topRight.translate(-cornerLength, 0),
      cornerPaint,
    );
    canvas.drawLine(
      scanRect.topRight,
      scanRect.topRight.translate(0, cornerLength),
      cornerPaint,
    );

    // Bottom-left corner
    canvas.drawLine(
      scanRect.bottomLeft,
      scanRect.bottomLeft.translate(cornerLength, 0),
      cornerPaint,
    );
    canvas.drawLine(
      scanRect.bottomLeft,
      scanRect.bottomLeft.translate(0, -cornerLength),
      cornerPaint,
    );

    // Bottom-right corner
    canvas.drawLine(
      scanRect.bottomRight,
      scanRect.bottomRight.translate(-cornerLength, 0),
      cornerPaint,
    );
    canvas.drawLine(
      scanRect.bottomRight,
      scanRect.bottomRight.translate(0, -cornerLength),
      cornerPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
