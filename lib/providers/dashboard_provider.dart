import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Dashboard statistics
class DashboardStats {
  final int totalItems;
  final int surveyedItems;
  final int pendingItems;
  final Map<String, int> statusCounts;
  final int newItems;
  final double completionPercentage;

  const DashboardStats({
    this.totalItems = 0,
    this.surveyedItems = 0,
    this.pendingItems = 0,
    this.statusCounts = const {},
    this.newItems = 0,
    this.completionPercentage = 0.0,
  });

  DashboardStats copyWith({
    int? totalItems,
    int? surveyedItems,
    int? pendingItems,
    Map<String, int>? statusCounts,
    int? newItems,
    double? completionPercentage,
  }) {
    return DashboardStats(
      totalItems: totalItems ?? this.totalItems,
      surveyedItems: surveyedItems ?? this.surveyedItems,
      pendingItems: pendingItems ?? this.pendingItems,
      statusCounts: statusCounts ?? this.statusCounts,
      newItems: newItems ?? this.newItems,
      completionPercentage: completionPercentage ?? this.completionPercentage,
    );
  }

  // Helper getters for specific status counts
  int get goodCount => statusCounts['Good'] ?? 0;
  int get brokenCount => statusCounts['Broken'] ?? 0;
  int get repairableCount => statusCounts['Repairable'] ?? 0;
  int get toBeDisposedCount => statusCounts['To be Disposed'] ?? 0;
  int get newFoundCount => statusCounts['New Found'] ?? 0;
}

/// Dashboard state
class DashboardState {
  final DashboardStats stats;
  final bool isLoading;
  final String? errorMessage;

  const DashboardState({
    this.stats = const DashboardStats(),
    this.isLoading = false,
    this.errorMessage,
  });

  DashboardState copyWith({
    DashboardStats? stats,
    bool? isLoading,
    String? errorMessage,
  }) {
    return DashboardState(
      stats: stats ?? this.stats,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
    );
  }
}

/// Dashboard notifier — reads from Firebase Firestore
class DashboardNotifier extends StateNotifier<DashboardState> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  DashboardNotifier() : super(const DashboardState());

  /// Get current year collection name (e.g., 'survey_2026')
  String get _currentCollectionName {
    final String currentYear = DateTime.now().year.toString();
    return 'survey_$currentYear';
  }

  /// Load dashboard statistics from Firestore
  Future<void> loadStats() async {
    state = state.copyWith(isLoading: true, errorMessage: null);

    try {
      // Collect all asset documents from BOTH structures
      List<Map<String, dynamic>> allDocs = [];

      // 1. Try flat collection: survey_YEAR/{docId}
      try {
        final flatSnapshot =
            await _firestore.collection(_currentCollectionName).get();
        for (final doc in flatSnapshot.docs) {
          allDocs.add(doc.data());
        }
        print(
            '[Dashboard] Flat collection "$_currentCollectionName": ${flatSnapshot.docs.length} docs');
      } catch (e) {
        print('[Dashboard] Flat collection query failed: $e');
      }

      // 2. Try hierarchical: collectionGroup('assets')
      try {
        final hierarchicalSnapshot =
            await _firestore.collectionGroup('assets').get();
        for (final doc in hierarchicalSnapshot.docs) {
          allDocs.add(doc.data());
        }
        print(
            '[Dashboard] CollectionGroup "assets": ${hierarchicalSnapshot.docs.length} docs');
      } catch (e) {
        print('[Dashboard] CollectionGroup query failed: $e');
      }

      print('[Dashboard] Total documents found: ${allDocs.length}');

      final int totalItems = allDocs.length;

      // Count surveyed and status breakdown
      int surveyedItems = 0;
      int newItems = 0;
      Map<String, int> statusCounts = {};

      for (final data in allDocs) {
        // Count verified items (approvalLevel >= 1)
        final approvalLevel = data['approvalLevel'] ?? 0;
        if (approvalLevel is int && approvalLevel >= 1) {
          surveyedItems++;
        }

        // Count new items
        final isNew = data['isNew'];
        if (isNew == true) {
          newItems++;
        }

        // Count by status (Good, Broken, Repairable, To be Disposed, New Found)
        final status = data['status']?.toString();
        if (status != null && status.isNotEmpty) {
          statusCounts[status] = (statusCounts[status] ?? 0) + 1;
        }
      }

      // Log what we found for debugging
      print(
          '[Dashboard] Stats -> Total: $totalItems, Verified: $surveyedItems, New: $newItems');
      print('[Dashboard] Status counts: $statusCounts');

      final int pendingItems = totalItems - surveyedItems;
      final double completionPercentage =
          totalItems > 0 ? (surveyedItems / totalItems) * 100 : 0.0;

      final stats = DashboardStats(
        totalItems: totalItems,
        surveyedItems: surveyedItems,
        pendingItems: pendingItems,
        statusCounts: statusCounts,
        newItems: newItems,
        completionPercentage: completionPercentage,
      );

      state = state.copyWith(stats: stats, isLoading: false);
    } catch (e) {
      print('[Dashboard] ERROR: $e');
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Failed to load statistics: $e',
      );
    }
  }

  /// Refresh statistics
  Future<void> refresh() async {
    await loadStats();
  }

  /// Clear error message
  void clearError() {
    state = state.copyWith(errorMessage: null);
  }
}

/// Dashboard provider
final dashboardProvider =
    StateNotifierProvider<DashboardNotifier, DashboardState>((ref) {
  return DashboardNotifier();
});
