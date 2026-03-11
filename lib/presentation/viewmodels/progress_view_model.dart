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

enum BadgeTier { none, bronze, silver, gold }

extension BadgeTierX on BadgeTier {
  String get label => switch (this) {
    BadgeTier.none => 'SIN INSIGNIA',
    BadgeTier.bronze => 'BRONCE',
    BadgeTier.silver => 'PLATA',
    BadgeTier.gold => 'ORO',
  };
}

class RewardsSummary {
  const RewardsSummary({
    required this.currentStreak,
    required this.longestStreak,
    required this.unlockedBadges,
    required this.activeToday,
    required this.badgesByCategory,
  });

  final int currentStreak;
  final int longestStreak;
  final int unlockedBadges;
  final bool activeToday;
  final Map<AppCategory, BadgeTier> badgesByCategory;
}

class AdaptivePlanRecommendation {
  const AdaptivePlanRecommendation({
    required this.activityType,
    required this.category,
    required this.level,
    required this.targetLetters,
    required this.reason,
  });

  final ActivityType activityType;
  final AppCategory category;
  final int level;
  final List<String> targetLetters;
  final String reason;
}

class ProgressViewModel extends Notifier<int> {
  static const _adaptableGames = [
    ActivityType.imagenPalabra,
    ActivityType.escribirPalabra,
    ActivityType.palabraPalabra,
    ActivityType.imagenFrase,
    ActivityType.sonidos,
    ActivityType.letraObjetivo,
    ActivityType.cambioExacto,
    ActivityType.discriminacion,
    ActivityType.discriminacionInversa,
  ];

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

  AdaptivePlanRecommendation adaptivePlanRecommendation({int windowSize = 18}) {
    final recent = getAllResults()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    if (recent.isEmpty) {
      return const AdaptivePlanRecommendation(
        activityType: ActivityType.imagenPalabra,
        category: AppCategory.cosasDeCasa,
        level: 1,
        targetLetters: ['A', 'E', 'O'],
        reason: 'COMIENZA CON EL JUEGO BASE PARA OBTENER DATOS.',
      );
    }

    final scoped = recent.take(windowSize).toList();
    var selectedGame = ActivityType.imagenPalabra;
    var bestNeedScore = -1.0;

    for (final game in _adaptableGames) {
      final gameResults = scoped
          .where((result) => result.activityType == game)
          .toList();
      if (gameResults.isEmpty) {
        continue;
      }
      final attempts = gameResults.fold<int>(
        0,
        (sum, result) => sum + result.correct + result.incorrect,
      );
      if (attempts <= 0) {
        continue;
      }
      final incorrect = gameResults.fold<int>(
        0,
        (sum, result) => sum + result.incorrect,
      );
      final accuracy =
          gameResults.fold<double>(0, (sum, result) => sum + result.accuracy) /
          gameResults.length;
      final needScore =
          (incorrect / attempts) * 0.60 +
          (1 - accuracy) * 0.35 +
          (gameResults.length / windowSize) * 0.05;

      if (needScore > bestNeedScore) {
        bestNeedScore = needScore;
        selectedGame = game;
      }
    }

    if (bestNeedScore < 0) {
      selectedGame = recent.first.activityType;
      if (!_adaptableGames.contains(selectedGame)) {
        selectedGame = ActivityType.imagenPalabra;
      }
    }

    final category = _recommendedCategoryForGame(selectedGame, scoped);
    final maxLevel = _maxLevelForGame(selectedGame);
    final level = recommendedLevelForGame(selectedGame, maxLevel: maxLevel);
    final letters = _focusLettersForGame(selectedGame, top: 3);

    final reason = letters.isEmpty
        ? 'SE RECOMIENDA REFORZAR ${selectedGame.label} EN ${category.label}.'
        : 'REFUERZA ${letters.join(', ')} EN ${category.label}.';

    return AdaptivePlanRecommendation(
      activityType: selectedGame,
      category: category,
      level: level,
      targetLetters: letters,
      reason: reason,
    );
  }

  RewardsSummary rewardsSummary() {
    final results = getAllResults()
      ..sort((a, b) => a.createdAt.compareTo(b.createdAt));

    final badges = <AppCategory, BadgeTier>{};
    for (final category in AppCategoryLists.reales) {
      badges[category] = _badgeTierForCategory(results, category);
    }

    final unlocked = badges.values
        .where((badge) => badge != BadgeTier.none)
        .length;

    final activeDays =
        results.map((result) => _onlyDate(result.createdAt)).toSet().toList()
          ..sort((a, b) => a.compareTo(b));

    final currentStreak = _currentStreak(activeDays);
    final longestStreak = _longestStreak(activeDays);
    final latestDay = activeDays.isEmpty ? null : activeDays.last;
    final activeToday =
        latestDay != null && latestDay == _onlyDate(DateTime.now());

    return RewardsSummary(
      currentStreak: currentStreak,
      longestStreak: longestStreak,
      unlockedBadges: unlocked,
      activeToday: activeToday,
      badgesByCategory: badges,
    );
  }

  int _maxLevelForGame(ActivityType activityType) {
    return switch (activityType) {
      ActivityType.letraObjetivo => 3,
      ActivityType.cambioExacto => 3,
      ActivityType.sonidos => 3,
      ActivityType.discriminacion => 3,
      ActivityType.discriminacionInversa => 3,
      _ => 1,
    };
  }

