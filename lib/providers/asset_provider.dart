import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/models/asset_model.dart';
import '../data/database/database_helper.dart';
import 'auth_provider.dart';

/// Asset list state
class AssetListState {
  final List<AssetModel> assets;
  final bool isLoading;
  final String? errorMessage;
  final String? searchQuery;
  final String? statusFilter;
  final bool? isSurveyedFilter;

  const AssetListState({
    this.assets = const [],
    this.isLoading = false,
    this.errorMessage,
    this.searchQuery,
    this.statusFilter,
    this.isSurveyedFilter,
  });

  AssetListState copyWith({
    List<AssetModel>? assets,
    bool? isLoading,
    String? errorMessage,
    String? searchQuery,
    String? statusFilter,
    bool? isSurveyedFilter,
  }) {
    return AssetListState(
      assets: assets ?? this.assets,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
      searchQuery: searchQuery ?? this.searchQuery,
      statusFilter: statusFilter ?? this.statusFilter,
      isSurveyedFilter: isSurveyedFilter ?? this.isSurveyedFilter,
    );
  }
}

/// Asset list notifier
class AssetListNotifier extends StateNotifier<AssetListState> {
  final DatabaseHelper _db;
  final Ref _ref;

  AssetListNotifier(this._db, this._ref) : super(const AssetListState());

  /// Load all assets for current user
  Future<void> loadAssets() async {
    state = state.copyWith(isLoading: true, errorMessage: null);

    try {
      final authState = _ref.read(authProvider);
      List<AssetModel> assets;

      if (authState.isFieldOfficer) {
        // Field officers see all assets, but can filter
        assets = await _db.getAssetsFiltered(
          searchQuery: state.searchQuery,
          surveyStatus: state.statusFilter,
          isSurveyed: state.isSurveyedFilter,
          updatedBy: authState.currentUser?.username,
        );
      } else {
        // Admin sees all assets
        assets = await _db.getAssetsFiltered(
          searchQuery: state.searchQuery,
          surveyStatus: state.statusFilter,
          isSurveyed: state.isSurveyedFilter,
        );
      }

      state = state.copyWith(assets: assets, isLoading: false);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Failed to load assets: $e',
      );
    }
  }

  /// Search assets
  Future<void> search(String query) async {
    state = state.copyWith(searchQuery: query);
    await loadAssets();
  }

  /// Filter by status
  Future<void> filterByStatus(String? status) async {
    state = state.copyWith(statusFilter: status);
    await loadAssets();
  }

  /// Filter by surveyed state
  Future<void> filterBySurveyed(bool? isSurveyed) async {
    state = state.copyWith(isSurveyedFilter: isSurveyed);
    await loadAssets();
  }

  /// Clear all filters
  Future<void> clearFilters() async {
    state = const AssetListState();
    await loadAssets();
  }

  /// Update a single asset
  Future<bool> updateAsset(AssetModel asset) async {
    try {
      await _db.updateAsset(asset);
      await loadAssets();
      return true;
    } catch (e) {
      state = state.copyWith(errorMessage: 'Failed to update asset: $e');
      return false;
    }
  }

  /// Add a new asset
  Future<bool> addAsset(AssetModel asset) async {
    try {
      await _db.insertAsset(asset);
      await loadAssets();
      return true;
    } catch (e) {
      state = state.copyWith(errorMessage: 'Failed to add asset: $e');
      return false;
    }
  }

  /// Clear error message
  void clearError() {
    state = state.copyWith(errorMessage: null);
  }
}

/// Asset list provider
final assetListProvider =
    StateNotifierProvider<AssetListNotifier, AssetListState>((ref) {
  return AssetListNotifier(DatabaseHelper(), ref);
});
