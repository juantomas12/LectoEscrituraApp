import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/providers/app_providers.dart';
import '../../core/utils/text_utils.dart';
import '../../domain/models/activity_result.dart';
import '../../domain/models/activity_type.dart';
import '../../domain/models/category.dart';
import '../../domain/models/item_progress.dart';
import '../../domain/models/level.dart';

class ActivityPerformance {
  const ActivityPerformance({
    required this.activityType,
    required this.sessions,
    required this.correct,
    required this.incorrect,
    required this.avgDurationSec,
  });

  final ActivityType activityType;
  final int sessions;
  final int correct;
  final int incorrect;
  final int avgDurationSec;

  int get attempts => correct + incorrect;
  double get accuracy => attempts == 0 ? 0 : correct / attempts;
}

class CategoryPerformance {
  const CategoryPerformance({
    required this.category,
    required this.sessions,
    required this.correct,
    required this.incorrect,
  });

  final AppCategory category;
  final int sessions;
  final int correct;
  final int incorrect;

  int get attempts => correct + incorrect;
  double get accuracy => attempts == 0 ? 0 : correct / attempts;
}

class LetterPerformance {
  const LetterPerformance({
    required this.letter,
    required this.totalAttempts,
    required this.incorrectAttempts,
  });

  final String letter;
  final int totalAttempts;
  final int incorrectAttempts;

  int get correctAttempts => totalAttempts - incorrectAttempts;
  double get errorRate =>
      totalAttempts == 0 ? 0 : incorrectAttempts / totalAttempts;
  double get masteryRate =>
      totalAttempts == 0 ? 0 : correctAttempts / totalAttempts;
}

class ProgressViewModel extends Notifier<int> {
  @override
  int build() {
    return 0;
  }

  Map<String, ItemProgress> getItemProgressMap() {
    return ref.read(progressRepositoryProvider).getItemProgressMap();
  }

  Map<String, ItemProgress> getGameItemProgressMap() {
    return ref.read(progressRepositoryProvider).getGameItemProgressMap();
  }

  List<ActivityResult> getAllResults() {
    return ref.read(progressRepositoryProvider).getAllResults();
  }

  List<ActivityResult> getRecentResults({int limit = 10}) {
    final all = getAllResults()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return all.take(limit).toList();
  }

  List<ActivityResult> getResultsByActivity(ActivityType activityType) {
    final all = getAllResults();
    all.sort((a, b) => a.createdAt.compareTo(b.createdAt));
    return all.where((result) => result.activityType == activityType).toList();
  }

  List<ActivityPerformance> activityPerformance({
    List<ActivityResult>? source,
  }) {
    final grouped = <ActivityType, List<ActivityResult>>{};
    for (final result in source ?? getAllResults()) {
      grouped
          .putIfAbsent(result.activityType, () => <ActivityResult>[])
          .add(result);
    }

    final output =
        grouped.entries.map((entry) {
          final sessions = entry.value.length;
          final correct = entry.value.fold<int>(0, (sum, r) => sum + r.correct);
          final incorrect = entry.value.fold<int>(
            0,
            (sum, r) => sum + r.incorrect,
          );
          final avgDurationSec = sessions == 0
              ? 0
              : (entry.value.fold<int>(
                          0,
                          (sum, r) => sum + r.durationInSeconds,
                        ) /
                        sessions)
                    .round();
          return ActivityPerformance(
            activityType: entry.key,
            sessions: sessions,
            correct: correct,
            incorrect: incorrect,
            avgDurationSec: avgDurationSec,
          );
        }).toList()..sort(
          (a, b) => a.activityType.index.compareTo(b.activityType.index),
        );

    return output;
  }

  List<CategoryPerformance> categoryPerformance({
    List<ActivityResult>? source,
  }) {
    final grouped = <AppCategory, List<ActivityResult>>{};
    for (final result in source ?? getAllResults()) {
      grouped
          .putIfAbsent(result.category, () => <ActivityResult>[])
          .add(result);
    }

    return AppCategoryLists.reales.map((category) {
      final bucket = grouped[category] ?? const <ActivityResult>[];
      final sessions = bucket.length;
      final correct = bucket.fold<int>(0, (sum, r) => sum + r.correct);
      final incorrect = bucket.fold<int>(0, (sum, r) => sum + r.incorrect);
      return CategoryPerformance(
        category: category,
        sessions: sessions,
        correct: correct,
        incorrect: incorrect,
      );
    }).toList();
  }

