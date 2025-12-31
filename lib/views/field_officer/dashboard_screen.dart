import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/dashboard_provider.dart';
import '../../providers/asset_provider.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/theme_toggle_button.dart';
import '../../widgets/statistic_overview_card.dart';
import '../../widgets/quick_actions_bar.dart';
import '../../widgets/enhanced_search_bar.dart';
import '../../widgets/loading_skeleton.dart';
import '../../widgets/empty_state.dart';
import 'widgets/summary_card.dart';
import 'widgets/asset_list_item.dart';
import 'widgets/filter_chip_bar.dart';
import 'scan_screen.dart';
import 'add_item_screen.dart';
import '../auth/login_screen.dart';

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
    Navigator.of(context)
        .push(
          MaterialPageRoute(builder: (_) => const ScanScreen()),
        )
        .then((_) => _onRefresh());
  }

  void _navigateToAddItem() {
    Navigator.of(context)
        .push(
          MaterialPageRoute(builder: (_) => const AddItemScreen()),
        )
        .then((_) => _onRefresh());
  }

  void _showExportDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.download, color: Color(0xFF2E7D32)),
            SizedBox(width: 12),
            Text('Export Data'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Export your survey data to CSV format.'),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.file_present, color: Color(0xFFFFD700)),
              title: const Text('Export All Data'),
              subtitle: const Text('Complete survey records'),
              onTap: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Exporting all data...'),
                    backgroundColor: Color(0xFF2E7D32),
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.check_circle, color: Colors.green),
              title: const Text('Export Completed Only'),
              subtitle: const Text('Surveyed items only'),
              onTap: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Exporting completed data...'),
                    backgroundColor: Color(0xFF2E7D32),
                  ),
                );
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  void _showImportOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Import Data',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 24),
            ListTile(
              leading: const CircleAvatar(
                backgroundColor: Color(0xFF2E7D32),
                child: Icon(Icons.file_upload, color: Colors.white),
              ),
              title: const Text('Import CSV'),
              subtitle: const Text('Import master data from CSV file'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('CSV import coming soon')),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleLogout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF8B0000),
            ),
            child: const Text('Logout'),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      ref.read(authProvider.notifier).logout();
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
      );
    }
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
            onPressed: _handleLogout,
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

            // Statistics Overview Card
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: dashboardState.isLoading
                    ? const StatCardSkeleton()
                    : StatisticOverviewCard(
                        totalItems: dashboardState.stats.totalItems,
                        surveyedItems: dashboardState.stats.surveyedItems,
                        pendingItems: dashboardState.stats.pendingItems,
                        completionPercentage:
                            dashboardState.stats.completionPercentage,
                      ),
              ),
            ),

            // Quick Actions Bar
            SliverToBoxAdapter(
              child: QuickActionsBar(
                onScan: _navigateToScan,
                onAdd: _navigateToAddItem,
                onExport: _showExportDialog,
                onImport: () => _showImportOptions(context),
              ),
            ),

            // Summary cards
            SliverToBoxAdapter(
              child: dashboardState.isLoading
                  ? const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16.0),
                      child: Row(
                        children: [
                          Expanded(child: StatCardSkeleton()),
                          SizedBox(width: 8),
                          Expanded(child: StatCardSkeleton()),
                          SizedBox(width: 8),
                          Expanded(child: StatCardSkeleton()),
                        ],
                      ),
                    )
                  : _buildSummaryCards(dashboardState.stats),
            ),

            // Enhanced Search bar
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: EnhancedSearchBar(
                  controller: _searchController,
                  onSearch: _onSearch,
                  onClear: _clearFilters,
                  hintText: 'Search by asset code or description...',
                  suggestions: const [
                    'Surveyed items',
                    'Pending items',
                    'Good condition',
                    'Broken items',
                  ],
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
              SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) => const AssetListSkeleton(),
                  childCount: 5,
                ),
              )
            else if (assetListState.assets.isEmpty)
              SliverFillRemaining(
                child: EmptyStateWidget(
                  icon: assetListState.searchQuery != null ||
                          _selectedStatus != null ||
                          _selectedSurveyFilter != null
                      ? Icons.search_off
                      : Icons.inventory_2,
                  title: assetListState.searchQuery != null ||
                          _selectedStatus != null ||
                          _selectedSurveyFilter != null
                      ? 'No Results Found'
                      : 'No Assets Yet',
                  message: assetListState.searchQuery != null ||
                          _selectedStatus != null ||
                          _selectedSurveyFilter != null
                      ? 'Try adjusting your search or filters'
                      : 'Start by scanning QR codes or adding items manually',
                  actionLabel: assetListState.searchQuery == null
                      ? 'Add First Item'
                      : null,
                  onAction: assetListState.searchQuery == null
                      ? _navigateToAddItem
                      : null,
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
      bottomNavigationBar: Container(
        padding: const EdgeInsets.only(bottom: 8),
        child: const ThemeToggleButton(),
      ),
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          FloatingActionButton.extended(
            onPressed: _navigateToAddItem,
            heroTag: 'addItem',
            label: const Text('Add Item'),
            icon: const Icon(Icons.add),
            backgroundColor: const Color(0xFFFFD700),
            foregroundColor: Colors.black,
          ),
          const SizedBox(height: 12),
          FloatingActionButton.extended(
            onPressed: _navigateToScan,
            heroTag: 'scan',
            label: const Text('Scan'),
            icon: const Icon(Icons.qr_code_scanner),
            backgroundColor: const Color(0xFF2E7D32),
            foregroundColor: Colors.white,
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
                  color: const Color(0xFF0C3B2E),
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
                  color: const Color(0xFFFFD700),
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
                  color: const Color(0xFFFFC107),
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
