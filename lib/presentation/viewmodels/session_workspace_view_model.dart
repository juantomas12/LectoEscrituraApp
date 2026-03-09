import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/providers/app_providers.dart';
import '../../core/utils/text_utils.dart';
import '../../data/services/openai_session_copilot_service.dart';
import '../../domain/models/ai_resource.dart';
import '../../domain/models/activity_type.dart';
import '../../domain/models/category.dart';
import '../../domain/models/session_block.dart';
import '../../domain/models/session_plan.dart';
import 'ai_resource_studio_view_model.dart';
import 'settings_view_model.dart';

class SessionCopilotMessage {
  const SessionCopilotMessage({
    required this.role,
    required this.text,
    required this.createdAt,
  });

  final String role;
  final String text;
  final DateTime createdAt;
}

class SessionWorkspaceState {
  const SessionWorkspaceState({
    required this.sessions,
    required this.activeSessionId,
    required this.copilotMessages,
    required this.isCopilotLoading,
    this.errorMessage,
  });

  final List<SessionPlan> sessions;
  final String? activeSessionId;
  final List<SessionCopilotMessage> copilotMessages;
  final bool isCopilotLoading;
  final String? errorMessage;

  SessionPlan? get activeSession {
    if (activeSessionId == null) {
      return null;
    }
    for (final session in sessions) {
      if (session.id == activeSessionId) {
        return session;
      }
    }
    return null;
  }

  SessionWorkspaceState copyWith({
    List<SessionPlan>? sessions,
    String? activeSessionId,
    List<SessionCopilotMessage>? copilotMessages,
    bool? isCopilotLoading,
    String? errorMessage,
  }) {
    return SessionWorkspaceState(
      sessions: sessions ?? this.sessions,
      activeSessionId: activeSessionId ?? this.activeSessionId,
      copilotMessages: copilotMessages ?? this.copilotMessages,
      isCopilotLoading: isCopilotLoading ?? this.isCopilotLoading,
      errorMessage: errorMessage,
    );
  }
}

class SessionWorkspaceViewModel extends Notifier<SessionWorkspaceState> {
  static const Set<String> _gameActionKeywords = {
    'CREA',
    'CREAR',
    'GENERA',
    'GENERAR',
    'HAZ',
    'HACER',
    'QUIERO',
    'NECESITO',
    'PON',
    'PONER',
    'CAMBIA',
    'CAMBIAR',
    'USA',
    'USAR',
    'INCLUYE',
    'AÑADE',
    'ANADE',
    'METE',
    'METER',
  };

  @override
  SessionWorkspaceState build() {
    final all = ref.read(sessionPlanRepositoryProvider).getAll();
    return SessionWorkspaceState(
      sessions: all,
      activeSessionId: all.isEmpty ? null : all.first.id,
      copilotMessages: [
        SessionCopilotMessage(
          role: 'assistant',
          text:
              'Soy tu copiloto de sesión. Pídeme cambios de duración, edad, bloques o tipo de juego.',
          createdAt: DateTime.fromMillisecondsSinceEpoch(0),
        ),
      ],
      isCopilotLoading: false,
    );
  }

  void refresh() {
    final all = ref.read(sessionPlanRepositoryProvider).getAll();
    final activeId = state.activeSessionId;
    final hasActive =
        activeId != null && all.any((item) => item.id == activeId);
    state = state.copyWith(
      sessions: all,
      activeSessionId: hasActive
          ? activeId
          : (all.isEmpty ? null : all.first.id),
      errorMessage: null,
    );
  }

  void selectSession(String id) {
    state = state.copyWith(activeSessionId: id, errorMessage: null);
  }

  Future<void> deleteSession(String id) async {
    await ref.read(sessionPlanRepositoryProvider).delete(id);
    refresh();
  }

  Future<void> saveSession(SessionPlan updated) async {
    await ref.read(sessionPlanRepositoryProvider).save(updated);
    refresh();
    selectSession(updated.id);
  }

