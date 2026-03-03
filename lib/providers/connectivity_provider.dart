import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// =====================================================
// CONNECTIVITY STATUS
// =====================================================

enum NetworkStatus { online, offline, checking }

final connectivityProvider =
    StateNotifierProvider<ConnectivityNotifier, NetworkStatus>((ref) {
  return ConnectivityNotifier();
});

class ConnectivityNotifier extends StateNotifier<NetworkStatus> {
  late StreamSubscription<List<ConnectivityResult>> _subscription;

  ConnectivityNotifier() : super(NetworkStatus.checking) {
    _init();
  }

  void _init() {
    // Check initial status
    _checkConnectivity();

    // Listen for changes
    _subscription = Connectivity().onConnectivityChanged.listen((results) {
      if (results.contains(ConnectivityResult.none)) {
        state = NetworkStatus.offline;
      } else {
        // We have a connection type, verify with a real Firebase ping
        _verifyFirebaseConnection();
      }
    });
  }

  Future<void> _checkConnectivity() async {
    final results = await Connectivity().checkConnectivity();
    if (results.contains(ConnectivityResult.none)) {
      state = NetworkStatus.offline;
    } else {
      await _verifyFirebaseConnection();
    }
  }

  /// Actually ping Firebase to confirm we can reach it
  Future<void> _verifyFirebaseConnection() async {
    try {
      // Quick read to verify Firebase is reachable
      await FirebaseFirestore.instance
          .collection('_connectivity_check')
          .doc('ping')
          .get(const GetOptions(source: Source.server))
          .timeout(const Duration(seconds: 5));
      state = NetworkStatus.online;
    } catch (_) {
      // Network exists but can't reach Firebase
      state = NetworkStatus.offline;
    }
  }

  /// Manual refresh
  Future<void> refresh() async {
    state = NetworkStatus.checking;
    await _checkConnectivity();
  }

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}

// =====================================================
// SYNC STATUS TRACKING
// =====================================================

enum SyncItemStatus { synced, pending, failed }

class SyncItem {
  final String id; // asset barcode or unique ID
  final String description;
  final SyncItemStatus status;
  final DateTime timestamp;
  final String? errorMessage;

  SyncItem({
    required this.id,
    required this.description,
    required this.status,
    required this.timestamp,
    this.errorMessage,
  });

  SyncItem copyWith({
    SyncItemStatus? status,
    String? errorMessage,
  }) {
    return SyncItem(
      id: id,
      description: description,
      status: status ?? this.status,
      timestamp: timestamp,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}

class SyncState {
  final List<SyncItem> items;
  final bool isSyncing;

  SyncState({this.items = const [], this.isSyncing = false});

  int get syncedCount =>
      items.where((i) => i.status == SyncItemStatus.synced).length;
  int get pendingCount =>
      items.where((i) => i.status == SyncItemStatus.pending).length;
  int get failedCount =>
      items.where((i) => i.status == SyncItemStatus.failed).length;
  int get totalCount => items.length;

  /// True if all items are synced or there are no items
  bool get allSynced => pendingCount == 0 && failedCount == 0;
}

final syncStatusProvider =
    StateNotifierProvider<SyncStatusNotifier, SyncState>((ref) {
  return SyncStatusNotifier();
});

class SyncStatusNotifier extends StateNotifier<SyncState> {
  SyncStatusNotifier() : super(SyncState());

  /// Mark an item as synced (called after successful Firebase save)
  void markSynced(String id, String description) {
    final updated = [...state.items];

    // Remove existing entry for this ID if any
    updated.removeWhere((item) => item.id == id);

    // Add as synced
    updated.insert(
      0,
      SyncItem(
        id: id,
        description: description,
        status: SyncItemStatus.synced,
        timestamp: DateTime.now(),
      ),
    );

    // Keep only last 50 items
    if (updated.length > 50) updated.removeRange(50, updated.length);

    state = SyncState(items: updated);
  }

  /// Mark an item as pending (saving in progress)
  void markPending(String id, String description) {
    final updated = [...state.items];
    updated.removeWhere((item) => item.id == id);
    updated.insert(
      0,
      SyncItem(
        id: id,
        description: description,
        status: SyncItemStatus.pending,
        timestamp: DateTime.now(),
      ),
    );
    if (updated.length > 50) updated.removeRange(50, updated.length);
    state = SyncState(items: updated);
  }

  /// Mark an item as failed
  void markFailed(String id, String description, String error) {
    final updated = [...state.items];
    updated.removeWhere((item) => item.id == id);
    updated.insert(
      0,
      SyncItem(
        id: id,
        description: description,
        status: SyncItemStatus.failed,
        timestamp: DateTime.now(),
        errorMessage: error,
      ),
    );
    if (updated.length > 50) updated.removeRange(50, updated.length);
    state = SyncState(items: updated);
  }

  /// Clear all sync history
  void clear() {
    state = SyncState();
  }
}
