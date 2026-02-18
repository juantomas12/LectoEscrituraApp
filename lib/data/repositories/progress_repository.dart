import 'package:hive/hive.dart';

import '../../domain/models/activity_result.dart';
import '../../domain/models/category.dart';
import '../../domain/models/item_progress.dart';
import '../../domain/models/level.dart';

class ProgressRepository {
  static const _resultsBoxName = 'results_box';
  static const _itemProgressBoxName = 'item_progress_box';

  Future<void> init() async {
    await Hive.openBox<Map>(_resultsBoxName);
    await Hive.openBox<Map>(_itemProgressBoxName);
  }

  Box<Map> get _resultsBox => Hive.box<Map>(_resultsBoxName);
  Box<Map> get _itemProgressBox => Hive.box<Map>(_itemProgressBoxName);

  Future<void> saveActivityResult(ActivityResult result) async {
    await _resultsBox.add(result.toMap());
  }

  List<ActivityResult> getAllResults() {
    return _resultsBox.values.map(ActivityResult.fromMap).toList();
  }

  int countCompletedFor({
    required AppCategory category,
    required AppLevel level,
  }) {
    return getAllResults()
        .where((result) => result.category == category && result.level == level)
        .length;
  }

  Map<String, ItemProgress> getItemProgressMap() {
    final output = <String, ItemProgress>{};
    for (final key in _itemProgressBox.keys) {
      final value = _itemProgressBox.get(key);
      if (value == null) {
        continue;
      }
      final progress = ItemProgress.fromMap(value);
      output[progress.itemId] = progress;
    }
    return output;
  }

  Future<void> registerItemAttempt({
    required String itemId,
    required bool correct,
  }) async {
    final current = _itemProgressBox.get(itemId);
    final progress = current == null
        ? ItemProgress(itemId: itemId)
        : ItemProgress.fromMap(current);

    final updated = progress.registerAttempt(correct);
    await _itemProgressBox.put(itemId, updated.toMap());
  }
}
