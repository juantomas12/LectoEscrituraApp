import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/providers/app_providers.dart';
import '../../domain/models/activity_result.dart';
import '../../domain/models/activity_type.dart';
import '../../domain/models/category.dart';
import '../../domain/models/item_progress.dart';
import '../../domain/models/level.dart';

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
