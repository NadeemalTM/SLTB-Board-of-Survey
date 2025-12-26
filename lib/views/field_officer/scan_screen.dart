import 'package:flutter/material.dart';

/// Placeholder for Scan Screen
/// TODO: Implement with mobile_scanner package
class ScanScreen extends StatelessWidget {
  const ScanScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Scan Barcode'),
      ),
      body: const Center(
        child: Text('Scanner implementation coming soon'),
      ),
    );
  }
}