  Future<void> updateSessionFields({
    required String sessionId,
    String? title,
    String? objective,
    String? ageRange,
    String? durationLabel,
    String? modeLabel,
    String? domain,
    int? totalMinutes,
  }) async {
    SessionPlan? target;
    for (final item in state.sessions) {
      if (item.id == sessionId) {
        target = item;
        break;
      }
    }
    if (target == null) {
      return;
    }
    await saveSession(
      target.copyWith(
        title: title,
        objective: objective,
        ageRange: ageRange,
        durationLabel: durationLabel,
        modeLabel: modeLabel,
        domain: domain,
        totalMinutes: totalMinutes,
      ),
    );
  }

  Future<void> updateBlock({
    required String sessionId,
    required int blockIndex,
    String? title,
    int? durationMin,
    List<String>? lines,
    bool? hasGame,
  }) async {
    SessionPlan? target;
    for (final item in state.sessions) {
      if (item.id == sessionId) {
        target = item;
        break;
      }
    }
    if (target == null ||
        blockIndex < 0 ||
        blockIndex >= target.blocks.length) {
      return;
    }

    final nextBlocks = [...target.blocks];
    nextBlocks[blockIndex] = nextBlocks[blockIndex].copyWith(
      title: title,
      durationMin: durationMin,
      lines: lines,
      hasGame: hasGame,
    );
    await saveSession(target.copyWith(blocks: nextBlocks));
  }

  int _durationToMinutes(String raw) {
    final value = raw.toUpperCase();
    if (value.contains('15-20')) return 60;
    if (value.contains('10-15')) return 45;
    if (value.contains('5-10')) return 30;
    if (value.contains('1-3')) return 15;
    return 40;
  }

  List<SessionBlock> _buildBlocks(
    AiResource resource,
    int totalMinutes, {
    required int maxActivitySteps,
    required bool includeGameBlock,
  }) {
    final act = resource.activitySteps.isEmpty
        ? ['INICIAR CON UNA ACTIVIDAD BREVE Y CONCRETA.']
        : resource.activitySteps;
    final ask = resource.questions.isEmpty
        ? ['REALIZAR 3 PREGUNTAS DE COMPRENSIÓN ADAPTADAS A LA EDAD.']
        : resource.questions;
    final games = resource.miniGames.isEmpty
        ? ['EJECUTAR UN MINI-JUEGO DE REFUERZO CON IMÁGENES.']
        : resource.miniGames;

    if (includeGameBlock) {
      final d1 = (totalMinutes * 0.22).round().clamp(8, 18);
      final d2 = (totalMinutes * 0.33).round().clamp(10, 24);
      final d3 = (totalMinutes * 0.30).round().clamp(10, 24);
      final d4 = (totalMinutes - d1 - d2 - d3).clamp(8, 18);
      return [
        SessionBlock(
          title: 'ACTIVACIÓN Y MODELADO',
          durationMin: d1,
          lines: act.take(maxActivitySteps).toList(),
        ),
        SessionBlock(
          title: 'PROCESAMIENTO GUIADO',
          durationMin: d2,
          lines: ask.take(maxActivitySteps).toList(),
        ),
        SessionBlock(
          title: 'JUEGO GENERADO',
          durationMin: d3,
          hasGame: true,
          lines: [
            ...games.take(2),
            'ABRIR EL JUEGO INTERACTIVO DESDE EL BOTÓN DEL BLOQUE.',
          ],
        ),
        SessionBlock(
          title: 'CIERRE Y REPASO',
          durationMin: d4,
          lines: [
            'RECUPERAR LO APRENDIDO CON PREGUNTAS GUIADAS.',
            'REFORZAR EL OBJETIVO GENERAL DE LA SESIÓN.',
            'REGISTRAR RESPUESTA ESPERADA Y OBSERVACIONES.',
          ],
        ),
      ];
    }

    final d1 = (totalMinutes * 0.25).round().clamp(8, 20);
    final d2 = (totalMinutes * 0.5).round().clamp(12, 30);
    final d3 = (totalMinutes - d1 - d2).clamp(8, 20);
    return [
      SessionBlock(
        title: 'ACTIVACIÓN Y LECTURA MODELADA',
        durationMin: d1,
        lines: act.take(maxActivitySteps).toList(),
      ),
      SessionBlock(
        title: 'PROCESAMIENTO LITERAL E INFERENCIAL',
        durationMin: d2,
        lines: ask.take(maxActivitySteps).toList(),
      ),
      SessionBlock(
        title: 'RENARRACIÓN Y CIERRE',
        durationMin: d3,
        lines: [
          'RECUPERAR LO APRENDIDO CON PREGUNTAS GUIADAS.',
          'REFORZAR EL OBJETIVO GENERAL DE LA SESIÓN.',
          'REGISTRAR RESPUESTA ESPERADA Y OBSERVACIONES.',
        ],
      ),
    ];
  }

