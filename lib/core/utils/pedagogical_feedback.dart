import 'text_utils.dart';

class PedagogicalFeedback {
  static String positive({
    required int streak,
    required int totalCorrect,
  }) {
    if (streak >= 6) {
      return 'EXCELENTE RACHA: $streak';
    }
    if (streak >= 3) {
      return 'MUY BIEN. SIGUE ASÍ';
    }
    if (totalCorrect <= 1) {
      return 'BUEN INICIO. CONTINÚA';
    }
    return 'CORRECTO';
  }

  static String retry({
    required int attemptsOnCurrent,
    String? hint,
  }) {
    if (attemptsOnCurrent <= 1) {
      return 'CASI. REVISA DESPACIO';
    }
    if (hint != null && hint.isNotEmpty) {
      return 'PISTA: $hint';
    }
    return 'INTÉNTALO DE NUEVO';
  }

  static String writingError({
    required String expected,
    required String input,
    required int attemptsOnCurrent,
    required bool showHints,
  }) {
    final cleanExpected = normalizeWordForLetters(expected);
    final cleanInput = normalizeWordForLetters(input);

    if (cleanInput.isEmpty) {
      return 'ESCRIBE LA PALABRA PARA COMPROBAR';
    }

    String base;
    if (cleanInput.length < cleanExpected.length) {
      base = 'TE FALTAN LETRAS';
    } else if (cleanInput.length > cleanExpected.length) {
      base = 'SOBRAN LETRAS';
    } else if (cleanExpected.isNotEmpty && cleanInput[0] != cleanExpected[0]) {
      base = 'REVISA LA PRIMERA LETRA: ${cleanExpected[0]}';
    } else if (cleanExpected.isNotEmpty &&
        cleanInput[cleanInput.length - 1] != cleanExpected[cleanExpected.length - 1]) {
      base = 'REVISA LA ÚLTIMA LETRA: ${cleanExpected[cleanExpected.length - 1]}';
    } else {
      base = 'CASI CORRECTO. REVISA CADA LETRA';
    }

    if (showHints && attemptsOnCurrent >= 2) {
      return '$base. PISTA: ${buildSemiCopyHint(expected)}';
    }

    return base;
  }
}
