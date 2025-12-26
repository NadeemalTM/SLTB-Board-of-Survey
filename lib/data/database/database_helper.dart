import 'dart:async';
import 'dart:io';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import '../models/asset_model.dart';
import 'database_constants.dart';

/// DatabaseHelper - Singleton class managing all SQFlite operations
/// 
/// Provides comprehensive CRUD operations for the assets table,
/// batch import from CSV, and export of modified records.
class DatabaseHelper {
  // Singleton pattern
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  factory DatabaseHelper() => _instance;
  DatabaseHelper._internal();
  
  /// Static getter for instance (used by UI)
  static DatabaseHelper get instance => _instance;

  static Database? _database;

  /// Get database instance (create if not exists)
  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  /// Initialize database and create tables
  Future<Database> _initDatabase() async {
    try {
      // Get application documents directory
      Directory documentsDirectory = await getApplicationDocumentsDirectory();
      String path = join(documentsDirectory.path, DatabaseConstants.databaseName);

      // Open database (creates if doesn't exist)
      return await openDatabase(
        path,
        version: DatabaseConstants.databaseVersion,
        onCreate: _onCreate,
        onUpgrade: _onUpgrade,
      );
    } catch (e) {
      throw Exception('Failed to initialize database: $e');
    }
  }

  /// Create tables on first database creation
  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE ${DatabaseConstants.assetsTable} (
        ${DatabaseConstants.columnId} INTEGER PRIMARY KEY AUTOINCREMENT,
        ${DatabaseConstants.columnSerialNo} INTEGER,
        ${DatabaseConstants.columnDescription} TEXT NOT NULL,
        ${DatabaseConstants.columnOldCode} TEXT,
        ${DatabaseConstants.columnNewCode} TEXT NOT NULL UNIQUE,
        ${DatabaseConstants.columnBookBalance} INTEGER DEFAULT 0,
        ${DatabaseConstants.columnPhysicalBalance} INTEGER DEFAULT 0,
        ${DatabaseConstants.columnExcess} INTEGER DEFAULT 0,
        ${DatabaseConstants.columnShortage} INTEGER DEFAULT 0,
        ${DatabaseConstants.columnRemarks} TEXT,
        ${DatabaseConstants.columnSurveyStatus} TEXT,
        ${DatabaseConstants.columnImagePath1} TEXT,
        ${DatabaseConstants.columnImagePath2} TEXT,
        ${DatabaseConstants.columnImagePath3} TEXT,
        ${DatabaseConstants.columnLastUpdatedBy} TEXT,
        ${DatabaseConstants.columnLastUpdatedDate} TEXT,
        ${DatabaseConstants.columnIsNewItem} INTEGER DEFAULT 0
      )
    ''');

    // Create indexes for better query performance
    await db.execute('''
      CREATE INDEX idx_new_code ON ${DatabaseConstants.assetsTable}(${DatabaseConstants.columnNewCode})
    ''');

    await db.execute('''
      CREATE INDEX idx_survey_status ON ${DatabaseConstants.assetsTable}(${DatabaseConstants.columnSurveyStatus})
    ''');

    await db.execute('''
      CREATE INDEX idx_last_updated_by ON ${DatabaseConstants.assetsTable}(${DatabaseConstants.columnLastUpdatedBy})
    ''');
  }

  /// Handle database upgrades (for future versions)
  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    // Handle schema migrations here when version changes
    // Example: if (oldVersion < 2) { /* add new column */ }
  }

  // ==================== CRUD Operations ====================

  /// Insert a new asset record
  Future<int> insertAsset(AssetModel asset) async {
    try {
      final db = await database;
      return await db.insert(
        DatabaseConstants.assetsTable,
        asset.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    } catch (e) {
      throw Exception('Failed to insert asset: $e');
    }
  }

  /// Update an existing asset record
  Future<int> updateAsset(AssetModel asset) async {
    try {
      final db = await database;
      return await db.update(
        DatabaseConstants.assetsTable,
        asset.toMap(),
        where: '${DatabaseConstants.columnId} = ?',
        whereArgs: [asset.id],
      );
    } catch (e) {
      throw Exception('Failed to update asset: $e');
    }
  }

  /// Delete an asset by ID
  Future<int> deleteAsset(int id) async {
    try {
      final db = await database;
      return await db.delete(
        DatabaseConstants.assetsTable,
        where: '${DatabaseConstants.columnId} = ?',
        whereArgs: [id],
      );
    } catch (e) {
      throw Exception('Failed to delete asset: $e');
    }
  }

  /// Get asset by ID
  Future<AssetModel?> getAssetById(int id) async {
    try {
      final db = await database;
      final List<Map<String, dynamic>> maps = await db.query(
        DatabaseConstants.assetsTable,
        where: '${DatabaseConstants.columnId} = ?',
        whereArgs: [id],
      );

      if (maps.isEmpty) return null;
      return AssetModel.fromMap(maps.first);
    } catch (e) {
      throw Exception('Failed to get asset by ID: $e');
    }
  }

  /// Get asset by new_code (barcode/QR code)
  /// This is the primary method used during scanning
  Future<AssetModel?> getAssetByNewCode(String newCode) async {
    try {
      final db = await database;
      final List<Map<String, dynamic>> maps = await db.query(
        DatabaseConstants.assetsTable,
        where: '${DatabaseConstants.columnNewCode} = ?',
        whereArgs: [newCode],
      );

      if (maps.isEmpty) return null;
      return AssetModel.fromMap(maps.first);
    } catch (e) {
      throw Exception('Failed to get asset by code: $e');
    }
  }

  /// Get all assets
  Future<List<AssetModel>> getAllAssets() async {
    try {
      final db = await database;
      final List<Map<String, dynamic>> maps = await db.query(
        DatabaseConstants.assetsTable,
        orderBy: '${DatabaseConstants.columnSerialNo} ASC',
      );

      return List.generate(maps.length, (i) => AssetModel.fromMap(maps[i]));
    } catch (e) {
      throw Exception('Failed to get all assets: $e');
    }
  }

  /// Get assets with filters
  Future<List<AssetModel>> getAssetsFiltered({
    String? searchQuery,
    String? surveyStatus,
    bool? isSurveyed,
    String? updatedBy,
  }) async {
    try {
      final db = await database;
      String whereClause = '';
      List<dynamic> whereArgs = [];

      // Build dynamic WHERE clause
      List<String> conditions = [];

      if (searchQuery != null && searchQuery.isNotEmpty) {
        conditions.add(
          '(${DatabaseConstants.columnDescription} LIKE ? OR ${DatabaseConstants.columnNewCode} LIKE ? OR ${DatabaseConstants.columnOldCode} LIKE ?)',
        );
        String searchPattern = '%$searchQuery%';
        whereArgs.addAll([searchPattern, searchPattern, searchPattern]);
      }

      if (surveyStatus != null && surveyStatus.isNotEmpty) {
        conditions.add('${DatabaseConstants.columnSurveyStatus} = ?');
        whereArgs.add(surveyStatus);
      }

      if (isSurveyed != null) {
        if (isSurveyed) {
          conditions.add('${DatabaseConstants.columnLastUpdatedBy} IS NOT NULL');
        } else {
          conditions.add('${DatabaseConstants.columnLastUpdatedBy} IS NULL');
        }
      }

      if (updatedBy != null && updatedBy.isNotEmpty) {
        conditions.add('${DatabaseConstants.columnLastUpdatedBy} = ?');
        whereArgs.add(updatedBy);
      }

      if (conditions.isNotEmpty) {
        whereClause = conditions.join(' AND ');
      }

      final List<Map<String, dynamic>> maps = await db.query(
        DatabaseConstants.assetsTable,
        where: whereClause.isEmpty ? null : whereClause,
        whereArgs: whereArgs.isEmpty ? null : whereArgs,
        orderBy: '${DatabaseConstants.columnSerialNo} ASC',
      );

      return List.generate(maps.length, (i) => AssetModel.fromMap(maps[i]));
    } catch (e) {
      throw Exception('Failed to get filtered assets: $e');
    }
  }

  // ==================== Dashboard Statistics ====================

  /// Get total count of assets
  Future<int> getTotalCount() async {
    try {
      final db = await database;
      final result = await db.rawQuery(
        'SELECT COUNT(*) as count FROM ${DatabaseConstants.assetsTable}',
      );
      return Sqflite.firstIntValue(result) ?? 0;
    } catch (e) {
      throw Exception('Failed to get total count: $e');
    }
  }

  /// Get count of surveyed assets
  Future<int> getSurveyedCount() async {
    try {
      final db = await database;
      final result = await db.rawQuery(
        'SELECT COUNT(*) as count FROM ${DatabaseConstants.assetsTable} WHERE ${DatabaseConstants.columnLastUpdatedBy} IS NOT NULL',
      );
      return Sqflite.firstIntValue(result) ?? 0;
    } catch (e) {
      throw Exception('Failed to get surveyed count: $e');
    }
  }

  /// Get count by survey status
  Future<Map<String, int>> getCountByStatus() async {
    try {
      final db = await database;
      final result = await db.rawQuery('''
        SELECT ${DatabaseConstants.columnSurveyStatus}, COUNT(*) as count 
        FROM ${DatabaseConstants.assetsTable} 
        WHERE ${DatabaseConstants.columnSurveyStatus} IS NOT NULL
        GROUP BY ${DatabaseConstants.columnSurveyStatus}
      ''');

      Map<String, int> statusCounts = {};
      for (var row in result) {
        String status = row['survey_status'] as String;
        int count = row['count'] as int;
        statusCounts[status] = count;
      }
      return statusCounts;
    } catch (e) {
      throw Exception('Failed to get status counts: $e');
    }
  }

  /// Get count of new items added by field officers
  Future<int> getNewItemsCount() async {
    try {
      final db = await database;
      final result = await db.rawQuery(
        'SELECT COUNT(*) as count FROM ${DatabaseConstants.assetsTable} WHERE ${DatabaseConstants.columnIsNewItem} = 1',
      );
      return Sqflite.firstIntValue(result) ?? 0;
    } catch (e) {
      throw Exception('Failed to get new items count: $e');
    }
  }

  // ==================== Batch Operations for CSV ====================

  /// Batch insert assets from master CSV import (Admin function)
  /// Clears existing data and inserts new master list
  Future<int> batchInsertFromMasterCsv(List<AssetModel> assets) async {
    try {
      final db = await database;
      int insertedCount = 0;

      await db.transaction((txn) async {
        // Clear existing data
        await txn.delete(DatabaseConstants.assetsTable);

        // Batch insert new records
        Batch batch = txn.batch();
        for (var asset in assets) {
          batch.insert(
            DatabaseConstants.assetsTable,
            asset.toMap(),
            conflictAlgorithm: ConflictAlgorithm.replace,
          );
        }
        await batch.commit(noResult: true);
        insertedCount = assets.length;
      });

      return insertedCount;
    } catch (e) {
      throw Exception('Failed to batch insert from master CSV: $e');
    }
  }

  /// Merge field officer CSV data into existing records
  /// Updates matching records based on new_code
  Future<Map<String, dynamic>> mergeFieldOfficerCsv(List<AssetModel> assets) async {
    try {
      final db = await database;
      int updatedCount = 0;
      int insertedCount = 0;
      int notFoundCount = 0;
      int failedCount = 0;

      await db.transaction((txn) async {
        for (var asset in assets) {
          try {
            // Try to find existing record by new_code
            final existing = await txn.query(
              DatabaseConstants.assetsTable,
              where: '${DatabaseConstants.columnNewCode} = ?',
              whereArgs: [asset.newCode],
            );

            if (existing.isNotEmpty) {
              // Update existing record
              await txn.update(
                DatabaseConstants.assetsTable,
                asset.toMap(),
                where: '${DatabaseConstants.columnNewCode} = ?',
                whereArgs: [asset.newCode],
              );
              updatedCount++;
            } else if (asset.isNewItem == 1) {
              // Insert as new item if marked as new
              await txn.insert(
                DatabaseConstants.assetsTable,
                asset.toMap(),
                conflictAlgorithm: ConflictAlgorithm.replace,
              );
              insertedCount++;
            } else {
              // Asset not found in master list
              notFoundCount++;
            }
          } catch (e) {
            failedCount++;
          }
        }
      });

      return {
        'updated': updatedCount,
        'inserted': insertedCount,
        'notFound': notFoundCount,
        'failed': failedCount,
      };
    } catch (e) {
      throw Exception('Failed to merge field officer CSV: $e');
    }
  }

  /// Get all assets modified by a specific field officer
  /// Used for field officer CSV export
  Future<List<AssetModel>> getModifiedAssetsByUser(String username) async {
    try {
      final db = await database;
      final List<Map<String, dynamic>> maps = await db.query(
        DatabaseConstants.assetsTable,
        where: '${DatabaseConstants.columnLastUpdatedBy} = ?',
        whereArgs: [username],
        orderBy: '${DatabaseConstants.columnSerialNo} ASC',
      );

      return List.generate(maps.length, (i) => AssetModel.fromMap(maps[i]));
    } catch (e) {
      throw Exception('Failed to get modified assets: $e');
    }
  }

  /// Get all assets for final report export (Admin function)
  Future<List<AssetModel>> getAllAssetsForExport() async {
    try {
      return await getAllAssets();
    } catch (e) {
      throw Exception('Failed to get assets for export: $e');
    }
  }

  // ==================== Database Maintenance ====================

  /// Clear all data from assets table
  Future<void> clearAllAssets() async {
    try {
      final db = await database;
      await db.delete(DatabaseConstants.assetsTable);
    } catch (e) {
      throw Exception('Failed to clear assets: $e');
    }
  }

  /// Get database file path (for backup/debugging)
  Future<String> getDatabasePath() async {
    try {
      Directory documentsDirectory = await getApplicationDocumentsDirectory();
      return join(documentsDirectory.path, DatabaseConstants.databaseName);
    } catch (e) {
      throw Exception('Failed to get database path: $e');
    }
  }

  /// Close database connection
  Future<void> close() async {
    final db = await database;
    await db.close();
    _database = null;
  }

  /// Delete database file (use with caution!)
  Future<void> deleteDatabase() async {
    try {
      String path = await getDatabasePath();
      if (await File(path).exists()) {
        await File(path).delete();
        _database = null;
      }
    } catch (e) {
      throw Exception('Failed to delete database: $e');
    }
  }
}
