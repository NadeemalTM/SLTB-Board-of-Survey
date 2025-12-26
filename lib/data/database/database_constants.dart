/// Constants for database operations
class DatabaseConstants {
  // Database configuration
  static const String databaseName = 'sltb_survey.db';
  static const int databaseVersion = 1;

  // Table names
  static const String assetsTable = 'assets';

  // Column names for assets table
  static const String columnId = 'id';
  static const String columnSerialNo = 'serial_no';
  static const String columnDescription = 'description';
  static const String columnOldCode = 'old_code';
  static const String columnNewCode = 'new_code';
  static const String columnBookBalance = 'book_balance';
  static const String columnPhysicalBalance = 'physical_balance';
  static const String columnExcess = 'excess';
  static const String columnShortage = 'shortage';
  static const String columnRemarks = 'remarks';
  static const String columnSurveyStatus = 'survey_status';
  static const String columnImagePath1 = 'image_path_1';
  static const String columnImagePath2 = 'image_path_2';
  static const String columnImagePath3 = 'image_path_3';
  static const String columnLastUpdatedBy = 'last_updated_by';
  static const String columnLastUpdatedDate = 'last_updated_date';
  static const String columnIsNewItem = 'is_new_item';
}
