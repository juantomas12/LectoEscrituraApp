import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/providers/app_providers.dart';
import '../../data/services/openai_session_copilot_service.dart';
import '../../domain/models/ai_resource.dart';
import '../../domain/models/session_block.dart';
import '../../domain/models/session_plan.dart';
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

      await saveSession(result.updatedSession);
      state = state.copyWith(
        copilotMessages: [
          ...state.copilotMessages,
          SessionCopilotMessage(
            role: 'assistant',
            text: result.assistantMessage,
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
