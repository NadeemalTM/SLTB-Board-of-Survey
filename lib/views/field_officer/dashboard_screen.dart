import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/dashboard_provider.dart';
import '../providers/asset_provider.dart';
import '../providers/auth_provider.dart';
import '../core/constants/survey_status.dart';
import 'widgets/summary_card.dart';
import 'widgets/asset_list_item.dart';
import 'widgets/filter_chip_bar.dart';
import 'scan_screen.dart';
import 'add_item_screen.dart';

/// Field Officer Dashboard - Main home screen
/// 
/// Features:
/// - Summary cards with statistics
/// - Search bar
/// - Filter chips (status, surveyed/pending)
/// - Scrollable asset list
/// - FAB for scanning and adding items
class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  final TextEditingController _searchController = TextEditingController();
  String? _selectedStatus;
  bool? _selectedSurveyFilter;

  @override
  void initState() {
    super.initState();
    // Load initial data
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(dashboardProvider.notifier).loadStats();
      ref.read(assetListProvider.notifier).loadAssets();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onSearch(String query) {
    ref.read(assetListProvider.notifier).search(query);
  }

  void _onStatusFilterChanged(String? status) {
    setState(() => _selectedStatus = status);
    ref.read(assetListProvider.notifier).filterByStatus(status);
  }

  void _onSurveyFilterChanged(bool? isSurveyed) {
    setState(() => _selectedSurveyFilter = isSurveyed);
    ref.read(assetListProvider.notifier).filterBySurveyed(isSurveyed);
  }

  void _clearFilters() {
    setState(() {
      _selectedStatus = null;
      _selectedSurveyFilter = null;
      _searchController.clear();
    });
    ref.read(assetListProvider.notifier).clearFilters();
  }

  Future<void> _onRefresh() async {
    await ref.read(dashboardProvider.notifier).refresh();
    await ref.read(assetListProvider.notifier).loadAssets();
  }

  void _navigateToScan() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const ScanScreen()),
    ).then((_) => _onRefresh());
  }

  void _navigateToAddItem() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const AddItemScreen()),
    ).then((_) => _onRefresh());
  }

  void _showExportDialog() {
    // TODO: Implement CSV export dialog
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Export functionality coming soon')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final dashboardState = ref.watch(dashboardProvider);
    final assetListState = ref.watch(assetListProvider);
    final authState = ref.watch(authProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('SLTB Survey Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.download),
            onPressed: _showExportDialog,
            tooltip: 'Export My Work',
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              ref.read(authProvider.notifier).logout();
            },
            tooltip: 'Logout',
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _onRefresh,
        child: CustomScrollView(
          slivers: [
            // User greeting
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Welcome, ${authState.currentUser?.displayName ?? "User"}',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Track and update equipment survey',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Colors.grey[600],
                          ),
                    ),
                  ],
                ),
              ),
            ),

            // Summary cards
            SliverToBoxAdapter(
              child: dashboardState.isLoading
                  ? const Center(
                      child: Padding(
                        padding: EdgeInsets.all(32.0),
                        child: CircularProgressIndicator(),
                      ),
                    )
                  : _buildSummaryCards(dashboardState.stats),
            ),

            // Search bar
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Search by code or description...',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              _searchController.clear();
                              _onSearch('');
                            },
                          )
                        : null,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: Colors.grey[100],
                  ),
                  onChanged: _onSearch,
                ),
              ),
            ),

            // Filter chips
            SliverToBoxAdapter(
              child: FilterChipBar(
                selectedStatus: _selectedStatus,
                selectedSurveyFilter: _selectedSurveyFilter,
                onStatusChanged: _onStatusFilterChanged,
                onSurveyFilterChanged: _onSurveyFilterChanged,
                onClearFilters: _clearFilters,
              ),
            ),

            // Asset list header
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Assets (${assetListState.assets.length})',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    if (assetListState.searchQuery != null ||
                        _selectedStatus != null ||
                        _selectedSurveyFilter != null)
                      TextButton.icon(
                        onPressed: _clearFilters,
                        icon: const Icon(Icons.clear_all),
                        label: const Text('Clear Filters'),
                      ),
                  ],
                ),
              ),
            ),

            // Asset list
            if (assetListState.isLoading)
              const SliverFillRemaining(
                child: Center(child: CircularProgressIndicator()),
              )
            else if (assetListState.assets.isEmpty)
              SliverFillRemaining(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.inbox, size: 64, color: Colors.grey[400]),
                      const SizedBox(height: 16),
                      Text(
                        'No assets found',
                        style: TextStyle(
                          fontSize: 18,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
              )
            else
              SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final asset = assetListState.assets[index];
                    return AssetListItem(
                      asset: asset,
                      onTap: () {
                        // Navigate to asset detail screen
                        // TODO: Implement navigation
                      },
                    );
                  },
                  childCount: assetListState.assets.length,
                ),
              ),

            // Bottom padding
            const SliverToBoxAdapter(
              child: SizedBox(height: 80),
            ),
          ],
        ),
      ),
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          FloatingActionButton.extended(
            onPressed: _navigateToAddItem,
            heroTag: 'addItem',
            label: const Text('Add Item'),
            icon: const Icon(Icons.add),
            backgroundColor: Colors.orange,
          ),
          const SizedBox(height: 12),
          FloatingActionButton.extended(
            onPressed: _navigateToScan,
            heroTag: 'scan',
            label: const Text('Scan'),
            icon: const Icon(Icons.qr_code_scanner),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCards(DashboardStats stats) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Column(
        children: [
          // Row 1: Total, Verified, Pending
          Row(
            children: [
              Expanded(
                child: SummaryCard(
                  title: 'Total Items',
                  value: stats.totalItems.toString(),
                  icon: Icons.inventory_2,
                  color: Colors.blue,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: SummaryCard(
                  title: 'Verified',
                  value: stats.surveyedItems.toString(),
                  icon: Icons.check_circle,
                  color: Colors.green,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: SummaryCard(
                  title: 'Pending',
                  value: stats.pendingItems.toString(),
                  icon: Icons.pending,
                  color: Colors.orange,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Row 2: Good, Broken, Repairable
          Row(
            children: [
              Expanded(
                child: SummaryCard(
                  title: 'Good',
                  value: stats.goodCount.toString(),
                  icon: Icons.thumb_up,
                  color: Colors.teal,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: SummaryCard(
                  title: 'Broken',
                  value: stats.brokenCount.toString(),
                  icon: Icons.broken_image,
                  color: Colors.red,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: SummaryCard(
                  title: 'Repairable',
                  value: stats.repairableCount.toString(),
                  icon: Icons.build,
                  color: Colors.amber,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Progress card
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Survey Progress',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        '${stats.completionPercentage.toStringAsFixed(1)}%',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  LinearProgressIndicator(
                    value: stats.completionPercentage / 100,
                    minHeight: 8,
                    backgroundColor: Colors.grey[200],
                    borderRadius: BorderRadius.circular(4),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}
