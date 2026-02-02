import 'package:hive/hive.dart';

part 'survey_entry.g.dart';

@HiveType(typeId: 1)
class SurveyEntry {
  @HiveField(0)
  final DateTime timestamp;

  @HiveField(1)
  final int usabilityRating;      // 1–5

  @HiveField(2)
  final int featureRating;        // 1–5

  @HiveField(3)
  final String comments;

  SurveyEntry({
    required this.timestamp,
    required this.usabilityRating,
    required this.featureRating,
    required this.comments,
  });
}
