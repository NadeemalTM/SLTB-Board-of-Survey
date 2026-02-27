import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../data/models/asset_model.dart';
import '../../providers/auth_provider.dart';
import 'field_verification_screen.dart';
import 'widgets/asset_list_item.dart';

/// Lists assets with pending verification from Firebase Firestore
class PendingVerificationListScreen extends ConsumerStatefulWidget {
  const PendingVerificationListScreen({super.key});

  @override
  ConsumerState<PendingVerificationListScreen> createState() =>
      _PendingVerificationListScreenState();
}

class _PendingVerificationListScreenState
    extends ConsumerState<PendingVerificationListScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  List<AssetModel> _items = [];
  bool _loading = true;

  String get _currentCollectionName {
    final String currentYear = DateTime.now().year.toString();
    return 'survey_$currentYear';
  }

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      List<AssetModel> allItems = [];

      // 1. Flat collection: survey_YEAR/{docId}
      try {
        final flatSnapshot =
            await _firestore.collection(_currentCollectionName).get();
        for (final doc in flatSnapshot.docs) {
          final data = doc.data();
          allItems.add(AssetModel.fromFirestore(data));
        }
      } catch (e) {
        print('[PendingVerification] Flat query failed: $e');
      }

      // 2. Hierarchical: collectionGroup('assets')
      try {
        final hierarchicalSnapshot =
            await _firestore.collectionGroup('assets').get();
        for (final doc in hierarchicalSnapshot.docs) {
          final data = doc.data();
          allItems.add(AssetModel.fromFirestore(data));
        }
      } catch (e) {
        print('[PendingVerification] CollectionGroup query failed: $e');
      }

      // Filter: show items that are NOT verified/confirmed by any officer
      _items = allItems.where((a) {
        final approvalStatus = a.verificationStatus?.toLowerCase() ?? 'pending';

        // Exclude if approvalStatus contains 'verified' or 'approved'
        if (approvalStatus.contains('verified') ||
            approvalStatus.contains('approved')) {
          return false;
        }

        // Exclude if a field officer has already verified it
        if (a.verifiedBy != null && a.verifiedBy!.isNotEmpty) {
          return false;
        }

        return true;
      }).toList();

      print(
          '[PendingVerification] Total: ${allItems.length}, Pending: ${_items.length}');
    } catch (e) {
      print('[PendingVerification] ERROR: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _refresh() async => _load();

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pending Verification'),
        actions: [
          IconButton(onPressed: _refresh, icon: const Icon(Icons.refresh)),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _items.isEmpty
              ? const Center(child: Text('No pending items'))
              : RefreshIndicator(
                  onRefresh: _refresh,
                  child: ListView.builder(
                    physics: const AlwaysScrollableScrollPhysics(),
                    itemCount: _items.length,
                    itemBuilder: (context, index) {
                      final asset = _items[index];
                      return AssetListItem(
                        asset: asset,
                        onTap: () async {
                          final result = await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                                  FieldOfficerVerificationScreen(asset: asset),
                            ),
                          );
                          if (result == true) _refresh();
                        },
                      );
                    },
                  ),
                ),
    );
  }
}