  List<LetterPerformance> letterPerformance({int minAttempts = 1}) {
    final progressMap = getItemProgressMap();
    final items = ref.read(datasetRepositoryProvider).getAllItems();
    final itemById = {for (final item in items) item.id: item};
    const targetLetters = [
      'A',
      'E',
      'I',
      'O',
      'U',
      'L',
      'M',
      'N',
      'P',
      'R',
      'S',
      'T',
      'C',
      'D',
      'B',
      'G',
    ];

    final totals = <String, int>{for (final letter in targetLetters) letter: 0};
    final incorrects = <String, int>{
      for (final letter in targetLetters) letter: 0,
    };

    for (final progress in progressMap.values) {
      final word = itemById[progress.itemId]?.word ?? '';
      final attempts = progress.correctAttempts + progress.incorrectAttempts;
      if (attempts <= 0) {
        continue;
      }
      for (final letter in targetLetters) {
        if (containsLetter(word, letter)) {
          totals[letter] = (totals[letter] ?? 0) + attempts;
          incorrects[letter] =
              (incorrects[letter] ?? 0) + progress.incorrectAttempts;
        }
      }
    }

    final stats = <LetterPerformance>[];
    for (final letter in targetLetters) {
      final total = totals[letter] ?? 0;
      if (total < minAttempts) {
        continue;
      }
      stats.add(
        LetterPerformance(
          letter: letter,
          totalAttempts: total,
          incorrectAttempts: incorrects[letter] ?? 0,
        ),
      );
    }
    return stats;
  }

  int recommendedLevelForGame(
    ActivityType activityType, {
    int maxLevel = 3,
    int windowSize = 6,
  }) {
    final recent = getResultsByActivity(
      activityType,
    ).reversed.take(windowSize).toList();
    if (recent.isEmpty) {
      return 1;
    }

    final averageAccuracy =
        recent.fold<double>(0, (sum, result) => sum + result.accuracy) /
        recent.length;
    final averageIncorrect =
        recent.fold<double>(0, (sum, result) => sum + result.incorrect) /
        recent.length;
    final lowScores = recent.where((result) => result.accuracy < 0.5).length;

    if (lowScores >= 2 || averageAccuracy < 0.6) {
      return 1;
    }
    if (averageAccuracy >= 0.85 && averageIncorrect <= 1) {
      return maxLevel >= 3 ? 3 : maxLevel;
    }
    return maxLevel >= 2 ? 2 : 1;
  }

  Map<AppCategory, double> categoryAccuracyMap() {
    final map = <AppCategory, List<ActivityResult>>{};
    for (final result in getAllResults()) {
      map.putIfAbsent(result.category, () => <ActivityResult>[]).add(result);
    }

    final output = <AppCategory, double>{};
    for (final category in AppCategoryLists.reales) {
      final bucket = map[category] ?? const <ActivityResult>[];
      if (bucket.isEmpty) {
        output[category] = 0;
        continue;
      }
      final accuracy =
          bucket.fold<double>(0, (sum, result) => sum + result.accuracy) /
          bucket.length;
      output[category] = accuracy;
    }
    return output;
  }

  Map<String, int> hardestLetters({int top = 6}) {
    final progressMap = getItemProgressMap();
    final items = ref.read(datasetRepositoryProvider).getAllItems();
    final itemById = {for (final item in items) item.id: item};
    const targetLetters = [
      'A',
      'E',
      'I',
      'O',
      'U',
      'L',
      'M',
      'N',
      'P',
      'R',
      'S',
      'T',
    ];
    final scoreByLetter = <String, int>{
      for (final letter in targetLetters) letter: 0,
    };

    for (final progress in progressMap.values) {
      if (progress.incorrectAttempts <= 0) {
        continue;
      }
      final word = itemById[progress.itemId]?.word ?? '';
      for (final letter in targetLetters) {
        if (containsLetter(word, letter)) {
          scoreByLetter[letter] =
              (scoreByLetter[letter] ?? 0) + progress.incorrectAttempts;
        }
      }
    }

    final sorted = scoreByLetter.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final output = <String, int>{};
    for (final entry in sorted.where((entry) => entry.value > 0).take(top)) {
      output[entry.key] = entry.value;
    }
    return output;
  }

  int countCompletedFor({
    required AppCategory category,
    required AppLevel level,
  }) {
    return ref
        .read(progressRepositoryProvider)
        .countCompletedFor(category: category, level: level);
  }

  Future<void> registerAttempt({
    required String itemId,
    required bool correct,
    ActivityType? activityType,
  }) async {
    await ref
        .read(progressRepositoryProvider)
        .registerItemAttempt(
          itemId: itemId,
          correct: correct,
          activityType: activityType,
        );
    state++;
  }

  Future<void> saveResult(ActivityResult result) async {
    await ref.read(progressRepositoryProvider).saveActivityResult(result);
    state++;
  }
}

final progressViewModelProvider = NotifierProvider<ProgressViewModel, int>(
  ProgressViewModel.new,
);

final itemProgressMapProvider = Provider<Map<String, ItemProgress>>((ref) {
  ref.watch(progressViewModelProvider);
  return ref.read(progressViewModelProvider.notifier).getItemProgressMap();
});

final gameItemProgressMapProvider = Provider<Map<String, ItemProgress>>((ref) {
  ref.watch(progressViewModelProvider);
  return ref.read(progressViewModelProvider.notifier).getGameItemProgressMap();
});
