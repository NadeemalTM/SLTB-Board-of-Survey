/// Survey status options for assets
enum SurveyStatus {
  good('Good', 'හොඳයි'),
  broken('Broken', 'කැඩුණු'),
  repairable('Repairable', 'අලුත්වැඩියා කළ හැකි'),
  toBeDisposed('To be Disposed', 'ඉවත් කළ යුතු'),
  newFound('New Found', 'අලුතින් හමු වූ');

  final String englishLabel;
  final String sinhalaLabel;

  const SurveyStatus(this.englishLabel, this.sinhalaLabel);

  static List<String> get allValues =>
      SurveyStatus.values.map((e) => e.englishLabel).toList();

  static List<String> get allSinhalaValues =>
      SurveyStatus.values.map((e) => e.sinhalaLabel).toList();
}
