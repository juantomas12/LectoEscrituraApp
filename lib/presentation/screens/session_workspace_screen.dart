import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/models/ai_resource.dart';
import '../../domain/models/session_plan.dart';
import '../viewmodels/ai_resource_studio_view_model.dart';
import '../viewmodels/session_workspace_view_model.dart';
import '../widgets/upper_text.dart';
import 'generated_session_game_screen.dart';

const _ageOptions = [
  'AUTO',
  'INFANTIL (3-6)',
  'INFANTIL (7-12)',
  'ADOLESCENTES',
  'ADULTOS',
  'MAYORES',
];
const _durationOptions = ['1-3 MIN', '5-10 MIN', '10-15 MIN', '15-20 MIN'];
const _modeOptions = [
  'SITUACIÓN DE APRENDIZAJE',
  'ACTIVIDAD DE PREGUNTAS',
  'MINI-JUEGO GUIADO',
];
const _categoryOptions = [
  'MIX DE CATEGORÍAS',
  'COSAS DE CASA',
  'COMIDA',
  'DINERO',
  'BAÑO',
  'PROFESIONES',
  'SALUD',
  'EMOCIONES',
];

class SessionWorkspaceScreen extends ConsumerStatefulWidget {
  const SessionWorkspaceScreen({super.key});

  @override
  ConsumerState<SessionWorkspaceScreen> createState() =>
      _SessionWorkspaceScreenState();
}

