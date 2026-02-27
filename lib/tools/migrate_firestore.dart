import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import '../services/firestore_service.dart';

// Minimal app to run one-time Firestore migration from flat collection
// to hierarchical structure. Run with:
// flutter run -t lib/tools/migrate_firestore.dart -d chrome
// or on any connected device/emulator.

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  final service = FirestoreService();
  debugPrint('Starting Firestore migration...');
  await service.migrateFlatToHierarchy(deleteSource: false);
  debugPrint('Migration completed.');

  runApp(const _DoneApp());
}

class _DoneApp extends StatelessWidget {
  const _DoneApp();

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      home: Scaffold(
        body: Center(
          child: Text('Firestore migration completed'),
        ),
      ),
    );
  }
}
