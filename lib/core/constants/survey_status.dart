/// Survey status constants for assets
class SurveyStatus {
  static const String good = 'Good';
  static const String broken = 'Broken';
  static const String missing = 'Missing';
  
  static List<String> get allValues => [
        good,
        broken,
        missing,
      ];
  
  static List<String> get values => allValues;
  
  /// Convert old status values to new ones for backward compatibility
  static String migrateStatus(String? oldStatus) {
    if (oldStatus == null) return good;
    
    switch (oldStatus.toLowerCase()) {
      case 'verified':
      case 'good':
      case 'pending':
        return good;
      case 'damaged':
      case 'broken':
        return broken;
      case 'missing':
        return missing;
      default:
        return good;
    }
  }
}
