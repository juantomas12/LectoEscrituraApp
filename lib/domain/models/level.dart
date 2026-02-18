enum AppLevel { uno, dos, tres, cuatro, cinco }

typedef Level = AppLevel;

extension AppLevelX on AppLevel {
  int get value => switch (this) {
    AppLevel.uno => 1,
    AppLevel.dos => 2,
    AppLevel.tres => 3,
    AppLevel.cuatro => 4,
    AppLevel.cinco => 5,
  };

  String get label => 'NIVEL $value';

  static AppLevel fromInt(int value) {
    return AppLevel.values.firstWhere(
      (level) => level.value == value,
      orElse: () => AppLevel.uno,
    );
  }
}
