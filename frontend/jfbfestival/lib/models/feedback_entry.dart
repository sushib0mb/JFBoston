import 'package:hive/hive.dart';

part 'feedback_entry.g.dart';

@HiveType(typeId: 0)
class FeedbackEntry {
  @HiveField(0)
  final String subject;

  @HiveField(1)
  final String message;

  @HiveField(2)
  final DateTime timestamp;

  FeedbackEntry({
    required this.subject,
    required this.message,
    required this.timestamp,
  });
}
