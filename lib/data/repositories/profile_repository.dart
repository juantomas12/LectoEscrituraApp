import 'package:hive/hive.dart';

import '../../domain/models/user_profile.dart';

class ProfileRepository {
  static const _profileBoxName = 'profile_box';
  static const _profileKey = 'local_profile';

  Future<void> init() async {
    await Hive.openBox<Map>(_profileBoxName);
    final box = Hive.box<Map>(_profileBoxName);
    if (!box.containsKey(_profileKey)) {
      final profile = UserProfile(
        id: 'LOCAL-USER',
        displayName: 'ESTUDIANTE LOCAL',
        createdAt: DateTime.now(),
      );
      await box.put(_profileKey, profile.toMap());
    }
  }

  UserProfile loadProfile() {
    final box = Hive.box<Map>(_profileBoxName);
    return UserProfile.fromMap(box.get(_profileKey));
  }
}
