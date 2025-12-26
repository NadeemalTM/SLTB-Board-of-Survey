import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/database/database_helper.dart';
import 'auth_provider.dart';

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

/// Dashboard notifier
class DashboardNotifier extends StateNotifier<DashboardState> {
  final DatabaseHelper _db;
  final Ref _ref;

  DashboardNotifier(this._db, this._ref) : super(const DashboardState());

  /// Load dashboard statistics
  Future<void> loadStats() async {
    state = state.copyWith(isLoading: true, errorMessage: null);

    try {
      // Fetch all statistics
      final totalItems = await _db.getTotalCount();
      final surveyedItems = await _db.getSurveyedCount();
      final pendingItems = totalItems - surveyedItems;
      final statusCounts = await _db.getCountByStatus();
      final newItems = await _db.getNewItemsCount();

      // Calculate completion percentage
      final completionPercentage =
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
  return DashboardNotifier(DatabaseHelper(), ref);
});
