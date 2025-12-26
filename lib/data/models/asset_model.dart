/// Asset Model - Represents a single asset/equipment in the survey
/// 
/// This model contains both the original master data fields and
/// the new survey fields populated by field officers.
class AssetModel {
  // Primary Key
  final int? id;

  // ==================== Original Master Data Fields ====================
  /// Serial number from master list (අංකය)
  final int? serialNo;

  /// Asset description (විස්තරය)
  final String description;

  /// Old code number (පැරණි කේත අංකය)
  final String? oldCode;

  /// New code number - Used as Barcode/QR code (නව කේත අංකය)
  /// This field is UNIQUE and indexed for fast barcode lookup
  final String newCode;

  /// Book balance quantity (පොත් අනුව ශේෂය)
  final int bookBalance;

  // ==================== New Survey Fields ====================
  /// Physical balance quantity found during survey (භෞතික අගය)
  final int physicalBalance;

  /// Excess quantity: physical - book (if positive) (අතිරික්තය)
  final int excess;

  /// Shortage quantity: book - physical (if positive) (හිඟය)
  final int shortage;

  /// Survey remarks/notes (සටහන්)
  final String? remarks;

  /// Survey status: 'Good', 'Broken', 'Repairable', 'To be Disposed', 'New Found'
  final String? surveyStatus;

  /// Local file path to first image
  final String? imagePath1;

  /// Local file path to second image
  final String? imagePath2;

  /// Local file path to third image
  final String? imagePath3;

  /// Username of the field officer who last updated this record
  final String? lastUpdatedBy;

  /// ISO8601 timestamp of last update
  final String? lastUpdatedDate;

  /// Flag: 0 = existing item from master, 1 = new item added by field officer
  final int isNewItem;

  AssetModel({
    this.id,
    this.serialNo,
    required this.description,
    this.oldCode,
    required this.newCode,
    this.bookBalance = 0,
    this.physicalBalance = 0,
    this.excess = 0,
    this.shortage = 0,
    this.remarks,
    this.surveyStatus,
    this.imagePath1,
    this.imagePath2,
    this.imagePath3,
    this.lastUpdatedBy,
    this.lastUpdatedDate,
    this.isNewItem = 0,
  });

  // ==================== Factory Constructors ====================

  /// Create AssetModel from database map
  factory AssetModel.fromMap(Map<String, dynamic> map) {
    return AssetModel(
      id: map['id'] as int?,
      serialNo: map['serial_no'] as int?,
      description: map['description'] as String,
      oldCode: map['old_code'] as String?,
      newCode: map['new_code'] as String,
      bookBalance: map['book_balance'] as int? ?? 0,
      physicalBalance: map['physical_balance'] as int? ?? 0,
      excess: map['excess'] as int? ?? 0,
      shortage: map['shortage'] as int? ?? 0,
      remarks: map['remarks'] as String?,
      surveyStatus: map['survey_status'] as String?,
      imagePath1: map['image_path_1'] as String?,
      imagePath2: map['image_path_2'] as String?,
      imagePath3: map['image_path_3'] as String?,
      lastUpdatedBy: map['last_updated_by'] as String?,
      lastUpdatedDate: map['last_updated_date'] as String?,
      isNewItem: map['is_new_item'] as int? ?? 0,
    );
  }

  /// Create AssetModel from CSV row (for master import)
  /// Expected CSV columns: serial_no, description, old_code, new_code, book_balance
  factory AssetModel.fromCsvRow(List<dynamic> row) {
    return AssetModel(
      serialNo: int.tryParse(row[0].toString()),
      description: row[1].toString(),
      oldCode: row[2].toString(),
      newCode: row[3].toString(),
      bookBalance: int.tryParse(row[4].toString()) ?? 0,
    );
  }

  // ==================== Conversion Methods ====================

