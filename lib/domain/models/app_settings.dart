import 'difficulty.dart';

class AppSettings {
  const AppSettings({
    this.audioEnabled = true,
    this.highContrast = false,
    this.dyslexiaMode = false,
    this.accentTolerance = true,
    this.showHints = true,
    this.defaultDifficulty = Difficulty.primaria,
    this.unlockThreshold = 0,
  });

  final bool audioEnabled;
  final bool highContrast;
  final bool dyslexiaMode;
  final bool accentTolerance;
  final bool showHints;
  final Difficulty defaultDifficulty;
  final int unlockThreshold;

  AppSettings copyWith({
    bool? audioEnabled,
    bool? highContrast,
    bool? dyslexiaMode,
    bool? accentTolerance,
    bool? showHints,
    Difficulty? defaultDifficulty,
    int? unlockThreshold,
  }) {
    return AppSettings(
      audioEnabled: audioEnabled ?? this.audioEnabled,
      highContrast: highContrast ?? this.highContrast,
      dyslexiaMode: dyslexiaMode ?? this.dyslexiaMode,
      accentTolerance: accentTolerance ?? this.accentTolerance,
      showHints: showHints ?? this.showHints,
      defaultDifficulty: defaultDifficulty ?? this.defaultDifficulty,
      unlockThreshold: unlockThreshold ?? this.unlockThreshold,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'audioEnabled': audioEnabled,
      'highContrast': highContrast,
      'dyslexiaMode': dyslexiaMode,
      'accentTolerance': accentTolerance,
      'showHints': showHints,
      'defaultDifficulty': defaultDifficulty.name,
      'unlockThreshold': unlockThreshold,
    };
  }

  factory AppSettings.fromMap(Map<dynamic, dynamic>? map) {
    if (map == null || map.isEmpty) {
      return const AppSettings();
    }
    return AppSettings(
      audioEnabled: map['audioEnabled'] as bool? ?? true,
      highContrast: map['highContrast'] as bool? ?? false,
      dyslexiaMode: map['dyslexiaMode'] as bool? ?? false,
      accentTolerance: map['accentTolerance'] as bool? ?? true,
      showHints: map['showHints'] as bool? ?? true,
      defaultDifficulty:
          (map['defaultDifficulty'] ?? 'primaria').toString() == 'secundaria'
          ? Difficulty.secundaria
          : Difficulty.primaria,
      unlockThreshold: map['unlockThreshold'] as int? ?? 0,
    );
  }
}