  Future<_GameResolution?> _resolveGameResourceIfRequested({
    required String prompt,
    required SessionPlan session,
    required String apiKey,
    required String model,
  }) async {
    final request = _extractGameRequest(prompt);
    if (request == null) {
      return null;
    }

    final repository = ref.read(aiResourceRepositoryProvider);
    final existing =
        repository.findBestMatch(request.query) ??
        repository.findBestMatch(prompt);
    if (existing != null) {
      return _GameResolution(
        session: _linkSessionToResource(session, existing),
        note: 'Juego encontrado en la base y vinculado: ${existing.title}.',
      );
    }

    final generated = await ref
        .read(openAiResourceGeneratorServiceProvider)
        .generateResource(
          instruction: _buildAutoGameInstruction(
            prompt: prompt,
            session: session,
            gameName: request.displayName,
          ),
          ageRange: session.ageRange,
          duration: session.durationLabel,
          mode: session.modeLabel,
          categoryLabel: session.domain,
          difficultyLabel: 'AUTO POR EDAD',
          apiKey: apiKey,
          allowedWords: _availableWordsForSession(session.domain),
          model: model,
        );

    await repository.save(generated);
    ref.read(aiResourceStudioViewModelProvider.notifier).refresh();
    return _GameResolution(
      session: _linkSessionToResource(session, generated),
      note:
          'El juego no estaba en la base. Lo creé y guardé automáticamente: ${generated.title}.',
    );
  }

  _GameRequest? _extractGameRequest(String prompt) {
    final normalized = normalizeForComparison(prompt, ignoreAccents: true);
    final hasAction = _containsAnyKeyword(normalized, _gameActionKeywords);
    final extracted = _extractGameNameFromPrompt(prompt);
    if (!hasAction || extracted.trim().isEmpty) {
      return null;
    }
    final query = extracted.trim().isEmpty ? prompt.trim() : extracted.trim();
    final boundedQuery = query.length > 120 ? query.substring(0, 120) : query;
    final displayName = extracted.trim().isEmpty
        ? 'JUEGO SOLICITADO'
        : extracted.trim().toUpperCase();
    return _GameRequest(query: boundedQuery.trim(), displayName: displayName);
  }

  String _extractGameNameFromPrompt(String prompt) {
    final normalized = normalizeForComparison(prompt, ignoreAccents: true);
    const knownGames = [
      'RULETA DE PALABRAS',
      'RULETA',
      'JUEGO DE MEMORIA',
      'MEMORIA',
      'SOPA DE LETRAS',
      'PALABRAS ENCADENADAS',
      'ADIVINA LA PALABRA',
      'ADIVINA',
      'BINGO',
      'TRIVIA',
    ];
    for (final game in knownGames) {
      if (normalized.contains(game)) {
        return game;
      }
    }

    final match = RegExp(
      r'(?:juego|mini\s*juego|actividad)\s+(?:de|del|tipo)\s+([A-Za-zÁÉÍÓÚÑáéíóúñ0-9 ]{3,80})',
      caseSensitive: false,
    ).firstMatch(prompt);
    if (match == null) {
      return '';
    }

    final candidate = (match.group(1) ?? '').trim();
    if (candidate.isEmpty) {
      return '';
    }
    final cut = candidate.split(RegExp(r'[\n\.,;:]')).first.trim();
    final clean = cut
        .split(
          RegExp(r'\s+(?:para|con|y|que|donde|si)\s+', caseSensitive: false),
        )
        .first
        .trim();
    return clean.replaceFirst(
      RegExp(r'^(el|la|los|las|un|una)\s+', caseSensitive: false),
      '',
    );
  }

  bool _containsAnyKeyword(String source, Set<String> keywords) {
    for (final keyword in keywords) {
      if (source.contains(keyword)) {
        return true;
      }
    }
    return false;
  }

