import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:io';
import '../../data/models/asset_model.dart';
import 'field_verification_screen.dart';

/// Verified Items Screen - Shows all verified/confirmed assets with thumbnails
class VerifiedItemsScreen extends StatefulWidget {
  const VerifiedItemsScreen({super.key});

  @override
  State<VerifiedItemsScreen> createState() => _VerifiedItemsScreenState();
}

class _VerifiedItemsScreenState extends State<VerifiedItemsScreen> {
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
        print('[VerifiedItems] Flat query failed: $e');
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
        print('[VerifiedItems] CollectionGroup query failed: $e');
      }

      // Filter: show only verified/confirmed items
      _items = allItems.where((a) {
        final approvalStatus = a.verificationStatus?.toLowerCase() ?? 'pending';

        // Include if approvalStatus contains 'verified' or 'approved'
        if (approvalStatus.contains('verified') ||
            approvalStatus.contains('approved')) {
          return true;
        }

        // Include if a field officer has verified it
        if (a.verifiedBy != null && a.verifiedBy!.isNotEmpty) {
          return true;
        }

        return false;
      }).toList();

      print(
          '[VerifiedItems] Total: ${allItems.length}, Verified: ${_items.length}');
    } catch (e) {
      print('[VerifiedItems] ERROR: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _refresh() async => _load();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Verified Items (${_loading ? '...' : _items.length})'),
        actions: [
          IconButton(onPressed: _refresh, icon: const Icon(Icons.refresh)),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _items.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.check_circle_outline,
                          size: 64, color: Colors.grey[400]),
                      const SizedBox(height: 16),
                      Text(
                        'No verified items yet',
                        style: TextStyle(
                          fontSize: 18,
                          color: Colors.grey[400],
                        ),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _refresh,
                  child: ListView.builder(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    itemCount: _items.length,
                    itemBuilder: (context, index) {
                      final asset = _items[index];
                      return _buildVerifiedAssetCard(asset);
                    },
                  ),
                ),
    );
  }

  Widget _buildVerifiedAssetCard(AssetModel asset) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      child: InkWell(
        onTap: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => FieldOfficerVerificationScreen(asset: asset),
            ),
          );
          _refresh();
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              // Thumbnail image
              _buildThumbnail(asset),
              const SizedBox(width: 12),

              // Asset details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Code
                    Text(
                      asset.newCode,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 3),

                    // Description
                    Text(
                      asset.description,
                      style: TextStyle(
                        color: Colors.grey[500],
                        fontSize: 13,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),

                    // Status & verified by info
                    Row(
                      children: [
                        // Status chip
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: Colors.green.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                                color: Colors.green.withOpacity(0.3)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.check_circle,
                                  size: 14, color: Colors.green),
                              const SizedBox(width: 4),
                              Text(
                                asset.surveyStatus ?? 'Verified',
                                style: const TextStyle(
                                  color: Colors.green,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),

                        // Verified by
                        if (asset.verifiedBy != null &&
                            asset.verifiedBy!.isNotEmpty)
                          Expanded(
                            child: Text(
                              'by ${asset.verifiedBy}',
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.grey[500],
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),

              // Arrow
              Icon(Icons.chevron_right, color: Colors.grey[400]),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildThumbnail(AssetModel asset) {
    // Prefer cloud URL (works across devices), fallback to local path
    final cloudUrl = asset.photoUrl1 ?? asset.photoUrl2 ?? asset.photoUrl3;
    final localPath = asset.imagePath1 ?? asset.imagePath2 ?? asset.imagePath3;

    return Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        color: const Color(0xFF1A3A2E),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFF2A5A4E), width: 1),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(7),
        child: _buildImageWidget(cloudUrl, localPath),
      ),
    );
  }

  Widget _buildImageWidget(String? cloudUrl, String? localPath) {
    // Try cloud URL first
    if (cloudUrl != null && cloudUrl.startsWith('http')) {
      return Image.network(
        cloudUrl,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          // Fallback to local file if network fails
          if (localPath != null &&
              localPath.isNotEmpty &&
              !localPath.startsWith('http')) {
            return Image.file(
              File(localPath),
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => _buildPlaceholderIcon(),
            );
          }
          return _buildPlaceholderIcon();
        },
      );
    }

    // Try local path
    if (localPath != null && localPath.isNotEmpty) {
      if (localPath.startsWith('http')) {
        return Image.network(
          localPath,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => _buildPlaceholderIcon(),
        );
      }
      return Image.file(
        File(localPath),
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _buildPlaceholderIcon(),
      );
    }

    return _buildPlaceholderIcon();
  }

  Widget _buildPlaceholderIcon() {
    return const Center(
      child: Icon(
        Icons.inventory_2,
        color: Colors.white54,
        size: 28,
      ),
    );
  }
}