  AppCategory _recommendedCategoryForGame(
    ActivityType activityType,
    List<ActivityResult> source,
  ) {
    final grouped = <AppCategory, List<ActivityResult>>{};
    for (final result in source) {
      if (result.activityType != activityType) {
        continue;
      }
      if (result.category == AppCategory.mixta) {
        continue;
      }
      grouped
          .putIfAbsent(result.category, () => <ActivityResult>[])
          .add(result);
    }

    if (grouped.isNotEmpty) {
      var selected = grouped.keys.first;
      var bestNeed = -1.0;

      for (final entry in grouped.entries) {
        final attempts = entry.value.fold<int>(
          0,
          (sum, result) => sum + result.correct + result.incorrect,
        );
        if (attempts <= 0) {
          continue;
        }
        final incorrect = entry.value.fold<int>(
          0,
          (sum, result) => sum + result.incorrect,
        );
        final need = incorrect / attempts;
        if (need > bestNeed) {
          bestNeed = need;
          selected = entry.key;
        }
      }
      return selected;
    }

    final byCategory = categoryAccuracyMap();
    var fallback = AppCategory.cosasDeCasa;
    var lowestAccuracy = double.infinity;
    for (final category in AppCategoryLists.reales) {
      final accuracy = byCategory[category] ?? 0;
      if (accuracy < lowestAccuracy) {
        lowestAccuracy = accuracy;
        fallback = category;
      }
    }
    return fallback;
  }

  List<String> _focusLettersForGame(ActivityType activityType, {int top = 3}) {
    final gameProgressMap = getGameItemProgressMap();
    final items = ref.read(datasetRepositoryProvider).getAllItems();
    final itemById = {for (final item in items) item.id: item};
    final scoreByLetter = <String, int>{};

    for (final entry in gameProgressMap.entries) {
      final separator = entry.key.indexOf('|');
      if (separator <= 0) {
        continue;
      }

      final gameKey = entry.key.substring(0, separator);
      if (gameKey != activityType.key) {
        continue;
      }

      final itemId = entry.key.substring(separator + 1);
      final item = itemById[itemId];
      if (item == null) {
        continue;
      }

      final progress = entry.value;
      if (progress.incorrectAttempts <= 0) {
        continue;
      }

      final word = item.word ?? (item.words.isNotEmpty ? item.words.first : '');
      final letters = normalizeWordForLetters(
        word,
      ).split('').where((char) => RegExp(r'[A-ZÑ]').hasMatch(char)).toSet();

      if (letters.isEmpty) {
        continue;
      }

      final weightedScore =
          progress.incorrectAttempts * 2 - progress.correctAttempts;
      final score = weightedScore > 0
          ? weightedScore
          : progress.incorrectAttempts;
      for (final letter in letters) {
        scoreByLetter[letter] = (scoreByLetter[letter] ?? 0) + score;
      }
    }

    if (scoreByLetter.isEmpty) {
      final fallback = hardestLetters(top: top);
      return fallback.keys.take(top).toList();
    }

    final sorted = scoreByLetter.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return sorted.take(top).map((entry) => entry.key).toList();
  }

  BadgeTier _badgeTierForCategory(
    List<ActivityResult> source,
    AppCategory category,
  ) {
    final bucket = source
        .where((result) => result.category == category)
        .toList();
    if (bucket.isEmpty) {
      return BadgeTier.none;
    }

    final sessions = bucket.length;
    final attempts = bucket.fold<int>(
      0,
      (sum, result) => sum + result.correct + result.incorrect,
    );
    final accuracy = attempts == 0
        ? 0
        : bucket.fold<double>(0, (sum, result) => sum + result.accuracy) /
              bucket.length;

    if (sessions >= 10 && accuracy >= 0.85) {
      return BadgeTier.gold;
    }
    if (sessions >= 6 && accuracy >= 0.75) {
      return BadgeTier.silver;
    }
    if (sessions >= 3 && accuracy >= 0.60) {
      return BadgeTier.bronze;
    }
    return BadgeTier.none;
  }

  DateTime _onlyDate(DateTime value) {
    return DateTime(value.year, value.month, value.day);
  }

  int _currentStreak(List<DateTime> sortedDays) {
    if (sortedDays.isEmpty) {
      return 0;
    }
    var streak = 1;
    var cursor = sortedDays.last;
    for (var i = sortedDays.length - 2; i >= 0; i--) {
      final expectedPrevious = cursor.subtract(const Duration(days: 1));
      if (sortedDays[i] == expectedPrevious) {
        streak++;
        cursor = sortedDays[i];
        continue;
      }
      break;
    }
    return streak;
  }

  int _longestStreak(List<DateTime> sortedDays) {
    if (sortedDays.isEmpty) {
      return 0;
    }
    var best = 1;
    var current = 1;
    for (var i = 1; i < sortedDays.length; i++) {
      final previous = sortedDays[i - 1];
      final expected = previous.add(const Duration(days: 1));
      if (sortedDays[i] == expected) {
        current++;
        if (current > best) {
          best = current;
        }
      } else {
        current = 1;
      }
    }
    return best;
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
