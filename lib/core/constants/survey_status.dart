/// Survey status constants for assets
class SurveyStatus {
  static const String pending = 'Pending';
  static const String verified = 'Verified';
  static const String damaged = 'Damaged';
  static const String missing = 'Missing';
  
  static List<String> get allValues => [
        pending,
        verified,
        damaged,
        missing,
      ];
}
