String toUpperSingleSpace(String value) {
  final normalizedSpaces = value.trim().replaceAll(RegExp(r'\s+'), ' ');
  return normalizedSpaces.toUpperCase();
}

String _stripAccents(String value) {
  const replacements = {
    'Á': 'A',
    'É': 'E',
    'Í': 'I',
    'Ó': 'O',
    'Ú': 'U',
    'Ü': 'U',
    'À': 'A',
    'È': 'E',
    'Ì': 'I',
    'Ò': 'O',
    'Ù': 'U',
  };

  var output = value;
  replacements.forEach((key, replacement) {
    output = output.replaceAll(key, replacement);
  });
  return output;
}

String normalizeForComparison(String raw, {required bool ignoreAccents}) {
  final upper = toUpperSingleSpace(raw);
  if (!ignoreAccents) {
    return upper;
  }
  return _stripAccents(upper);
}

String buildSemiCopyHint(String word) {
  final clean = toUpperSingleSpace(word).replaceAll(' ', '');
  if (clean.length <= 2) {
    return clean;
  }
  final buffer = StringBuffer();
  for (var i = 0; i < clean.length; i++) {
    if (i.isEven) {
      buffer.write(clean[i]);
    } else {
      buffer.write('_');
    }
    if (i < clean.length - 1) {
      buffer.write(' ');
    }
  }
  return buffer.toString();
}

int countWords(String phrase) {
  return toUpperSingleSpace(
    phrase,
  ).split(' ').where((value) => value.isNotEmpty).length;
}

String normalizeWordForLetters(String value) {
  return normalizeForComparison(value, ignoreAccents: true).replaceAll(' ', '');
}

String buildTraceGuide(String word) {
  final clean = normalizeWordForLetters(
    word,
  ).replaceAll(RegExp(r'[^A-ZÑ]'), '');
  if (clean.isEmpty) {
    return '';
  }
  return clean.split('').join(' · ');
}

List<String> splitIntoSpanishSyllables(String rawWord) {
  final word = normalizeWordForLetters(
    rawWord,
  ).replaceAll(RegExp(r'[^A-ZÑ]'), '');
  if (word.isEmpty) {
    return const [];
  }
  if (word.length <= 3) {
    return [word];
  }

  const vowels = 'AEIOU';
  final output = <String>[];
  var buffer = StringBuffer();

  bool isVowel(String value) => vowels.contains(value);

  for (var i = 0; i < word.length; i++) {
    final char = word[i];
    buffer.write(char);
    final hasNext = i + 1 < word.length;
    if (!hasNext) {
      break;
    }

    final next = word[i + 1];
    final hasNext2 = i + 2 < word.length;
    final next2 = hasNext2 ? word[i + 2] : '';

    final currIsVowel = isVowel(char);
    final nextIsVowel = isVowel(next);
    final next2IsVowel = hasNext2 && isVowel(next2);

    if (currIsVowel && !nextIsVowel && next2IsVowel) {
      output.add(buffer.toString());
      buffer = StringBuffer();
      continue;
    }

    if (!currIsVowel && nextIsVowel && buffer.length >= 3) {
      final text = buffer.toString();
      output.add(text.substring(0, text.length - 1));
      buffer = StringBuffer(text.substring(text.length - 1));
      continue;
    }

    if (currIsVowel && nextIsVowel) {
      continue;
    }
  }

  final tail = buffer.toString();
  if (tail.isNotEmpty) {
    output.add(tail);
  }

  return output.where((value) => value.isNotEmpty).toList();
}

String buildSyllableHint(String word, {required bool revealAll}) {
  final syllables = splitIntoSpanishSyllables(word);
  if (syllables.isEmpty) {
    return '';
  }
  if (revealAll || syllables.length == 1) {
    return syllables.join(' - ');
  }
  final hidden = List<String>.filled(syllables.length - 1, '__');
  return '${syllables.first} - ${hidden.join(' - ')}';
}

List<String> buildReducedKeyboardLetters(String word) {
  final base = normalizeWordForLetters(word).replaceAll(RegExp(r'[^A-ZÑ]'), '');
  final letters = <String>{...base.split('')};
  const support = ['A', 'E', 'I', 'O', 'U', 'L', 'M', 'N', 'P', 'R', 'S', 'T'];
  for (final candidate in support) {
    if (letters.length >= 12) {
      break;
    }
    letters.add(candidate);
  }
  final sorted = letters.toList()..sort();
  return sorted;
}

bool containsLetter(String word, String letter) {
  final normalizedWord = normalizeWordForLetters(word);
  final normalizedLetter = normalizeWordForLetters(letter);
  if (normalizedWord.isEmpty || normalizedLetter.isEmpty) {
    return false;
  }
  return normalizedWord.contains(normalizedLetter);
}

int estimateSpanishSyllables(String rawWord) {
  final word = normalizeWordForLetters(
    rawWord,
  ).replaceAll(RegExp(r'[^A-ZÑ]'), '');
  if (word.isEmpty) {
    return 0;
  }

  const vowels = 'AEIOU';
  var syllables = 0;
  var previousWasVowel = false;

  for (var i = 0; i < word.length; i++) {
    final char = word[i];
    final isVowel = vowels.contains(char);
    if (isVowel && !previousWasVowel) {
      syllables++;
    }
    previousWasVowel = isVowel;
  }

  return syllables == 0 ? 1 : syllables;
}
