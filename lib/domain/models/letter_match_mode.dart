enum LetterMatchMode { contiene, inicia, medio, termina }

extension LetterMatchModeX on LetterMatchMode {
  String get label => switch (this) {
    LetterMatchMode.contiene => 'CONTIENE',
    LetterMatchMode.inicia => 'INICIA CON',
    LetterMatchMode.medio => 'TIENE EN MEDIO',
    LetterMatchMode.termina => 'TERMINA CON',
  };

  String get shortLabel => switch (this) {
    LetterMatchMode.contiene => 'CONTIENE',
    LetterMatchMode.inicia => 'INICIO',
    LetterMatchMode.medio => 'MEDIO',
    LetterMatchMode.termina => 'FINAL',
  };
}
