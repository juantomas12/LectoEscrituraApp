import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../../domain/models/session_block.dart';
import '../../domain/models/session_plan.dart';

class CopilotChatMessage {
  const CopilotChatMessage({required this.role, required this.content});

  final String role;
  final String content;
}

class SessionCopilotResult {
  const SessionCopilotResult({
    required this.assistantMessage,
    required this.updatedSession,
  });

  final String assistantMessage;
  final SessionPlan updatedSession;
}

class OpenAiSessionCopilotService {
  OpenAiSessionCopilotService({http.Client? client})
    : _client = client ?? http.Client();

  final http.Client _client;

  static const _defaultModel = 'gpt-4o-mini';
  static const _webProxyPath = '/lectorEscrituraapp/api/openai_proxy.php';

  Future<SessionCopilotResult> continueConversation({
    String? apiKey,
    required String model,
    required SessionPlan session,
    required String userMessage,
    required List<CopilotChatMessage> history,
  }) async {
    final normalizedApiKey = (apiKey ?? '').trim();
    if (!kIsWeb && normalizedApiKey.isEmpty) {
      throw StateError(
        'FALTA API KEY. CONFIGÚRALA EN AJUSTES O EN PANTALLA IA.',
      );
    }

    final normalizedModel = model.trim().isEmpty ? _defaultModel : model.trim();
    final systemPrompt = _buildSystemPrompt();
    final userPrompt = _buildUserPrompt(
      session: session,
      userMessage: userMessage,
      history: history,
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
    final assistantMessage =
        (parsed['assistant_message'] ?? 'He aplicado ajustes en la sesión.')
            .toString();
    final updateRaw = parsed['session_update'];
    if (updateRaw is! Map<String, dynamic>) {
      return SessionCopilotResult(
        assistantMessage: assistantMessage,
        updatedSession: session,
      );
    }

    final updated = _applyUpdate(session, updateRaw);
    return SessionCopilotResult(
      assistantMessage: assistantMessage,
      updatedSession: updated,
    );
  }

  SessionPlan _applyUpdate(SessionPlan base, Map<String, dynamic> update) {
    final parsedBlockUpdates = _parseBlockUpdates(update['blocks']);
    List<SessionBlock>? blocks;
    if (parsedBlockUpdates.isNotEmpty) {
      final replaceAll =
          update['replace_all_blocks'] as bool? ??
          update['replaceAllBlocks'] as bool? ??
          false;
      blocks = replaceAll
          ? parsedBlockUpdates
                .map(
                  (patch) => SessionBlock(
                    title: patch.title ?? 'BLOQUE',
                    durationMin: (patch.durationMin ?? 10).clamp(5, 40),
                    lines: (patch.lines == null || patch.lines!.isEmpty)
                        ? const ['AÑADIR INSTRUCCIONES DEL BLOQUE.']
                        : patch.lines!,
                    hasGame: patch.hasGame ?? false,
                  ),
                )
                .toList()
          : _mergeBlocks(base.blocks, parsedBlockUpdates);
    }

    final minutesRaw = update['total_minutes'] ?? update['totalMinutes'];
    final minutes = minutesRaw is int
        ? minutesRaw
        : int.tryParse((minutesRaw ?? '').toString());

    return base.copyWith(
      title: _stringOrNull(update['title']),
      objective: _stringOrNull(update['objective']),
      ageRange:
          _stringOrNull(update['age_range']) ??
          _stringOrNull(update['ageRange']),
      durationLabel:
          _stringOrNull(update['duration_label']) ??
          _stringOrNull(update['durationLabel']),
      modeLabel:
          _stringOrNull(update['mode']) ?? _stringOrNull(update['modeLabel']),
      domain:
          _stringOrNull(update['category']) ?? _stringOrNull(update['domain']),
      totalMinutes: minutes?.clamp(10, 90),
      blocks: blocks,
    );
  }

  List<_BlockPatch> _parseBlockUpdates(dynamic raw) {
    if (raw is! List) {
      return const [];
    }
    final output = <_BlockPatch>[];
    for (final node in raw.whereType<Map>()) {
      final linesRaw = node['lines'];
      final lines = linesRaw is List
          ? linesRaw
                .map((item) => item.toString().trim())
                .where((item) => item.isNotEmpty)
                .toList()
          : null;
      final durationRaw = node['duration_min'] ?? node['durationMin'];
      final durationMin = durationRaw is int
          ? durationRaw
          : int.tryParse((durationRaw ?? '').toString());
      final targetRaw = node['target_title'] ?? node['targetTitle'];
      final indexRaw =
          node['index'] ?? node['block_index'] ?? node['blockIndex'];
      final index = indexRaw is int ? indexRaw : int.tryParse('$indexRaw');
      output.add(
        _BlockPatch(
          targetTitle: _stringOrNull(targetRaw),
          index: index,
          title: _stringOrNull(node['title']),
          durationMin: durationMin,
          lines: lines,
          hasGame: node['has_game'] as bool? ?? node['hasGame'] as bool?,
        ),
      );
    }
    return output;
  }

  List<SessionBlock> _mergeBlocks(
    List<SessionBlock> baseBlocks,
    List<_BlockPatch> patches,
  ) {
    final merged = [...baseBlocks];
    for (final patch in patches) {
      final patchTarget = _normalize(patch.targetTitle ?? patch.title ?? '');
      var index = -1;
      if (patch.index != null &&
          patch.index! >= 0 &&
          patch.index! < merged.length) {
        index = patch.index!;
      } else if (patchTarget.isNotEmpty) {
        for (var i = 0; i < merged.length; i++) {
          final baseTitle = _normalize(merged[i].title);
          if (baseTitle == patchTarget ||
              baseTitle.contains(patchTarget) ||
              patchTarget.contains(baseTitle)) {
            index = i;
            break;
          }
        }
      }

      if (index >= 0) {
        final current = merged[index];
        merged[index] = current.copyWith(
          title: patch.title,
          durationMin: patch.durationMin?.clamp(5, 40),
          lines: patch.lines == null || patch.lines!.isEmpty
              ? null
              : patch.lines,
          hasGame: patch.hasGame,
        );
      } else {
        if ((patch.title ?? '').trim().isEmpty &&
            (patch.lines == null || patch.lines!.isEmpty)) {
          continue;
        }
        merged.add(
          SessionBlock(
            title: patch.title ?? 'BLOQUE',
            durationMin: (patch.durationMin ?? 10).clamp(5, 40),
            lines: (patch.lines == null || patch.lines!.isEmpty)
                ? const ['AÑADIR INSTRUCCIONES DEL BLOQUE.']
                : patch.lines!,
            hasGame: patch.hasGame ?? false,
          ),
        );
      }
    }
    return merged;
  }

  String _normalize(String value) {
    return value.trim().toUpperCase().replaceAll(RegExp(r'\s+'), ' ');
  }

  String? _stringOrNull(dynamic value) {
    final text = (value ?? '').toString().trim();
    return text.isEmpty ? null : text;
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
          'response_format': {'type': 'json_object'},
          'temperature': 0.35,
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
        'response_format': {'type': 'json_object'},
        'temperature': 0.35,
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
          'temperature': 0.35,
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
        'temperature': 0.35,
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
    } catch (_) {}
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

  String _buildSystemPrompt() {
    return '''
Eres copiloto experto en logopedia infantil.
Responde SIEMPRE en JSON válido con esta forma:
{
  "assistant_message": "texto breve para terapeuta",
  "session_update": {
    "title": "opcional",
    "objective": "opcional",
    "age_range": "opcional",
    "duration_label": "opcional",
    "mode": "opcional",
    "category": "opcional",
    "total_minutes": 45,
    "replace_all_blocks": false,
    "blocks": [
      {"target_title":"PROCESAMIENTO GUIADO", "title":"...", "duration_min":12, "has_game":false, "lines":["...","..."]}
    ]
  }
}
Reglas:
- Mantén lenguaje claro, práctico y accionable.
- Si no hay que cambiar algo, omite ese campo en session_update.
- Por defecto, EDICIÓN PARCIAL: si se piden cambios de un bloque, devuelve solo ese bloque en "blocks" usando "target_title", sin borrar los demás.
- Solo usa replace_all_blocks=true si el usuario pide explícitamente rehacer todo el guion.
- Los bloques deben sumar una sesión coherente y adaptada a la edad.
- No devuelvas markdown.
''';
  }

  String _buildUserPrompt({
    required SessionPlan session,
    required String userMessage,
    required List<CopilotChatMessage> history,
  }) {
    final historyLines = history
        .take(8)
        .map((m) => '${m.role.toUpperCase()}: ${m.content}')
        .join('\n');
    final sessionJson = jsonEncode(session.toMap());
    return '''
SESIÓN ACTUAL (JSON):
$sessionJson

HISTORIAL RECIENTE:
$historyLines

PETICIÓN DEL USUARIO:
$userMessage

Ajusta la sesión según la petición y devuelve JSON válido.
Recuerda: edición parcial de bloques por defecto, no borres bloques no mencionados.
''';
  }
}

class _BlockPatch {
  const _BlockPatch({
    required this.targetTitle,
    required this.index,
    required this.title,
    required this.durationMin,
    required this.lines,
    required this.hasGame,
  });

  final String? targetTitle;
  final int? index;
  final String? title;
  final int? durationMin;
  final List<String>? lines;
  final bool? hasGame;
}
