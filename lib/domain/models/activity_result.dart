import 'activity_type.dart';
import 'category.dart';
import 'level.dart';

class ActivityResult {
  ActivityResult({
    required this.id,
    required this.category,
    required this.level,
    required this.activityType,
    required this.correct,
    required this.incorrect,
    required this.durationInSeconds,
    required this.bestStreak,
    required this.createdAt,
  });

  final String id;
  final AppCategory category;
  final AppLevel level;
  final ActivityType activityType;
  final int correct;
  final int incorrect;
  final int durationInSeconds;
  final int bestStreak;
  final DateTime createdAt;

  double get accuracy {
    final total = correct + incorrect;
    if (total == 0) {
      return 0;
    }
    return correct / total;
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'category': category.label,
      'level': level.value,
      'activityType': activityType.key,
      'correct': correct,
      'incorrect': incorrect,
      'durationInSeconds': durationInSeconds,
      'bestStreak': bestStreak,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory ActivityResult.fromMap(Map<dynamic, dynamic> map) {
    return ActivityResult(
      id: (map['id'] ?? '').toString(),
      category: AppCategoryX.fromLabel((map['category'] ?? '').toString()),
      level: AppLevelX.fromInt((map['level'] ?? 1) as int),
      activityType: ActivityTypeX.fromKey(
        (map['activityType'] ?? '').toString(),
      ),
      correct: (map['correct'] ?? 0) as int,
      incorrect: (map['incorrect'] ?? 0) as int,
      durationInSeconds: (map['durationInSeconds'] ?? 0) as int,
      bestStreak: (map['bestStreak'] ?? 0) as int,
      createdAt:
          DateTime.tryParse((map['createdAt'] ?? '').toString()) ??
          DateTime.now(),
    );
  }
}