class _SessionWorkspaceScreenState
    extends ConsumerState<SessionWorkspaceScreen> {
  final TextEditingController _copilotController = TextEditingController();

  @override
  void dispose() {
    _copilotController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final workspace = ref.watch(sessionWorkspaceViewModelProvider);
    final workspaceVm = ref.read(sessionWorkspaceViewModelProvider.notifier);
    final resources = ref.watch(aiResourceStudioViewModelProvider).resources;
    final active = workspace.activeSession;
    final isWide = MediaQuery.sizeOf(context).width >= 1180;

    return Scaffold(
      appBar: AppBar(title: const UpperText('WORKSPACE DE SESIONES')),
      body: Padding(
        padding: const EdgeInsets.all(12),
        child: isWide
            ? Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 320,
                    child: _LeftPanel(
                      sessions: workspace.sessions,
                      activeId: workspace.activeSessionId,
                      compact: false,
                      onSelect: workspaceVm.selectSession,
                      onDelete: (id) => workspaceVm.deleteSession(id),
                      onGenerate: () => _handleGenerateSession(resources),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _CenterPanel(
                      active: active,
                      onOpenGame: (session) => _openGame(session),
                      onSaveSession: (session) =>
                          workspaceVm.saveSession(session),
                    ),
                  ),
                  const SizedBox(width: 12),
                  SizedBox(
                    width: 320,
                    child: _RightPanel(
                      messages: workspace.copilotMessages,
                      isLoading: workspace.isCopilotLoading,
                      errorMessage: workspace.errorMessage,
                      controller: _copilotController,
                      onSend: (text) async {
                        await workspaceVm.sendCopilotMessage(text);
                        if (mounted) {
                          _copilotController.clear();
                        }
                      },
                    ),
                  ),
                ],
              )
            : ListView(
                children: [
                  _LeftPanel(
                    sessions: workspace.sessions,
                    activeId: workspace.activeSessionId,
                    compact: true,
                    onSelect: workspaceVm.selectSession,
                    onDelete: (id) => workspaceVm.deleteSession(id),
                    onGenerate: () => _handleGenerateSession(resources),
                  ),
                  const SizedBox(height: 10),
                  _CenterPanel(
                    active: active,
                    onOpenGame: (session) => _openGame(session),
                    onSaveSession: (session) =>
                        workspaceVm.saveSession(session),
                  ),
                  const SizedBox(height: 10),
                  _RightPanel(
                    messages: workspace.copilotMessages,
                    isLoading: workspace.isCopilotLoading,
                    errorMessage: workspace.errorMessage,
                    controller: _copilotController,
                    onSend: (text) async {
                      await workspaceVm.sendCopilotMessage(text);
                      if (mounted) {
                        _copilotController.clear();
                      }
                    },
                  ),
                ],
              ),
      ),
    );
  }

  Future<void> _handleGenerateSession(List<AiResource> resources) async {
    final picked = _pickResource(resources);
    if (picked == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No hay recursos IA para generar sesión.'),
        ),
      );
      return;
    }
    final config = await _showGenerationDialog(resources, picked.id);
    if (!mounted || config == null) {
      return;
    }
    AiResource? selected;
    for (final resource in resources) {
      if (resource.id == config.resourceId) {
        selected = resource;
        break;
      }
    }
    if (selected == null) {
      return;
    }
    await ref
        .read(sessionWorkspaceViewModelProvider.notifier)
        .generateSessionFromResource(
          selected,
          totalMinutesOverride: config.minutes,
          maxActivitySteps: config.maxSteps,
          includeGameBlock: config.includeGameBlock,
        );
  }

  void _openGame(SessionPlan session) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => GeneratedSessionGameScreen(
          resourceId: session.sourceResourceId,
          sessionTitle: session.title,
        ),
      ),
    );
  }

  Future<_SessionGenerationConfig?> _showGenerationDialog(
    List<AiResource> resources,
    String initialResourceId,
  ) async {
    String selectedResourceId = initialResourceId;
    int selectedMinutes = 45;
    int selectedSteps = 4;
    bool includeGame = true;
    return showDialog<_SessionGenerationConfig>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const UpperText('NUEVA SESIÓN'),
              content: SizedBox(
                width: 460,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    DropdownButtonFormField<String>(
                      value: selectedResourceId,
                      decoration: const InputDecoration(
                        labelText: 'RECURSO BASE',
                      ),
                      items: resources.map((resource) {
                        return DropdownMenuItem<String>(
                          value: resource.id,
                          child: Text(
                            resource.title,
                            overflow: TextOverflow.ellipsis,
                          ),
                        );
                      }).toList(),
                      onChanged: (value) {
                        if (value == null) return;
                        setState(() => selectedResourceId = value);
                      },
                    ),
                    const SizedBox(height: 10),
                    DropdownButtonFormField<int>(
                      value: selectedMinutes,
                      decoration: const InputDecoration(
                        labelText: 'TIEMPO TOTAL (MIN)',
                      ),
                      items: const [15, 30, 45, 60].map((min) {
                        return DropdownMenuItem<int>(
                          value: min,
                          child: Text('$min MIN'),
                        );
                      }).toList(),
                      onChanged: (value) {
                        if (value == null) return;
                        setState(() => selectedMinutes = value);
                      },
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        const Expanded(
                          child: UpperText(
                            'PASOS POR BLOQUE',
                            style: TextStyle(fontWeight: FontWeight.w800),
                          ),
                        ),
                        DropdownButton<int>(
                          value: selectedSteps,
                          items: const [3, 4, 5, 6, 7, 8].map((steps) {
                            return DropdownMenuItem<int>(
                              value: steps,
                              child: Text('$steps'),
                            );
                          }).toList(),
                          onChanged: (value) {
                            if (value == null) return;
                            setState(() => selectedSteps = value);
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    SwitchListTile.adaptive(
                      contentPadding: EdgeInsets.zero,
                      value: includeGame,
                      title: const UpperText('AÑADIR BLOQUE DE JUEGO'),
                      onChanged: (value) => setState(() => includeGame = value),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const UpperText('CANCELAR'),
                ),
                FilledButton(
                  onPressed: () {
                    Navigator.of(context).pop(
                      _SessionGenerationConfig(
                        resourceId: selectedResourceId,
                        minutes: selectedMinutes,
                        maxSteps: selectedSteps,
                        includeGameBlock: includeGame,
                      ),
                    );
                  },
                  child: const UpperText('CREAR'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  AiResource? _pickResource(List<AiResource> resources) {
    if (resources.isEmpty) {
      return null;
    }
    for (final resource in resources) {
      if (resource.isFavorite) {
        return resource;
      }
    }
    return resources.first;
  }
}

class _LeftPanel extends StatelessWidget {
  const _LeftPanel({
    required this.sessions,
    required this.activeId,
    required this.compact,
    required this.onSelect,
    required this.onDelete,
    required this.onGenerate,
  });

  final List<SessionPlan> sessions;
  final String? activeId;
  final bool compact;
  final ValueChanged<String> onSelect;
  final ValueChanged<String> onDelete;
  final VoidCallback onGenerate;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            color: const Color(0xFFFFF5F8),
            border: Border.all(color: const Color(0xFFF5C7D4)),
          ),
          child: const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              UpperText(
                'SALDO DISPONIBLE',
                style: TextStyle(fontWeight: FontWeight.w900),
              ),
              SizedBox(height: 8),
              UpperText(
                '50',
                style: TextStyle(fontSize: 40, fontWeight: FontWeight.w900),
              ),
              UpperText('SESIONES DE ESTE PERIODO'),
            ],
          ),
        ),
        const SizedBox(height: 10),
        FilledButton.icon(
          onPressed: onGenerate,
          icon: const Icon(Icons.add_rounded),
          label: const UpperText('NUEVA SESIÓN'),
        ),
        const SizedBox(height: 10),
        if (compact)
          SizedBox(height: 420, child: _sessionList(context))
        else
          Expanded(child: _sessionList(context)),
      ],
    );
  }

  Widget _sessionList(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Theme.of(context).colorScheme.outline),
      ),
      child: sessions.isEmpty
          ? const Center(child: Text('Sin sesiones'))
          : ListView.builder(
              itemCount: sessions.length,
              itemBuilder: (context, index) {
                final session = sessions[index];
                final selected = activeId == session.id;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: InkWell(
                    onTap: () => onSelect(session.id),
                    borderRadius: BorderRadius.circular(12),
                    child: Ink(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        color: selected
                            ? const Color(0xFFFFEEF4)
                            : Theme.of(context).colorScheme.surface,
                        border: Border.all(
                          color: selected
                              ? const Color(0xFFF3A9C0)
                              : Theme.of(context).colorScheme.outline,
                        ),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  session.title,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '${session.domain} · ${session.totalMinutes} MIN',
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            onPressed: () => onDelete(session.id),
                            icon: const Icon(Icons.delete_outline_rounded),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
    );
  }
}

class _CenterPanel extends StatelessWidget {
  const _CenterPanel({
    required this.active,
    required this.onOpenGame,
    required this.onSaveSession,
  });

  final SessionPlan? active;
  final ValueChanged<SessionPlan> onOpenGame;
  final Future<void> Function(SessionPlan session) onSaveSession;

  @override
  Widget build(BuildContext context) {
    final session = active;
    if (session == null) {
      return Center(
        child: Text(
          'Genera una sesión para ver el guion aquí.',
          style: Theme.of(context).textTheme.titleLarge,
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Theme.of(context).colorScheme.outline),
      ),
      child: ListView(
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  session.title,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFE8FFF2),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  session.status,
                  style: const TextStyle(fontWeight: FontWeight.w900),
                ),
              ),
              const SizedBox(width: 8),
              OutlinedButton.icon(
                onPressed: () async {
                  final updated = await _showSessionEditDialog(
                    context,
                    session,
                  );
                  if (updated != null) {
                    await onSaveSession(updated);
                  }
                },
                icon: const Icon(Icons.edit_outlined),
                label: const UpperText('EDITAR'),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            '${session.ageRange} · ${session.durationLabel} · ${session.modeLabel} · ${session.domain}',
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              color: const Color(0xFFF8FBFF),
              border: Border.all(color: const Color(0xFFD8E8FF)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'OBJETIVO GENERAL',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 6),
                Text(session.objective),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'GUION DE LA SESIÓN',
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 8),
          ...(session.blocks.map((block) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  color: const Color(0xFFFFF5F8),
                  border: Border.all(color: const Color(0xFFF6C8D8)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            block.title,
                            style: Theme.of(context).textTheme.titleLarge
                                ?.copyWith(fontWeight: FontWeight.w800),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFE4F2FF),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            '${block.durationMin} MIN',
                            style: const TextStyle(fontWeight: FontWeight.w900),
                          ),
                        ),
                        const SizedBox(width: 6),
                        IconButton(
                          tooltip: 'Editar bloque',
                          onPressed: () async {
                            final updated = await _showBlockEditDialog(
                              context: context,
                              session: session,
                              blockIndex: session.blocks.indexOf(block),
                            );
                            if (updated != null) {
                              await onSaveSession(updated);
                            }
                          },
                          icon: const Icon(Icons.tune_rounded),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    ...(block.lines.map((line) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Text('• $line'),
                      );
                    })),
                    if (block.hasGame) ...[
                      const SizedBox(height: 8),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: FilledButton.icon(
                          onPressed: () => onOpenGame(session),
                          icon: const Icon(Icons.play_arrow_rounded),
                          label: const UpperText('ABRIR JUEGO GENERADO'),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            );
          })),
        ],
      ),
    );
  }

  Future<SessionPlan?> _showSessionEditDialog(
    BuildContext context,
    SessionPlan session,
  ) {
    final titleController = TextEditingController(text: session.title);
    final objectiveController = TextEditingController(text: session.objective);
    String age = _ageOptions.contains(session.ageRange)
        ? session.ageRange
        : _ageOptions.first;
    String duration = _durationOptions.contains(session.durationLabel)
        ? session.durationLabel
        : _durationOptions[2];
    String mode = _modeOptions.contains(session.modeLabel)
        ? session.modeLabel
        : _modeOptions.first;
    String category = _categoryOptions.contains(session.domain)
        ? session.domain
        : _categoryOptions.first;
    int minutes = session.totalMinutes;

    return showDialog<SessionPlan>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const UpperText('EDITAR SESIÓN'),
              content: SizedBox(
                width: 520,
                child: ListView(
                  shrinkWrap: true,
                  children: [
                    TextField(
                      controller: titleController,
                      decoration: const InputDecoration(labelText: 'TÍTULO'),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: objectiveController,
                      minLines: 2,
                      maxLines: 4,
                      decoration: const InputDecoration(labelText: 'OBJETIVO'),
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      value: age,
                      decoration: const InputDecoration(labelText: 'EDAD'),
                      items: _ageOptions
                          .map(
                            (item) => DropdownMenuItem(
                              value: item,
                              child: Text(item),
                            ),
                          )
                          .toList(),
                      onChanged: (value) {
                        if (value != null) {
                          setState(() => age = value);
                        }
                      },
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      value: duration,
                      decoration: const InputDecoration(labelText: 'DURACIÓN'),
                      items: _durationOptions
                          .map(
                            (item) => DropdownMenuItem(
                              value: item,
                              child: Text(item),
                            ),
                          )
                          .toList(),
                      onChanged: (value) {
                        if (value != null) {
                          setState(() => duration = value);
                        }
                      },
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<int>(
                      value: minutes,
                      decoration: const InputDecoration(
                        labelText: 'MINUTOS TOTALES',
                      ),
                      items: const [15, 30, 45, 60]
                          .map(
                            (item) => DropdownMenuItem(
                              value: item,
                              child: Text('$item'),
                            ),
                          )
                          .toList(),
                      onChanged: (value) {
                        if (value != null) {
                          setState(() => minutes = value);
                        }
                      },
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      value: mode,
                      decoration: const InputDecoration(labelText: 'MODO'),
                      items: _modeOptions
                          .map(
                            (item) => DropdownMenuItem(
                              value: item,
                              child: Text(item),
                            ),
                          )
                          .toList(),
                      onChanged: (value) {
                        if (value != null) {
                          setState(() => mode = value);
                        }
                      },
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      value: category,
                      decoration: const InputDecoration(labelText: 'CATEGORÍA'),
                      items: _categoryOptions
                          .map(
                            (item) => DropdownMenuItem(
                              value: item,
                              child: Text(item),
                            ),
                          )
                          .toList(),
                      onChanged: (value) {
                        if (value != null) {
                          setState(() => category = value);
                        }
                      },
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const UpperText('CANCELAR'),
                ),
                FilledButton(
                  onPressed: () {
                    Navigator.of(context).pop(
                      session.copyWith(
                        title: titleController.text.trim(),
                        objective: objectiveController.text.trim(),
                        ageRange: age,
                        durationLabel: duration,
                        modeLabel: mode,
                        domain: category,
                        totalMinutes: minutes,
                      ),
                    );
                  },
                  child: const UpperText('GUARDAR'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<SessionPlan?> _showBlockEditDialog({
    required BuildContext context,
    required SessionPlan session,
    required int blockIndex,
  }) {
    final target = session.blocks[blockIndex];
    final titleController = TextEditingController(text: target.title);
    final linesController = TextEditingController(
      text: target.lines.join('\n'),
    );
    int duration = target.durationMin;
    bool hasGame = target.hasGame;
    return showDialog<SessionPlan>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: UpperText('EDITAR BLOQUE ${blockIndex + 1}'),
              content: SizedBox(
                width: 480,
                child: ListView(
                  shrinkWrap: true,
                  children: [
                    TextField(
                      controller: titleController,
                      decoration: const InputDecoration(
                        labelText: 'TÍTULO BLOQUE',
                      ),
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<int>(
                      value: duration.clamp(5, 40),
                      decoration: const InputDecoration(
                        labelText: 'DURACIÓN (MIN)',
                      ),
                      items: [
                        for (var i = 5; i <= 40; i += 5)
                          DropdownMenuItem(value: i, child: Text('$i')),
                      ],
                      onChanged: (value) {
                        if (value != null) {
                          setState(() => duration = value);
                        }
                      },
                    ),
                    const SizedBox(height: 8),
                    SwitchListTile.adaptive(
                      contentPadding: EdgeInsets.zero,
                      value: hasGame,
                      title: const UpperText('INCLUIR BOTÓN DE JUEGO'),
                      onChanged: (value) => setState(() => hasGame = value),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: linesController,
                      minLines: 4,
                      maxLines: 8,
                      decoration: const InputDecoration(
                        labelText: 'LÍNEAS (UNA POR CADA RENGLÓN)',
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const UpperText('CANCELAR'),
                ),
                FilledButton(
                  onPressed: () {
                    final lines = linesController.text
                        .split('\n')
                        .map((line) => line.trim())
                        .where((line) => line.isNotEmpty)
                        .toList();
                    final blocks = [...session.blocks];
                    blocks[blockIndex] = blocks[blockIndex].copyWith(
                      title: titleController.text.trim(),
                      durationMin: duration,
                      hasGame: hasGame,
                      lines: lines.isEmpty ? blocks[blockIndex].lines : lines,
                    );
                    Navigator.of(context).pop(session.copyWith(blocks: blocks));
                  },
                  child: const UpperText('GUARDAR'),
                ),
              ],
            );
          },
        );
      },
    );
  }
}

class _SessionGenerationConfig {
  const _SessionGenerationConfig({
    required this.resourceId,
    required this.minutes,
    required this.maxSteps,
    required this.includeGameBlock,
  });

  final String resourceId;
  final int minutes;
  final int maxSteps;
  final bool includeGameBlock;
}

class _RightPanel extends StatelessWidget {
  const _RightPanel({
    required this.messages,
    required this.isLoading,
    required this.errorMessage,
    required this.controller,
    required this.onSend,
  });

  final List<SessionCopilotMessage> messages;
  final bool isLoading;
  final String? errorMessage;
  final TextEditingController controller;
  final Future<void> Function(String) onSend;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Theme.of(context).colorScheme.outline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const UpperText(
            'COPILOTO',
            style: TextStyle(fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                color: const Color(0xFFF8FBFF),
                border: Border.all(color: const Color(0xFFDDE8F8)),
              ),
              child: ListView(
                children: [
                  for (final msg in messages)
                    Align(
                      alignment: msg.role == 'user'
                          ? Alignment.centerRight
                          : Alignment.centerLeft,
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.all(10),
                        constraints: const BoxConstraints(maxWidth: 260),
                        decoration: BoxDecoration(
                          color: msg.role == 'user'
                              ? const Color(0xFFE4F6F2)
                              : const Color(0xFFF5F7FB),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Theme.of(context).colorScheme.outline,
                          ),
                        ),
                        child: Text(msg.text),
                      ),
                    ),
                  if (isLoading)
                    const Padding(
                      padding: EdgeInsets.all(8),
                      child: LinearProgressIndicator(),
                    ),
                  if (errorMessage != null && errorMessage!.trim().isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        errorMessage!,
                        style: const TextStyle(color: Colors.red),
                      ),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: controller,
            minLines: 2,
            maxLines: 3,
            decoration: InputDecoration(
              hintText: 'Escribe tu consulta de sesión',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          const SizedBox(height: 8),
          FilledButton.icon(
            onPressed: isLoading ? null : () => onSend(controller.text),
            icon: const Icon(Icons.send_rounded),
            label: const UpperText('ENVIAR'),
          ),
        ],
      ),
    );
  }
}
