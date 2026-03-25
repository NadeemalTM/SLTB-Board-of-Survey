import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/connectivity_provider.dart';

/// A compact banner widget that shows network status and sync info.
/// Place this at the top of dashboard screens.
class SyncStatusBanner extends ConsumerWidget {
  const SyncStatusBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final networkStatus = ref.watch(connectivityProvider);
    final syncState = ref.watch(syncStatusProvider);

    return AnimatedSize(
      duration: const Duration(milliseconds: 300),
      child: Column(
        children: [
          // Network status bar
          _buildNetworkBar(context, ref, networkStatus),

          // Sync summary (only if there are items)
          if (syncState.totalCount > 0) _buildSyncSummary(context, syncState),
        ],
      ),
    );
  }

  Widget _buildNetworkBar(
      BuildContext context, WidgetRef ref, NetworkStatus status) {
    final Color bgColor;
    final Color textColor;
    final IconData icon;
    final String label;

    switch (status) {
      case NetworkStatus.online:
        bgColor = const Color(0xFF1B5E20);
        textColor = const Color(0xFFA5D6A7);
        icon = Icons.cloud_done;
        label = 'Online — Connected to Firebase';
        break;
      case NetworkStatus.offline:
        bgColor = const Color(0xFFB71C1C);
        textColor = const Color(0xFFEF9A9A);
        icon = Icons.cloud_off;
        label = 'Offline — No connection';
        break;
      case NetworkStatus.checking:
        bgColor = const Color(0xFF1A237E);
        textColor = const Color(0xFF9FA8DA);
        icon = Icons.sync;
        label = 'Checking connection...';
        break;
    }

    return GestureDetector(
      onTap: () => ref.read(connectivityProvider.notifier).refresh(),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Icon(icon, color: textColor, size: 18),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  color: textColor,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            if (status == NetworkStatus.checking)
              SizedBox(
                width: 14,
                height: 14,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(textColor),
                ),
              )
            else
              Icon(Icons.refresh, color: textColor.withAlpha(150), size: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildSyncSummary(BuildContext context, SyncState syncState) {
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: syncState.failedCount > 0
                ? Colors.red.withAlpha(100)
                : syncState.pendingCount > 0
                    ? Colors.orange.withAlpha(100)
                    : Colors.green.withAlpha(100),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title row
            Row(
              children: [
                Icon(
                  syncState.allSynced
                      ? Icons.check_circle
                      : syncState.failedCount > 0
                          ? Icons.error
                          : Icons.hourglass_top,
                  size: 16,
                  color: syncState.allSynced
                      ? Colors.green
                      : syncState.failedCount > 0
                          ? Colors.red
                          : Colors.orange,
                ),
                const SizedBox(width: 8),
                Text(
                  'Recent Sync Activity',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[400],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Status chips row
            Row(
              children: [
                if (syncState.syncedCount > 0)
                  _buildStatusChip(
                    '✅ ${syncState.syncedCount} Synced',
                    Colors.green,
                  ),
                if (syncState.pendingCount > 0) ...[
                  const SizedBox(width: 8),
                  _buildStatusChip(
                    '⏳ ${syncState.pendingCount} Pending',
                    Colors.orange,
                  ),
                ],
                if (syncState.failedCount > 0) ...[
                  const SizedBox(width: 8),
                  _buildStatusChip(
                    '❌ ${syncState.failedCount} Failed',
                    Colors.red,
                  ),
                ],
              ],
            ),

            // Show last few items
            if (syncState.items.isNotEmpty) ...[
              const SizedBox(height: 8),
              ...syncState.items.take(3).map(
                    (item) => Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Row(
                        children: [
                          Icon(
                            item.status == SyncItemStatus.synced
                                ? Icons.check_circle_outline
                                : item.status == SyncItemStatus.failed
                                    ? Icons.error_outline
                                    : Icons.access_time,
                            size: 14,
                            color: item.status == SyncItemStatus.synced
                                ? Colors.green
                                : item.status == SyncItemStatus.failed
                                    ? Colors.red
                                    : Colors.orange,
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              '${item.id} — ${item.description}',
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.grey[500],
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Text(
                            _timeAgo(item.timestamp),
                            style: TextStyle(
                              fontSize: 10,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStatusChip(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withAlpha(25),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withAlpha(80)),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          color: color,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  String _timeAgo(DateTime time) {
    final diff = DateTime.now().difference(time);
    if (diff.inSeconds < 60) return 'just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }
}