  List<String> _availableWordsForSession(String categoryLabel) {
    final normalizedCategory = normalizeForComparison(
      categoryLabel,
      ignoreAccents: true,
    );
    var category = AppCategory.mixta;
    for (final candidate in AppCategory.values) {
      final normalizedLabel = normalizeForComparison(
        candidate.label,
        ignoreAccents: true,
      );
      final normalizedId = normalizeForComparison(
        candidate.id,
        ignoreAccents: true,
      );
      if (normalizedCategory == normalizedLabel ||
          normalizedCategory == normalizedId) {
        category = candidate;
        break;
      }
    }
    final dataset = ref.read(datasetRepositoryProvider);
    final words =
        dataset
            .getAllItems()
            .where((item) {
              final word = (item.word ?? '').trim();
              if (word.isEmpty ||
                  item.activityType != ActivityType.imagenPalabra) {
                return false;
              }
              return category == AppCategory.mixta || item.category == category;
            })
            .map((item) => item.word!.trim().toUpperCase())
            .toSet()
            .toList()
          ..sort();

    if (words.length <= 180) {
      return words;
    }
    return words.take(180).toList();
  }

  String _buildAutoGameInstruction({
    required String prompt,
    required SessionPlan session,
    required String gameName,
  }) {
    final objective = session.objective.trim().isEmpty
        ? 'Refuerzo lector y de vocabulario adaptado a la edad.'
        : session.objective.trim();
    return '''
CREA UN RECURSO IA PARA ESTA SESIÓN.
JUEGO SOLICITADO: $gameName
PETICIÓN DEL TERAPEUTA: $prompt
OBJETIVO BASE DE LA SESIÓN: $objective

REQUISITOS:
- RESPETAR EL JUEGO PEDIDO (SI PIDE RULETA, DEBE SER RULETA).
- ACTIVIDAD JUGABLE CON APOYO VISUAL.
- OPCIONES DE RESPUESTA PENSADAS PARA MOSTRAR IMÁGENES.
- PROPUESTA CLARA PARA USO EN TABLET.
''';
  }

  SessionPlan _linkSessionToResource(SessionPlan session, AiResource resource) {
    final nextBlocks = [...session.blocks];
    final normalizedTitle = normalizeForComparison(
      resource.title,
      ignoreAccents: true,
    );
    final primaryGameLine = resource.miniGames.isEmpty
        ? 'JUEGO PRINCIPAL: ${resource.title}.'
        : resource.miniGames.first;
    final linkedLine = 'RECURSO VINCULADO: ${resource.title}.';
    var gameIndex = -1;
    for (var i = 0; i < nextBlocks.length; i++) {
      if (nextBlocks[i].hasGame) {
        gameIndex = i;
        break;
      }
    }

    if (gameIndex >= 0) {
      final block = nextBlocks[gameIndex];
      final lines = [...block.lines];
      final alreadyLinked = lines.any(
        (line) => normalizeForComparison(
          line,
          ignoreAccents: true,
        ).contains(normalizedTitle),
      );
      if (!alreadyLinked) {
        lines.insert(0, primaryGameLine);
        lines.insert(1, linkedLine);
      }
      nextBlocks[gameIndex] = block.copyWith(
        hasGame: true,
        lines: lines,
        title: block.title.trim().isEmpty ? 'JUEGO GENERADO' : block.title,
      );
    } else {
      final duration = (session.totalMinutes * 0.28).round().clamp(8, 20);
      nextBlocks.add(
        SessionBlock(
          title: 'JUEGO GENERADO',
          durationMin: duration,
          hasGame: true,
          lines: [
            primaryGameLine,
            linkedLine,
            'ABRIR EL JUEGO INTERACTIVO DESDE EL BOTÓN DEL BLOQUE.',
          ],
        ),
      );
    }

    return session.copyWith(
      sourceResourceId: resource.id,
      sourceResourceTitle: resource.title,
      blocks: nextBlocks,
    );
  }

  String _mergeAssistantMessage(String base, String? note) {
    final trimmedNote = (note ?? '').trim();
    if (trimmedNote.isEmpty) {
      return base;
    }
    final trimmedBase = base.trim();
    if (trimmedBase.isEmpty) {
      return trimmedNote;
    }
    return '$trimmedBase\n$trimmedNote';
  }

