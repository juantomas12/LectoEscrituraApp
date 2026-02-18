import '../../domain/models/activity_type.dart';
import '../../domain/models/category.dart';
import '../../domain/models/difficulty.dart';
import '../../domain/models/item.dart';
import '../../domain/models/item_progress.dart';
import '../../domain/models/level.dart';

abstract class DatasetRepository {
  Future<void> load();

  List<Item> getAllItems();

  List<Item> getItems({
    required AppCategory category,
    required AppLevel level,
    required ActivityType activityType,
  });

  List<Item> getPrioritizedItems({
    required AppCategory category,
    required AppLevel level,
    required ActivityType activityType,
    required Difficulty difficulty,
    required Map<String, ItemProgress> progressMap,
    required int limit,
  });

  void setImageOverrides(Map<String, String> overrides);

  Map<String, String> getImageOverrides();
}
