import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../data/models/asset_model.dart';
import '../field_officer/field_verification_screen.dart';

/// Asset Search Screen — Search and filter all assets
/// Supports search by barcode, description, and filter by status
class AssetSearchScreen extends StatefulWidget {
  const AssetSearchScreen({super.key});

  @override
  State<AssetSearchScreen> createState() => _AssetSearchScreenState();
}

class _AssetSearchScreenState extends State<AssetSearchScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();

  List<AssetModel> _allItems = [];
  List<AssetModel> _filteredItems = [];
  bool _loading = true;
  String _selectedFilter = 'All';

  final List<String> _filterOptions = [
    'All',
    'Good',
    'Broken',
    'Missing',
    'Verified',
    'Pending',
  ];

  String get _currentCollectionName {
    final String currentYear = DateTime.now().year.toString();
    return 'survey_$currentYear';
  }

  @override
  void initState() {
    super.initState();
    _loadAllItems();
    _searchController.addListener(_applyFilters);
  }

  @override
  void dispose() {
    _searchController.removeListener(_applyFilters);
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  Future<void> _loadAllItems() async {
    setState(() => _loading = true);
    try {
      List<AssetModel> allItems = [];

      // 1. Flat collection
      try {
        final flatSnapshot =
            await _firestore.collection(_currentCollectionName).get();
        for (final doc in flatSnapshot.docs) {
          final data = doc.data();
          allItems.add(AssetModel.fromFirestore(data));
        }
      } catch (e) {
        print('[Search] Flat query failed: $e');
      }

      // 2. Hierarchical
      try {
        final hierarchicalSnapshot =
            await _firestore.collectionGroup('assets').get();
        for (final doc in hierarchicalSnapshot.docs) {
          final data = doc.data();
          allItems.add(AssetModel.fromFirestore(data));
        }
      } catch (e) {
        print('[Search] CollectionGroup query failed: $e');
      }

      _allItems = allItems;
      _applyFilters();
    } catch (e) {
      print('[Search] ERROR: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _applyFilters() {
    final query = _searchController.text.trim().toLowerCase();

    setState(() {
      _filteredItems = _allItems.where((asset) {
        // Text search — match barcode OR description
        bool matchesSearch = true;
        if (query.isNotEmpty) {
          final matchesCode = asset.newCode.toLowerCase().contains(query);
          final matchesOldCode =
              (asset.oldCode ?? '').toLowerCase().contains(query);
          final matchesDescription =
              asset.description.toLowerCase().contains(query);
          final matchesRemarks =
              (asset.remarks ?? '').toLowerCase().contains(query);
          matchesSearch = matchesCode ||
              matchesOldCode ||
              matchesDescription ||
              matchesRemarks;
        }

        // Status filter
        bool matchesFilter = true;
        if (_selectedFilter != 'All') {
          switch (_selectedFilter) {
            case 'Good':
              matchesFilter =
                  (asset.surveyStatus ?? '').toLowerCase() == 'good';
              break;
            case 'Broken':
              matchesFilter =
                  (asset.surveyStatus ?? '').toLowerCase() == 'broken';
              break;
            case 'Missing':
              matchesFilter =
                  (asset.surveyStatus ?? '').toLowerCase() == 'missing';
              break;
            case 'Verified':
              final approval = (asset.verificationStatus ?? '').toLowerCase();
              matchesFilter = approval.contains('verified') ||
                  approval.contains('approved') ||
                  (asset.verifiedBy != null && asset.verifiedBy!.isNotEmpty);
              break;
            case 'Pending':
              final approval = (asset.verificationStatus ?? '').toLowerCase();
              matchesFilter = !approval.contains('verified') &&
                  !approval.contains('approved') &&
                  (asset.verifiedBy == null || asset.verifiedBy!.isEmpty);
              break;
          }
        }

        return matchesSearch && matchesFilter;
      }).toList();
    });
  }

  Color _getFilterColor(String filter) {
    switch (filter) {
      case 'All':
        return const Color(0xFF0C3B2E);
      case 'Good':
        return Colors.green;
      case 'Broken':
        return Colors.orange;
      case 'Missing':
        return Colors.red;
      case 'Verified':
        return Colors.teal;
      case 'Pending':
        return Colors.amber.shade700;
      default:
        return Colors.grey;
    }
  }

  IconData _getStatusIcon(String? status) {
    switch ((status ?? '').toLowerCase()) {
      case 'good':
        return Icons.check_circle;
      case 'broken':
        return Icons.broken_image;
      case 'missing':
        return Icons.cancel;
      default:
        return Icons.help_outline;
    }
  }

  Color _getStatusColor(String? status) {
    switch ((status ?? '').toLowerCase()) {
      case 'good':
        return Colors.green;
      case 'broken':
        return Colors.orange;
      case 'missing':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Search Assets'),
      ),
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: TextField(
              controller: _searchController,
              focusNode: _searchFocusNode,
              decoration: InputDecoration(
                hintText: 'Search by barcode, description...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                        },
                      )
                    : null,
                filled: true,
                fillColor: Theme.of(context).cardColor,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              ),
              textInputAction: TextInputAction.search,
            ),
          ),

          // Filter chips
          SizedBox(
            height: 44,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              itemCount: _filterOptions.length,
              itemBuilder: (context, index) {
                final filter = _filterOptions[index];
                final isSelected = _selectedFilter == filter;
                final color = _getFilterColor(filter);

                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: FilterChip(
                    label: Text(
                      filter,
                      style: TextStyle(
                        color: isSelected ? Colors.white : color,
                        fontWeight:
                            isSelected ? FontWeight.bold : FontWeight.normal,
                        fontSize: 13,
                      ),
                    ),
                    selected: isSelected,
                    onSelected: (selected) {
                      setState(() {
                        _selectedFilter = filter;
                      });
                      _applyFilters();
                    },
                    backgroundColor: color.withOpacity(0.1),
                    selectedColor: color,
                    checkmarkColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                      side: BorderSide(
                        color: isSelected ? color : color.withOpacity(0.3),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          // Results count
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
            child: Row(
              children: [
                Text(
                  _loading
                      ? 'Loading...'
                      : '${_filteredItems.length} items found',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey[500],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const Spacer(),
                if (!_loading)
                  Text(
                    'Total: ${_allItems.length}',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
              ],
            ),
          ),

          const Divider(height: 1),

          // Results list
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _filteredItems.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.search_off,
                                size: 64, color: Colors.grey[400]),
                            const SizedBox(height: 16),
                            Text(
                              _searchController.text.isEmpty &&
                                      _selectedFilter == 'All'
                                  ? 'No assets found'
                                  : 'No matching assets',
                              style: TextStyle(
                                fontSize: 18,
                                color: Colors.grey[400],
                              ),
                            ),
                            const SizedBox(height: 8),
                            TextButton(
                              onPressed: () {
                                _searchController.clear();
                                setState(() => _selectedFilter = 'All');
                                _applyFilters();
                              },
                              child: const Text('Clear filters'),
                            ),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _loadAllItems,
                        child: ListView.builder(
                          physics: const AlwaysScrollableScrollPhysics(),
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          itemCount: _filteredItems.length,
                          itemBuilder: (context, index) {
                            return _buildAssetCard(_filteredItems[index]);
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildAssetCard(AssetModel asset) {
    final statusColor = _getStatusColor(asset.surveyStatus);
    final statusIcon = _getStatusIcon(asset.surveyStatus);

    // Check if verified
    final approval = (asset.verificationStatus ?? '').toLowerCase();
    final isVerified = approval.contains('verified') ||
        approval.contains('approved') ||
        (asset.verifiedBy != null && asset.verifiedBy!.isNotEmpty);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: InkWell(
        onTap: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => FieldOfficerVerificationScreen(asset: asset),
            ),
          );
          _loadAllItems();
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              // Status indicator
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(statusIcon, color: statusColor, size: 24),
              ),
              const SizedBox(width: 12),

              // Details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Barcode
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            asset.newCode,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (isVerified)
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.green.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                  color: Colors.green.withOpacity(0.3)),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.check_circle,
                                    size: 12, color: Colors.green),
                                SizedBox(width: 3),
                                Text(
                                  'Verified',
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: Colors.green,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
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
                    const SizedBox(height: 4),

                    // Bottom row — status + balances
                    Row(
                      children: [
                        // Status chip
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: statusColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            asset.surveyStatus ?? 'N/A',
                            style: TextStyle(
                              fontSize: 10,
                              color: statusColor,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),

                        // Book/Physical balance
                        Icon(Icons.book, size: 12, color: Colors.grey[500]),
                        const SizedBox(width: 2),
                        Text(
                          '${asset.bookBalance}',
                          style:
                              TextStyle(fontSize: 11, color: Colors.grey[500]),
                        ),
                        const SizedBox(width: 6),
                        Icon(Icons.inventory,
                            size: 12, color: Colors.grey[500]),
                        const SizedBox(width: 2),
                        Text(
                          '${asset.physicalBalance}',
                          style:
                              TextStyle(fontSize: 11, color: Colors.grey[500]),
                        ),

                        // Excess/Shortage indicator
                        if (asset.excess > 0) ...[
                          const SizedBox(width: 6),
                          Text(
                            '+${asset.excess}',
                            style: const TextStyle(
                                fontSize: 11,
                                color: Colors.green,
                                fontWeight: FontWeight.bold),
                          ),
                        ],
                        if (asset.shortage > 0) ...[
                          const SizedBox(width: 6),
                          Text(
                            '-${asset.shortage}',
                            style: const TextStyle(
                                fontSize: 11,
                                color: Colors.red,
                                fontWeight: FontWeight.bold),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),

              Icon(Icons.chevron_right, color: Colors.grey[400], size: 20),
            ],
          ),
        ),
      ),
    );
  }
}
