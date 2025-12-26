import 'package:flutter/material.dart';

/// Placeholder for Add Item Screen
/// TODO: Implement with form for adding new assets
class AddItemScreen extends StatelessWidget {
  const AddItemScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add New Item'),
      ),
      body: const Center(
        child: Text('Add item form implementation coming soon'),
      ),
    );
  }
}
