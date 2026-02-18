enum Difficulty { primaria, secundaria }

extension DifficultyX on Difficulty {
  String get label => switch (this) {
    Difficulty.primaria => 'PRIMARIA',
    Difficulty.secundaria => 'SECUNDARIA',
  };
}
