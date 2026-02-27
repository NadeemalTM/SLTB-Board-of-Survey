import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/auth_provider.dart';
import '../../providers/dashboard_provider.dart';
import 'pending_verification_list_screen.dart';
import '../scan/scan_screen.dart';
import '../scan/add_item_screen.dart';
import '../auth/login_screen.dart';
import 'verified_items_screen.dart';
import '../scan/asset_search_screen.dart';

/// Field Officer Dashboard - mirrored to Region Officer dashboard style
class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(dashboardProvider.notifier).loadStats();
    });
  }

  Future<void> _handleRefresh() async {
    await ref.read(dashboardProvider.notifier).loadStats();
  }

  Future<bool> _onBackPressed() async {
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
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final dashboardState = ref.watch(dashboardProvider);

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) {
          _onBackPressed();
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Field Officer Dashboard'),
          actions: [
            IconButton(
              icon: const Icon(Icons.search),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const AssetSearchScreen(),
                  ),
                ).then((_) => _handleRefresh());
              },
              tooltip: 'Search Assets',
            ),
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: _handleRefresh,
              tooltip: 'Refresh',
            ),
          ],
        ),
        body: RefreshIndicator(
          onRefresh: _handleRefresh,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Welcome Card
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const CircleAvatar(
                              radius: 30,
                              backgroundColor: Color(0xFF0C3B2E),
                              child: Icon(
                                Icons.badge,
                                size: 32,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Welcome, ${authState.currentUser?.displayName ?? 'Field Officer'}',
                                    style: const TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Text(
                                    'FIELD OFFICER',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        const Divider(),
                        const SizedBox(height: 8),
                        Text(
                          'Survey Overview',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey[400],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // Statistics Overview
                if (dashboardState.isLoading)
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.all(32.0),
                      child: CircularProgressIndicator(),
                    ),
                  )
                else ...[
                  _buildStatsGrid(dashboardState.stats),
                  const SizedBox(height: 20),
                  _buildStatusBreakdown(dashboardState.stats),
                  const SizedBox(height: 20),
                  _buildQuickActions(),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatsGrid(stats) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 1.5,
      children: [
        _buildStatCard(
          'Total Assets',
          stats.totalItems.toString(),
          Icons.inventory_2,
          Colors.blue,
        ),
        _buildStatCard(
          'Verified',
          stats.surveyedItems.toString(),
          Icons.check_circle,
          Colors.green,
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const VerifiedItemsScreen(),
              ),
            ).then((_) => _handleRefresh());
          },
        ),
        _buildStatCard(
          'Pending',
          stats.pendingItems.toString(),
          Icons.pending,
          Colors.orange,
        ),
        _buildStatCard(
          'Completion',
          '${stats.completionPercentage.toStringAsFixed(1)}%',
          Icons.pie_chart,
          const Color(0xFF0C3B2E),
        ),
      ],
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon, Color color,
      {VoidCallback? onTap}) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 28, color: color),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey[400],
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatusBreakdown(stats) {
    final statusItems = [
      _StatusItem('Good', stats.goodCount, Colors.green),
      _StatusItem('Broken', stats.brokenCount, Colors.red),
      _StatusItem('Repairable', stats.repairableCount, Colors.orange),
      _StatusItem('To be Disposed', stats.toBeDisposedCount, Colors.purple),
      _StatusItem('New Found', stats.newFoundCount, Colors.grey),
    ];

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.pie_chart_outline, size: 20),
                SizedBox(width: 8),
                Text(
                  'Status Breakdown',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...statusItems.map((item) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Row(
                    children: [
                      Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          color: item.color,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          item.label,
                          style: const TextStyle(fontSize: 14),
                        ),
                      ),
                      Text(
                        item.count.toString(),
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: item.color,
                        ),
                      ),
                    ],
                  ),
                )),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActions() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.flash_on, size: 20),
                SizedBox(width: 8),
                Text(
                  'Quick Actions',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const CircleAvatar(
                backgroundColor: Color(0xFF0C3B2E),
                child: Icon(Icons.fact_check, color: Colors.white),
              ),
              title: const Text('Pending Verification'),
              subtitle: const Text('Review and verify pending assets'),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const PendingVerificationListScreen(),
                  ),
                ).then((_) => _handleRefresh());
              },
            ),
            const Divider(),
            ListTile(
              leading: const CircleAvatar(
                backgroundColor: Color(0xFF0C3B2E),
                child: Icon(Icons.search, color: Colors.white),
              ),
              title: const Text('Search Assets'),
              subtitle: const Text('Find assets by barcode or description'),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const AssetSearchScreen(),
                  ),
                ).then((_) => _handleRefresh());
              },
            ),
            const Divider(),
            ListTile(
              leading: const CircleAvatar(
                backgroundColor: Color(0xFF0C3B2E),
                child: Icon(Icons.qr_code_scanner, color: Colors.white),
              ),
              title: const Text('Scan Barcode'),
              subtitle: const Text('Scan to enter/update asset data'),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const ScanScreen(),
                  ),
                ).then((_) => _handleRefresh());
              },
            ),
            const Divider(),
            ListTile(
              leading: const CircleAvatar(
                backgroundColor: Color(0xFF0C3B2E),
                child: Icon(Icons.add_box, color: Colors.white),
              ),
              title: const Text('Add New Asset'),
              subtitle: const Text('Manually add new asset without scanning'),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () {
                final timestamp = DateTime.now().millisecondsSinceEpoch;
                final newCode = 'MANUAL-$timestamp';
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => AddItemScreen(scannedCode: newCode),
                  ),
                ).then((_) => _handleRefresh());
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusItem {
  final String label;
  final int count;
  final Color color;

  _StatusItem(this.label, this.count, this.color);
}
