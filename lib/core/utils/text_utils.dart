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
