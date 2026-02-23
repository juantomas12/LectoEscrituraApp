import 'dart:convert';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../../core/utils/text_utils.dart';
import '../../domain/models/ai_resource.dart';
import '../../domain/models/ai_quiz_question.dart';

class OpenAiResourceGeneratorService {
  OpenAiResourceGeneratorService({http.Client? client})
    : _client = client ?? http.Client();

  final http.Client _client;
  final Random _random = Random();

  static const _defaultModel = 'gpt-4o-mini';
  static const _webProxyPath = '/lectorEscrituraapp/api/openai_proxy.php';

  Future<AiResource> generateResource({
    required String instruction,
    required String ageRange,
    required String duration,
    required String mode,
    required String categoryLabel,
    required String difficultyLabel,
    String? apiKey,
    required List<String> allowedWords,
    String? model,
  }) async {
    final normalizedApiKey = (apiKey ?? '').trim();
    if (!kIsWeb && normalizedApiKey.isEmpty) {
      throw StateError('FALTA API KEY. INTRODÚCELA EN LA PANTALLA DE IA.');
    }

    final normalizedModel = (model ?? _defaultModel).trim();
    final now = DateTime.now();
    final id = 'AI-${now.millisecondsSinceEpoch}-${_random.nextInt(9999)}';

    final systemPrompt = _buildSystemPrompt();
    final userPrompt = _buildUserPrompt(
      instruction: instruction,
      ageRange: ageRange,
      duration: duration,
      mode: mode,
      categoryLabel: categoryLabel,
      difficultyLabel: difficultyLabel,
      allowedWords: allowedWords,
    );

    String modelJson;
    try {
      final map = await _callResponsesApi(
        apiKey: normalizedApiKey,
        model: normalizedModel,
        systemPrompt: systemPrompt,
        userPrompt: userPrompt,
      );
      modelJson = _extractTextFromResponses(map);
    } catch (_) {
      final map = await _callChatCompletionsApi(
        apiKey: normalizedApiKey,
        model: normalizedModel,
        systemPrompt: systemPrompt,
        userPrompt: userPrompt,
      );
      modelJson = _extractTextFromChatCompletions(map);
    }

    final parsed = _extractJsonObject(modelJson);
    final title = (parsed['title'] ?? 'RECURSO IA').toString();
    final objective = (parsed['objective'] ?? '').toString();
    final targetLetter = _extractTargetLetter([
      instruction,
      title,
      objective,
      ..._stringListFrom(parsed['questions']),
    ]);
    final playable = _quizListFrom(parsed['playable_questions']);
    final fallbackQuestions = _fallbackQuestionsFrom(
      parsed['questions'],
      allowedWords: allowedWords,
      targetLetter: targetLetter,
    );
    final effectivePlayable = _sanitizePlayableQuestions(
      playable.isNotEmpty ? playable : fallbackQuestions,
      allowedWords: allowedWords,
      fallbackPrompts: _stringListFrom(parsed['questions']),
      targetLetter: targetLetter,
    );

    return AiResource(
      id: id,
      title: title,
      objective: objective,
      instruction: instruction,
      ageRange: ageRange,
      duration: duration,
      mode: mode,
      categoryLabel: categoryLabel,
      difficultyLabel: difficultyLabel,
      activitySteps: _stringListFrom(parsed['activity_steps']),
      questions: _stringListFrom(parsed['questions']),
      miniGames: _stringListFrom(parsed['mini_games']),
      materials: _stringListFrom(parsed['materials']),
      adaptations: _stringListFrom(parsed['adaptations']),
      investigationTitle:
          (parsed['investigation_title'] ?? 'FICHA DE INVESTIGACIÓN')
              .toString(),
      investigationText: (parsed['investigation_text'] ?? '').toString(),
      playableQuestions: effectivePlayable,
      createdAt: now,
      rawJson: jsonEncode(parsed),
    );
  }

