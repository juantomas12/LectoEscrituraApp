import 'package:hive/hive.dart';

import '../../domain/models/ai_resource.dart';

class AiResourceRepository {
  static const _boxName = 'ai_resources_box';

  Future<void> init() async {
    await Hive.openBox<Map>(_boxName);
  }

  Box<Map> get _box => Hive.box<Map>(_boxName);

  Future<void> save(AiResource resource) async {
    await _box.put(resource.id, resource.toMap());
  }

  List<AiResource> getAll() {
    final output = _box.values.map(AiResource.fromMap).toList();
    output.sort((a, b) {
      if (a.isFavorite != b.isFavorite) {
        return a.isFavorite ? -1 : 1;
      }
      return b.createdAt.compareTo(a.createdAt);
    });
    return output;
  }

  Future<void> delete(String id) async {
    await _box.delete(id);
  }
}
