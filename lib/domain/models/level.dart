enum AppLevel { uno, dos, tres }

typedef Level = AppLevel;

extension AppLevelX on AppLevel {
  int get value => switch (this) {
    AppLevel.uno => 1,
    AppLevel.dos => 2,
    AppLevel.tres => 3,
  };

  String get label => 'NIVEL $value';

  static AppLevel fromInt(int value) {
    return AppLevel.values.firstWhere(
      (level) => level.value == value,
      orElse: () => AppLevel.uno,
    );
  }
}