  Future<void> generateSessionFromResource(
    AiResource resource, {
    int? totalMinutesOverride,
    int maxActivitySteps = 4,
    bool includeGameBlock = true,
  }) async {
    final totalMinutes =
        totalMinutesOverride ?? _durationToMinutes(resource.duration);
    final now = DateTime.now();
    final id = 'SES-${now.millisecondsSinceEpoch}';
    final plan = SessionPlan(
      id: id,
      title: resource.title,
      domain: resource.categoryLabel,
      ageRange: resource.ageRange,
      durationLabel: resource.duration,
      modeLabel: resource.mode,
      status: 'LISTA',
      totalMinutes: totalMinutes,
      objective: resource.objective,
      sourceResourceId: resource.id,
      sourceResourceTitle: resource.title,
      blocks: _buildBlocks(
        resource,
        totalMinutes,
        maxActivitySteps: maxActivitySteps.clamp(2, 8),
        includeGameBlock: includeGameBlock,
      ),
      createdAt: now,
    );

    await ref.read(sessionPlanRepositoryProvider).save(plan);
    refresh();
    selectSession(id);
  }

  Future<void> sendCopilotMessage(String value) async {
    final prompt = value.trim();
    final active = state.activeSession;
    if (prompt.isEmpty || active == null || state.isCopilotLoading) {
      return;
    }

    final settings = ref.read(settingsViewModelProvider);
    final model = settings.openAiModel.trim().isNotEmpty
        ? settings.openAiModel.trim()
        : 'gpt-4o-mini';
    final now = DateTime.now();
    final newMessages = [
      ...state.copilotMessages,
      SessionCopilotMessage(role: 'user', text: prompt, createdAt: now),
    ];
    state = state.copyWith(
      copilotMessages: newMessages,
      isCopilotLoading: true,
      errorMessage: null,
    );

    try {
      final result = await ref
          .read(openAiSessionCopilotServiceProvider)
          .continueConversation(
            apiKey: settings.openAiApiKey.trim(),
            model: model,
            session: active,
            userMessage: prompt,
            history: newMessages
                .map(
                  (msg) =>
                      CopilotChatMessage(role: msg.role, content: msg.text),
                )
                .toList(),
          );

      var updatedSession = result.updatedSession;
      var assistantMessage = result.assistantMessage;

      try {
        final gameResolution = await _resolveGameResourceIfRequested(
          prompt: prompt,
          session: updatedSession,
          apiKey: settings.openAiApiKey.trim(),
          model: model,
        );
        if (gameResolution != null) {
          updatedSession = gameResolution.session;
          assistantMessage = _mergeAssistantMessage(
            assistantMessage,
            gameResolution.note,
          );
        }
      } catch (_) {
        assistantMessage = _mergeAssistantMessage(
          assistantMessage,
          'No pude crear o vincular automáticamente el juego solicitado. Revisa API key/modelo e inténtalo de nuevo.',
        );
      }

      await saveSession(updatedSession);
      state = state.copyWith(
        copilotMessages: [
          ...state.copilotMessages,
          SessionCopilotMessage(
            role: 'assistant',
            text: assistantMessage,
            createdAt: DateTime.now(),
          ),
        ],
        isCopilotLoading: false,
        errorMessage: null,
      );
    } catch (error) {
      state = state.copyWith(
        isCopilotLoading: false,
        errorMessage: error.toString(),
        copilotMessages: [
          ...state.copilotMessages,
          SessionCopilotMessage(
            role: 'assistant',
            text:
                'No pude aplicar el cambio automáticamente. Revisa API key/modelo en Ajustes y vuelve a intentarlo.',
            createdAt: DateTime.now(),
          ),
        ],
      );
    }
  }
}

final sessionWorkspaceViewModelProvider =
    NotifierProvider<SessionWorkspaceViewModel, SessionWorkspaceState>(
      SessionWorkspaceViewModel.new,
    );

class _GameRequest {
  const _GameRequest({required this.query, required this.displayName});

  final String query;
  final String displayName;
}

class _GameResolution {
  const _GameResolution({required this.session, this.note});

  final SessionPlan session;
  final String? note;
}
