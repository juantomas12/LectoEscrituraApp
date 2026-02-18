import 'package:hive/hive.dart';

class ImageOverrideRepository {
  static const _boxName = 'image_override_box';

  Future<void> init() async {
    await Hive.openBox<String>(_boxName);
  }

  Box<String> get _box => Hive.box<String>(_boxName);

  Map<String, String> loadOverrides() {
    return Map<String, String>.from(_box.toMap());
  }

  Future<void> setOverride({
    required String itemId,
    required String imageAsset,
  }) async {
    await _box.put(itemId, imageAsset);
  }

  Future<void> removeOverride(String itemId) async {
    await _box.delete(itemId);
  }

  Future<void> clear() async {
    await _box.clear();
  }
}
