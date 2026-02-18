import 'package:hive/hive.dart';

import '../../domain/models/app_settings.dart';

class SettingsRepository {
  static const _settingsBoxName = 'settings_box';
  static const _settingsKey = 'app_settings';

  Future<void> init() async {
    await Hive.openBox<Map>(_settingsBoxName);
  }

  Box<Map> get _box => Hive.box<Map>(_settingsBoxName);

  AppSettings loadSettings() {
    return AppSettings.fromMap(_box.get(_settingsKey));
  }

  Future<void> saveSettings(AppSettings settings) async {
    await _box.put(_settingsKey, settings.toMap());
  }
}
