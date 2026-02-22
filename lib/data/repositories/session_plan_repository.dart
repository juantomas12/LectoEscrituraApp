import 'package:hive/hive.dart';

import '../../domain/models/session_plan.dart';

class SessionPlanRepository {
  static const _boxName = 'session_plan_box';

  Future<void> init() async {
    await Hive.openBox<Map>(_boxName);
  }

  Box<Map> get _box => Hive.box<Map>(_boxName);

  Future<void> save(SessionPlan plan) async {
    await _box.put(plan.id, plan.toMap());
  }

  List<SessionPlan> getAll() {
    final output = _box.values.map(SessionPlan.fromMap).toList();
    output.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return output;
  }

  Future<void> delete(String id) async {
    await _box.delete(id);
  }
}
