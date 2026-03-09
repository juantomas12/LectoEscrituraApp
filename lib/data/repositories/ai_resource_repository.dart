import 'package:hive/hive.dart';

import '../../core/utils/text_utils.dart';
import '../../domain/models/ai_resource.dart';

class AiResourceRepository {
  static const _boxName = 'ai_resources_box';
  static const Set<String> _ignoredTokens = {
    'EL',
    'LA',
    'LOS',
    'LAS',
    'DE',
    'DEL',
    'UN',
    'UNA',
    'UNOS',
    'UNAS',
    'PARA',
    'CON',
    'POR',
    'EN',
    'Y',
    'O',
    'AL',
    'QUE',
    'QUIERO',
    'NECESITO',
    'CREAR',
    'CREA',
    'GENERAR',
    'GENERA',
    'JUEGO',
    'MINIJUEGO',
    'MINI',
  };

  Future<void> init() async {
    await Hive.openBox<Map>(_boxName);
  }

  Box<Map> get _box => Hive.box<Map>(_boxName);

  Future<void> save(AiResource resource) async {
    await _box.put(resource.id, resource.toMap());
  }

  List<AiResource> getAll() {
    final output = _box.values.map(AiResource.fromMap).toList();
    output.sort((a, b) {
      if (a.isFavorite != b.isFavorite) {
        return a.isFavorite ? -1 : 1;
      }
      return b.createdAt.compareTo(a.createdAt);
    });
    return output;
  }

  AiResource? findBestMatch(String query, {int minimumScore = 10}) {
    final normalizedQuery = _normalizeSearchText(query);
    if (normalizedQuery.isEmpty) {
      return null;
    }
    final queryTokens = _tokenize(normalizedQuery);
    AiResource? best;
    var bestScore = 0;

    for (final resource in getAll()) {
      final score = _scoreResource(resource, normalizedQuery, queryTokens);
      if (score > bestScore) {
        bestScore = score;
        best = resource;
      }
    }

    if (bestScore < minimumScore) {
      return null;
    }
    return best;
  }

  int _scoreResource(
    AiResource resource,
    String normalizedQuery,
    Set<String> queryTokens,
  ) {
    final title = _normalizeSearchText(resource.title);
    final objective = _normalizeSearchText(resource.objective);
    final instruction = _normalizeSearchText(resource.instruction);
    final miniGames = _normalizeSearchText(resource.miniGames.join(' '));
    final haystack = '$title $miniGames $objective $instruction'.trim();
    final titleTokens = _tokenize(title);

    var score = 0;

    if (title == normalizedQuery) {
      score += 30;
    } else if (title.contains(normalizedQuery) ||
        normalizedQuery.contains(title)) {
      score += 16;
    }

    if (haystack.contains(normalizedQuery) ||
        normalizedQuery.contains(haystack)) {
      score += 10;
    }

    for (final token in queryTokens) {
      if (titleTokens.contains(token)) {
        score += 5;
      }
      if (miniGames.contains(token)) {
        score += 4;
      } else if (haystack.contains(token)) {
        score += 2;
      }
    }

    if (queryTokens.isNotEmpty) {
      final overlap = queryTokens.where((token) => haystack.contains(token));
      score += overlap.length;
    }

    return score;
  }

  String _normalizeSearchText(String value) {
    return normalizeForComparison(value, ignoreAccents: true)
        .replaceAll(RegExp(r'[^A-Z0-9Ñ ]'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  Set<String> _tokenize(String value) {
    return _normalizeSearchText(value)
        .split(' ')
        .map((token) => token.trim())
        .where(
          (token) =>
              token.length >= 3 &&
              !_ignoredTokens.contains(token) &&
              RegExp(r'[A-ZÑ0-9]').hasMatch(token),
        )
        .toSet();
  }

  Future<void> delete(String id) async {
    await _box.delete(id);
  }
}