  /// Convert to database map
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'serial_no': serialNo,
      'description': description,
      'old_code': oldCode,
      'new_code': newCode,
      'book_balance': bookBalance,
      'physical_balance': physicalBalance,
      'excess': excess,
      'shortage': shortage,
      'remarks': remarks,
      'survey_status': surveyStatus,
      'image_path_1': imagePath1,
      'image_path_2': imagePath2,
      'image_path_3': imagePath3,
      'last_updated_by': lastUpdatedBy,
      'last_updated_date': lastUpdatedDate,
      'is_new_item': isNewItem,
    };
  }

  /// Convert to CSV row for export
  List<dynamic> toCsvRow() {
    return [
      serialNo ?? '',
      description,
      oldCode ?? '',
      newCode,
      bookBalance,
      physicalBalance,
      excess,
      shortage,
      surveyStatus ?? '',
      remarks ?? '',
      imagePath1 ?? '',
      imagePath2 ?? '',
      imagePath3 ?? '',
      lastUpdatedBy ?? '',
      lastUpdatedDate ?? '',
      isNewItem,
    ];
  }

  // ==================== Helper Methods ====================

  /// Create a copy with updated fields
  AssetModel copyWith({
    int? id,
    int? serialNo,
    String? description,
    String? oldCode,
    String? newCode,
    int? bookBalance,
    int? physicalBalance,
    int? excess,
    int? shortage,
    String? remarks,
    String? surveyStatus,
    String? imagePath1,
    String? imagePath2,
    String? imagePath3,
    String? lastUpdatedBy,
    String? lastUpdatedDate,
    int? isNewItem,
  }) {
    return AssetModel(
      id: id ?? this.id,
      serialNo: serialNo ?? this.serialNo,
      description: description ?? this.description,
      oldCode: oldCode ?? this.oldCode,
      newCode: newCode ?? this.newCode,
      bookBalance: bookBalance ?? this.bookBalance,
      physicalBalance: physicalBalance ?? this.physicalBalance,
      excess: excess ?? this.excess,
      shortage: shortage ?? this.shortage,
      remarks: remarks ?? this.remarks,
      surveyStatus: surveyStatus ?? this.surveyStatus,
      imagePath1: imagePath1 ?? this.imagePath1,
      imagePath2: imagePath2 ?? this.imagePath2,
      imagePath3: imagePath3 ?? this.imagePath3,
      lastUpdatedBy: lastUpdatedBy ?? this.lastUpdatedBy,
      lastUpdatedDate: lastUpdatedDate ?? this.lastUpdatedDate,
      isNewItem: isNewItem ?? this.isNewItem,
    );
  }

  /// Calculate excess and shortage based on physical and book balance
  static Map<String, int> calculateDifferences(int physical, int book) {
    final diff = physical - book;
    return {
      'excess': diff > 0 ? diff : 0,
      'shortage': diff < 0 ? -diff : 0,
    };
  }

  /// Check if asset has been surveyed (updated by field officer)
  bool get isSurveyed {
    return lastUpdatedBy != null && lastUpdatedBy!.isNotEmpty;
  }

  /// Check if asset has images attached
  bool get hasImages {
    return imagePath1 != null || imagePath2 != null || imagePath3 != null;
  }

  /// Get count of attached images
  int get imageCount {
    int count = 0;
    if (imagePath1 != null && imagePath1!.isNotEmpty) count++;
    if (imagePath2 != null && imagePath2!.isNotEmpty) count++;
    if (imagePath3 != null && imagePath3!.isNotEmpty) count++;
    return count;
  }

  @override
  String toString() {
    return 'AssetModel(id: $id, newCode: $newCode, description: $description, '
        'bookBalance: $bookBalance, physicalBalance: $physicalBalance, '
        'status: $surveyStatus, surveyed: $isSurveyed)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is AssetModel &&
        other.id == id &&
        other.newCode == newCode &&
        other.description == description;
  }

  @override
  int get hashCode => id.hashCode ^ newCode.hashCode ^ description.hashCode;
}