  Future<Map<String, dynamic>> _callResponsesApi({
    required String apiKey,
    required String model,
    required String systemPrompt,
    required String userPrompt,
  }) async {
    if (kIsWeb) {
      return _postToWebProxy(
        endpoint: 'responses',
        body: {
          'model': model,
          'input': [
            {'role': 'system', 'content': systemPrompt},
            {'role': 'user', 'content': userPrompt},
          ],
          'text': {
            'format': {
              'type': 'json_schema',
              'name': 'learning_resource',
              'schema': _resourceSchema,
            },
          },
          'temperature': 0.4,
        },
      );
    }

    final response = await _client.post(
      Uri.parse('https://api.openai.com/v1/responses'),
      headers: {
        'Authorization': 'Bearer $apiKey',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'model': model,
        'input': [
          {'role': 'system', 'content': systemPrompt},
          {'role': 'user', 'content': userPrompt},
        ],
        'text': {
          'format': {
            'type': 'json_schema',
            'name': 'learning_resource',
            'schema': _resourceSchema,
          },
        },
        'temperature': 0.4,
      }),
    );

    if (response.statusCode >= 400) {
      throw StateError(
        'RESPONSES API ${response.statusCode}: ${response.body}',
      );
    }
    final decoded = jsonDecode(response.body);
    if (decoded is! Map<String, dynamic>) {
      throw const FormatException('RESPUESTA RESPONSES API INVÁLIDA.');
    }
    return decoded;
  }

  Future<Map<String, dynamic>> _callChatCompletionsApi({
    required String apiKey,
    required String model,
    required String systemPrompt,
    required String userPrompt,
  }) async {
    if (kIsWeb) {
      return _postToWebProxy(
        endpoint: 'chat_completions',
        body: {
          'model': model,
          'messages': [
            {'role': 'system', 'content': systemPrompt},
            {'role': 'user', 'content': userPrompt},
          ],
          'response_format': {'type': 'json_object'},
          'temperature': 0.4,
        },
      );
    }

    final response = await _client.post(
      Uri.parse('https://api.openai.com/v1/chat/completions'),
      headers: {
        'Authorization': 'Bearer $apiKey',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'model': model,
        'messages': [
          {'role': 'system', 'content': systemPrompt},
          {'role': 'user', 'content': userPrompt},
        ],
        'response_format': {'type': 'json_object'},
        'temperature': 0.4,
      }),
    );

    if (response.statusCode >= 400) {
      throw StateError(
        'CHAT COMPLETIONS API ${response.statusCode}: ${response.body}',
      );
    }
    final decoded = jsonDecode(response.body);
    if (decoded is! Map<String, dynamic>) {
      throw const FormatException('RESPUESTA CHAT COMPLETIONS INVÁLIDA.');
    }
    return decoded;
  }

  Future<Map<String, dynamic>> _postToWebProxy({
    required String endpoint,
    required Map<String, dynamic> body,
  }) async {
    final response = await _client.post(
      Uri.parse(_webProxyPath),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'endpoint': endpoint, 'body': body}),
    );
    if (response.statusCode >= 400) {
      throw StateError('PROXY API ${response.statusCode}: ${response.body}');
    }
    final decoded = jsonDecode(response.body);
    if (decoded is! Map<String, dynamic>) {
      throw const FormatException('RESPUESTA PROXY INVÁLIDA.');
    }
    return decoded;
  }

  String _extractTextFromResponses(Map<String, dynamic> map) {
    final direct = map['output_text'];
    if (direct is String && direct.trim().isNotEmpty) {
      return direct;
    }

    final output = map['output'];
    if (output is List) {
      for (final node in output) {
        if (node is! Map) {
          continue;
        }
        final content = node['content'];
        if (content is! List) {
          continue;
        }
        for (final item in content) {
          if (item is! Map) {
            continue;
          }
          final text = item['text'] ?? item['output_text'];
          if (text is String && text.trim().isNotEmpty) {
            return text;
          }
        }
      }
    }

    throw const FormatException('NO SE PUDO EXTRAER TEXTO DE RESPONSES API.');
  }

  String _extractTextFromChatCompletions(Map<String, dynamic> map) {
    final choices = map['choices'];
    if (choices is! List || choices.isEmpty) {
      throw const FormatException('CHAT COMPLETIONS SIN CHOICES.');
    }

    final first = choices.first;
    if (first is! Map) {
      throw const FormatException('CHOICE INVÁLIDO.');
    }

    final message = first['message'];
    if (message is! Map) {
      throw const FormatException('MESSAGE INVÁLIDO.');
    }

    final content = message['content'];
    if (content is String && content.trim().isNotEmpty) {
      return content;
    }
    throw const FormatException('CHAT COMPLETIONS SIN CONTENIDO.');
  }

  Map<String, dynamic> _extractJsonObject(String raw) {
    try {
      final decoded = jsonDecode(raw);
      if (decoded is Map<String, dynamic>) {
        return decoded;
      }
    } catch (_) {
      // FALLBACK: TRY TO CAPTURE THE FIRST JSON OBJECT FROM THE MODEL TEXT.
    }

    final match = RegExp(r'\{[\s\S]*\}').firstMatch(raw);
    if (match == null) {
      throw const FormatException('NO SE ENCONTRÓ JSON EN LA RESPUESTA.');
    }
    final candidate = match.group(0)!;
    final decoded = jsonDecode(candidate);
    if (decoded is! Map<String, dynamic>) {
      throw const FormatException('EL JSON RECIBIDO NO ES UN OBJETO.');
    }
    return decoded;
  }

  List<String> _stringListFrom(dynamic value) {
    if (value is List) {
      return value
          .map((item) => item.toString().trim())
          .where((item) => item.isNotEmpty)
          .toList();
    }
    if (value is String && value.trim().isNotEmpty) {
      return value
          .split(RegExp(r'[\n\r]+'))
          .map((item) => item.trim())
          .where((item) => item.isNotEmpty)
          .toList();
    }
    return const [];
  }

  List<AiQuizQuestion> _quizListFrom(dynamic value) {
    if (value is! List) {
      return const [];
    }
    final output = <AiQuizQuestion>[];
    for (final raw in value) {
      if (raw is! Map) {
        continue;
      }
      final question = AiQuizQuestion.fromMap(raw);
      if (question.prompt.trim().isEmpty || question.options.length < 2) {
        continue;
      }
      output.add(question);
    }
    return output;
  }

  List<AiQuizQuestion> _sanitizePlayableQuestions(
    List<AiQuizQuestion> input, {
    required List<String> allowedWords,
    required List<String> fallbackPrompts,
    required String? targetLetter,
  }) {
    final allowed = allowedWords
        .map((item) => item.trim().toUpperCase())
        .where((item) => item.isNotEmpty)
        .toSet();

    final sanitized = <AiQuizQuestion>[];
    for (final q in input) {
      final options = q.options
          .map((item) => item.trim().toUpperCase())
          .where((item) => item.isNotEmpty)
          .toList();
      if (options.length < 3) {
        continue;
      }
      final unique = options.toSet().toList();
      if (unique.length < 3) {
        continue;
      }
      final valid =
          allowed.isEmpty || unique.every((item) => allowed.contains(item));
      if (!valid) {
        continue;
      }

      final mutable = [...unique.take(3)];
      if (targetLetter != null &&
          !mutable.any((option) => containsLetter(option, targetLetter))) {
        final candidatePool = allowed
            .where((word) => containsLetter(word, targetLetter))
            .where((word) => !mutable.contains(word))
            .toList();
        if (candidatePool.isNotEmpty) {
          candidatePool.shuffle(_random);
          mutable[2] = candidatePool.first;
        }
      }
      if (targetLetter != null &&
          !mutable.any((option) => containsLetter(option, targetLetter))) {
        continue;
      }

      final correct = q.correctIndex.clamp(0, unique.length - 1);
      final prompt = q.prompt.trim().isEmpty
          ? (fallbackPrompts.isEmpty
                ? '¿Cuál opción corresponde mejor a la consigna?'
                : fallbackPrompts.first)
          : q.prompt.trim();
      var effectiveCorrect = correct > 2 ? 0 : correct;
      if (targetLetter != null) {
        for (var i = 0; i < mutable.length; i++) {
          if (containsLetter(mutable[i], targetLetter)) {
            effectiveCorrect = i;
            break;
          }
        }
      }
      sanitized.add(
        AiQuizQuestion(
          prompt: prompt,
          options: mutable,
          correctIndex: effectiveCorrect,
          feedback: q.feedback.trim().isEmpty
              ? 'Muy bien. Explica por qué has elegido esa opción.'
              : q.feedback.trim(),
        ),
      );
      if (sanitized.length >= 6) {
        break;
      }
    }

    if (sanitized.length >= 4) {
      return sanitized;
    }

    return _fallbackQuestionsFrom(
      fallbackPrompts,
      allowedWords: allowedWords,
      targetLetter: targetLetter,
    );
  }

  List<AiQuizQuestion> _fallbackQuestionsFrom(
    dynamic value, {
    required List<String> allowedWords,
    required String? targetLetter,
  }) {
    final base = _stringListFrom(value);
    final usableWords = allowedWords
        .where((word) => word.trim().isNotEmpty)
        .map((word) => word.trim().toUpperCase())
        .toSet()
        .toList();
    usableWords.shuffle(_random);
    final withTarget = targetLetter == null
        ? usableWords
        : usableWords
              .where((word) => containsLetter(word, targetLetter))
              .toList();
    final withoutTarget = targetLetter == null
        ? usableWords
        : usableWords
              .where((word) => !containsLetter(word, targetLetter))
              .toList();

    final output = <AiQuizQuestion>[];
    var index = 0;
    for (final question in base.take(6)) {
      final correctWord = withTarget.isNotEmpty
          ? withTarget[index % withTarget.length]
          : null;
      final distractors = <String>[];
      final distractorSource = withoutTarget.isNotEmpty
          ? withoutTarget
          : usableWords.where((word) => word != correctWord).toList();
      for (final candidate in distractorSource) {
        if (distractors.length >= 2) {
          break;
        }
        if (candidate != correctWord && !distractors.contains(candidate)) {
          distractors.add(candidate);
        }
      }
      if (correctWord == null || distractors.length < 2) {
        break;
      }
      index++;
      final selected = [correctWord, ...distractors]..shuffle(_random);
      final correctIndex = selected.indexOf(correctWord);
      final promptText = targetLetter == null
          ? question
          : "¿Qué palabra contiene la letra '$targetLetter'?";
      output.add(
        AiQuizQuestion(
          prompt: promptText,
          options: selected,
          correctIndex: correctIndex < 0 ? 0 : correctIndex,
          feedback: 'OBSERVA BIEN LAS IMÁGENES Y EXPLICA TU ELECCIÓN.',
        ),
      );
    }
    return output;
  }

  String? _extractTargetLetter(List<String> texts) {
    final merged = texts
        .map((item) => item.trim().toUpperCase())
        .where((item) => item.isNotEmpty)
        .join(' ');
    if (merged.isEmpty) {
      return null;
    }
    final vocalMatch = RegExp(
      r'(?:VOCAL|VOCALES)\s*([AEIOU])',
    ).firstMatch(merged);
    if (vocalMatch != null) {
      return vocalMatch.group(1);
    }
    final letraMatch = RegExp(
      r'(?:LETRA|LETRAS)\s*([A-ZÑ])',
    ).firstMatch(merged);
    if (letraMatch != null) {
      return letraMatch.group(1);
    }
    return null;
  }

  String _buildSystemPrompt() {
    return '''
ERES UN ASISTENTE EXPERTO EN LOGOPEDIA, LECTOESCRITURA Y DISEÑO DE ACTIVIDADES PARA TABLET.
DEVUELVE SOLO JSON VÁLIDO CON ESTE ESQUEMA:
- title: string
- objective: string
- investigation_title: string
- investigation_text: string
- activity_steps: string[]
- questions: string[]
- mini_games: string[]
- materials: string[]
- adaptations: string[]
- playable_questions: Array<{prompt:string, options:string[], correct_index:number, feedback:string}>

REGLAS:
- ESPAÑOL DE ESPAÑA.
- CONTENIDO CLARO, ACCIONABLE Y APTO PARA NIÑOS.
- SIEMPRE INCLUYE PREGUNTAS Y UNA PROPUESTA DE MINI-JUEGO.
- INCLUYE AL MENOS 3 MINI-JUEGOS DISTINTOS EN mini_games.
- GENERA ENTRE 4 Y 6 PREGUNTAS TIPO TEST EN playable_questions.
- CADA PREGUNTA DEBE TENER 3 OPCIONES.
- correct_index DEBE SER 0, 1 O 2.
- TODAS LAS OPCIONES DE playable_questions DEBEN SER PALABRAS CONCRETAS Y VISUALES (OBJETOS, ANIMALES, LUGARES O PROFESIONES).
- LA PREGUNTA Y LA RESPUESTA CORRECTA DEBEN ESTAR ALINEADAS SEMÁNTICAMENTE (SIN CONTRADICCIONES).
- NO AÑADAS TEXTO FUERA DEL JSON.
''';
  }

  String _buildUserPrompt({
    required String instruction,
    required String ageRange,
    required String duration,
    required String mode,
    required String categoryLabel,
    required String difficultyLabel,
    required List<String> allowedWords,
  }) {
    final normalizedWords =
        allowedWords
            .map((word) => word.trim().toUpperCase())
            .where((word) => word.isNotEmpty)
            .toSet()
            .toList()
          ..sort();

    final wordsBlock = normalizedWords.isEmpty
        ? ''
        : '\nPALABRAS DISPONIBLES PARA OPCIONES VISUALES:\n${normalizedWords.join(', ')}\n';

    return '''
OBJETIVO DEL PROFESIONAL:
$instruction

PARÁMETROS:
- EDAD/NIVEL: $ageRange
- DURACIÓN: $duration
- MODO: $mode
- CATEGORÍA: $categoryLabel
- DIFICULTAD: $difficultyLabel
$wordsBlock

QUEREMOS UNA ACTIVIDAD QUE SE PUEDA MOSTRAR EN UNA SOLA PANTALLA DE TABLET.
ADEMÁS, INCLUYE UNA FICHA DE LECTURA CORTA (investigation_text) PARA CONTESTAR LAS PREGUNTAS.
EN playable_questions, LAS OPCIONES DE RESPUESTA DEBEN SER PALABRAS CONCRETAS (OBJETOS) PARA PODER MOSTRAR IMAGEN.
SI EXISTE LA LISTA DE PALABRAS DISPONIBLES, USA SOLO ESAS PALABRAS EN options.
''';
  }

  static const Map<String, dynamic> _resourceSchema = {
    'type': 'object',
    'required': [
      'title',
      'objective',
      'investigation_title',
      'investigation_text',
      'activity_steps',
      'questions',
      'mini_games',
      'materials',
      'adaptations',
      'playable_questions',
    ],
    'properties': {
      'title': {'type': 'string'},
      'objective': {'type': 'string'},
      'investigation_title': {'type': 'string'},
      'investigation_text': {'type': 'string'},
      'activity_steps': {
        'type': 'array',
        'items': {'type': 'string'},
      },
      'questions': {
        'type': 'array',
        'items': {'type': 'string'},
      },
      'mini_games': {
        'type': 'array',
        'items': {'type': 'string'},
      },
      'materials': {
        'type': 'array',
        'items': {'type': 'string'},
      },
      'adaptations': {
        'type': 'array',
        'items': {'type': 'string'},
      },
      'playable_questions': {
        'type': 'array',
        'items': {
          'type': 'object',
          'required': ['prompt', 'options', 'correct_index', 'feedback'],
          'properties': {
            'prompt': {'type': 'string'},
            'options': {
              'type': 'array',
              'minItems': 3,
              'maxItems': 3,
              'items': {'type': 'string'},
            },
            'correct_index': {'type': 'integer'},
            'feedback': {'type': 'string'},
          },
          'additionalProperties': false,
        },
      },
    },
    'additionalProperties': false,
  };
}
