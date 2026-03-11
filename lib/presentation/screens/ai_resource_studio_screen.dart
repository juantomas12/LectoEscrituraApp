import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/providers/app_providers.dart';
import '../../core/config/env_config.dart';
import '../../core/utils/text_utils.dart';
import '../../domain/models/ai_quiz_question.dart';
import '../../domain/models/ai_resource.dart';
import '../../domain/models/activity_type.dart';
import '../../domain/models/category.dart';
import '../utils/category_visuals.dart';
import '../viewmodels/ai_resource_studio_view_model.dart';
import '../viewmodels/settings_view_model.dart';
import '../widgets/activity_asset_image.dart';
import '../widgets/upper_text.dart';
import 'session_workspace_screen.dart';

const _aiStudioGameChoices = <ActivityType>[
  ActivityType.imagenPalabra,
  ActivityType.escribirPalabra,
  ActivityType.palabraPalabra,
  ActivityType.imagenFrase,
  ActivityType.sonidos,
  ActivityType.letraObjetivo,
  ActivityType.cambioExacto,
  ActivityType.ruletaLetras,
  ActivityType.discriminacion,
  ActivityType.discriminacionInversa,
];

String _studioGameLabel(ActivityType type) {
  return switch (type) {
    ActivityType.imagenPalabra => 'IMAGEN Y PALABRA',
    ActivityType.escribirPalabra => 'ESCRIBIR PALABRA',
    ActivityType.palabraPalabra => 'PALABRA CON PALABRA',
    ActivityType.imagenFrase => 'IMAGEN Y FRASE',
    ActivityType.sonidos => 'JUEGO DE SONIDOS',
    ActivityType.letraObjetivo => 'LETRAS Y VOCALES',
    ActivityType.cambioExacto => 'TIENDA DE CHUCHES',
    ActivityType.ruletaLetras => 'RULETA DE LETRAS',
    ActivityType.discriminacion => 'DISCRIMINACIÓN',
    ActivityType.discriminacionInversa => 'DISCRIMINACIÓN INVERSA',
  };
}

String _studioGameDescription(ActivityType type) {
  return switch (type) {
    ActivityType.imagenPalabra =>
      'ASOCIA CADA IMAGEN CON SU PALABRA Y REFUERZA VOCABULARIO.',
    ActivityType.escribirPalabra =>
      'OBSERVA LA IMAGEN Y ESCRIBE LA PALABRA CORRECTA PASO A PASO.',
    ActivityType.palabraPalabra =>
      'RELACIONA PALABRAS ENTRE SÍ PARA TRABAJAR SIGNIFICADO Y MEMORIA.',
    ActivityType.imagenFrase =>
      'UNE UNA FRASE CON LA IMAGEN CORRECTA PARA COMPRENSIÓN LECTORA.',
    ActivityType.sonidos =>
      'ESCUCHA UN SONIDO Y SELECCIONA LA IMAGEN QUE LO REPRESENTA.',
    ActivityType.letraObjetivo =>
      'ENTRENA LETRAS Y VOCALES EN CONTEXTOS VISUALES ADAPTADOS.',
    ActivityType.cambioExacto =>
      'TRABAJA DINERO Y CÁLCULO MENTAL CON RETOS DE CAMBIO EXACTO.',
    ActivityType.ruletaLetras =>
      'LA RULETA DEFINE RETOS DINÁMICOS PARA CONCIENCIA FONOLÓGICA.',
    ActivityType.discriminacion =>
      'MEJORA ATENCIÓN VISUAL ENCONTRANDO OPCIONES CORRECTAS.',
    ActivityType.discriminacionInversa =>
      'IDENTIFICA EL INTRUSO Y PRACTICA DISCRIMINACIÓN AVANZADA.',
  };
}

class _StudioGameVisual {
  const _StudioGameVisual({
    required this.focusTag,
    required this.storyIcons,
    required this.storyChips,
    required this.icon,
    required this.startColor,
    required this.endColor,
  });

  final String focusTag;
  final List<IconData> storyIcons;
  final List<String> storyChips;
  final IconData icon;
  final Color startColor;
  final Color endColor;
}

const _studioGameVisuals = <ActivityType, _StudioGameVisual>{
  ActivityType.imagenPalabra: _StudioGameVisual(
    focusTag: 'VOCABULARIO',
    storyIcons: [
      Icons.image_rounded,
      Icons.text_fields_rounded,
      Icons.link_rounded,
    ],
    storyChips: ['IMAGEN', 'PALABRA'],
    icon: Icons.image_search_rounded,
    startColor: Color(0xFF7AD7F0),
    endColor: Color(0xFF72E6B4),
  ),
  ActivityType.escribirPalabra: _StudioGameVisual(
    focusTag: 'ESCRITURA',
    storyIcons: [
      Icons.edit_rounded,
      Icons.spellcheck_rounded,
      Icons.draw_rounded,
    ],
    storyChips: ['TRAZO', 'COPIA'],
    icon: Icons.edit_note_rounded,
    startColor: Color(0xFFFFC66A),
    endColor: Color(0xFFFF9E7C),
  ),
  ActivityType.palabraPalabra: _StudioGameVisual(
    focusTag: 'RELACIÓN',
    storyIcons: [
      Icons.short_text_rounded,
      Icons.compare_arrows_rounded,
      Icons.menu_book_rounded,
    ],
    storyChips: ['PALABRAS', 'RELACIÓN'],
    icon: Icons.compare_arrows_rounded,
    startColor: Color(0xFFA4A0FF),
    endColor: Color(0xFF8D86F8),
  ),
  ActivityType.imagenFrase: _StudioGameVisual(
    focusTag: 'COMPRENSIÓN',
    storyIcons: [
      Icons.image_rounded,
      Icons.notes_rounded,
      Icons.auto_stories_rounded,
    ],
    storyChips: ['FRASE', 'LECTURA'],
    icon: Icons.auto_stories_rounded,
    startColor: Color(0xFF88D4FF),
    endColor: Color(0xFF6EC5FF),
  ),
  ActivityType.sonidos: _StudioGameVisual(
    focusTag: 'ESCUCHA',
    storyIcons: [
      Icons.volume_up_rounded,
      Icons.hearing_rounded,
      Icons.image_search_rounded,
    ],
    storyChips: ['SONIDO', 'IMAGEN'],
    icon: Icons.volume_up_rounded,
    startColor: Color(0xFF84E2C0),
    endColor: Color(0xFF6EC5FF),
  ),
  ActivityType.letraObjetivo: _StudioGameVisual(
    focusTag: 'LETRAS',
    storyIcons: [
      Icons.sort_by_alpha_rounded,
      Icons.text_fields_rounded,
      Icons.hearing_rounded,
    ],
    storyChips: ['LETRAS', 'VOCALES'],
    icon: Icons.sort_by_alpha_rounded,
    startColor: Color(0xFF90E7D7),
    endColor: Color(0xFF76D6E8),
  ),
  ActivityType.cambioExacto: _StudioGameVisual(
    focusTag: 'EUROS',
    storyIcons: [
      Icons.attach_money_rounded,
      Icons.shopping_bag_rounded,
      Icons.calculate_rounded,
    ],
    storyChips: ['TIENDA', 'EUROS'],
    icon: Icons.local_mall_rounded,
    startColor: Color(0xFFFFC2A0),
    endColor: Color(0xFFFF9FC6),
  ),
  ActivityType.ruletaLetras: _StudioGameVisual(
    focusTag: 'RULETA',
    storyIcons: [
      Icons.casino_rounded,
      Icons.refresh_rounded,
      Icons.text_fields_rounded,
    ],
    storyChips: ['RULETA', 'RETO'],
    icon: Icons.casino_rounded,
    startColor: Color(0xFFFFD17A),
    endColor: Color(0xFFFFC36A),
  ),
  ActivityType.discriminacion: _StudioGameVisual(
    focusTag: 'ATENCIÓN',
    storyIcons: [
      Icons.visibility_rounded,
      Icons.center_focus_strong_rounded,
      Icons.check_circle_rounded,
    ],
    storyChips: ['ATENCIÓN', 'SELECCIÓN'],
    icon: Icons.visibility_rounded,
    startColor: Color(0xFF92E6B3),
    endColor: Color(0xFF71D9D0),
  ),
  ActivityType.discriminacionInversa: _StudioGameVisual(
    focusTag: 'INTRUSO',
    storyIcons: [
      Icons.search_rounded,
      Icons.remove_circle_rounded,
      Icons.psychology_alt_rounded,
    ],
    storyChips: ['INTRUSO', 'DETECTIVE'],
    icon: Icons.change_circle_rounded,
    startColor: Color(0xFFFFB7D5),
    endColor: Color(0xFFFFA899),
  ),
};

class _StudioModeVisual {
  const _StudioModeVisual({
    required this.value,
    required this.icon,
    required this.title,
    required this.description,
    required this.color,
  });

  final String value;
  final IconData icon;
  final String title;
  final String description;
  final Color color;
}

const _studioModeVisuals = <_StudioModeVisual>[
  _StudioModeVisual(
    value: 'SITUACIÓN DE APRENDIZAJE',
    icon: Icons.auto_stories_rounded,
    title: 'SITUACIÓN REAL',
    description: 'SECUENCIA COMPLETA CON OBJETIVO, PASOS Y CIERRE.',
    color: Color(0xFF0F8A6A),
  ),
  _StudioModeVisual(
    value: 'ACTIVIDAD DE PREGUNTAS',
    icon: Icons.quiz_rounded,
    title: 'PREGUNTAS GUIADAS',
    description: 'TRABAJO DIRECTO CON PREGUNTAS CORTAS Y RETROALIMENTACIÓN.',
    color: Color(0xFF1E79B8),
  ),
  _StudioModeVisual(
    value: 'MINI-JUEGO GUIADO',
    icon: Icons.sports_esports_rounded,
    title: 'MINI-JUEGO',
    description: 'FORMATO LÚDICO CON RETOS CORTOS Y RESPUESTA INMEDIATA.',
    color: Color(0xFFAD5F00),
  ),
];

ActivityType? _activityTypeFromStoredKey(String rawKey) {
  final normalized = rawKey.trim().toUpperCase();
  if (normalized.isEmpty) {
    return null;
  }
  for (final type in ActivityType.values) {
    if (type.key == normalized) {
      return type;
    }
  }
  return null;
}

String _resourceRequestedGameLabel(AiResource resource) {
  final type = _activityTypeFromStoredKey(resource.requestedActivityTypeKey);
  if (type == null) {
    return 'JUEGO APP: AUTO';
  }
  return 'JUEGO APP: ${_studioGameLabel(type)}';
}

class AiResourceStudioScreen extends ConsumerStatefulWidget {
  const AiResourceStudioScreen({super.key});

  @override
  ConsumerState<AiResourceStudioScreen> createState() =>
      _AiResourceStudioScreenState();
}

class _AiResourceStudioScreenState
    extends ConsumerState<AiResourceStudioScreen> {
  static const _maxPromptLength = 1000;
  static const _wizardTotalSteps = 3;

  final _instructionController = TextEditingController();
  final _apiKeyController = TextEditingController();
  final _modelController = TextEditingController(text: EnvConfig.openAiModel);
  final _searchController = TextEditingController();
  bool _didSyncKeyFromSettings = false;

  String _ageRange = 'INFANTIL (7-12)';
  String _duration = '10-15 MIN';
  String _mode = 'SITUACIÓN DE APRENDIZAJE';
  AppCategory _category = AppCategory.mixta;
  ActivityType _requestedGameType = ActivityType.imagenPalabra;
  int _wizardStep = 0;
  bool _showWizard = true;
  bool _onlyFavorites = false;
  AiResource? _selectedResource;

  bool get _hasInstruction => _instructionController.text.trim().isNotEmpty;

  bool _canMoveForwardFromCurrentStep() {
    if (_wizardStep == 0) {
      return _hasInstruction;
    }
    return true;
  }

  void _goToNextStep() {
    if (!_canMoveForwardFromCurrentStep()) {
      final messenger = ScaffoldMessenger.maybeOf(context);
      messenger?.hideCurrentSnackBar();
      messenger?.showSnackBar(
        const SnackBar(
          content: UpperText('ESCRIBE EL CASO PARA PODER CONTINUAR'),
        ),
      );
      return;
    }
    if (_wizardStep >= _wizardTotalSteps - 1) {
      return;
    }
    setState(() {
      _wizardStep++;
    });
  }

  void _goToPreviousStep() {
    if (_wizardStep <= 0) {
      return;
    }
    setState(() {
      _wizardStep--;
    });
  }

  Widget _buildWizardMilestones(BuildContext context) {
    final milestones = <(String label, IconData icon)>[
      ('CASO', Icons.edit_note_rounded),
      ('DISEÑO', Icons.palette_rounded),
      ('GENERAR', Icons.auto_awesome_rounded),
    ];
    final colorScheme = Theme.of(context).colorScheme;

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: List<Widget>.generate(milestones.length, (index) {
        final isActive = _wizardStep == index;
        final isCompleted = _wizardStep > index;
        final fg = isActive || isCompleted ? Colors.white : colorScheme.primary;
        final bg = isActive
            ? colorScheme.primary
            : isCompleted
            ? const Color(0xFF0F8A6A)
            : colorScheme.primary.withValues(alpha: 0.10);
        final border = isActive || isCompleted
            ? Colors.transparent
            : colorScheme.primary.withValues(alpha: 0.24);

        return AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: border),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                isCompleted ? Icons.check_rounded : milestones[index].$2,
                size: 16,
                color: fg,
              ),
              const SizedBox(width: 6),
              UpperText(
                milestones[index].$1,
                style: TextStyle(
                  color: fg,
                  fontWeight: FontWeight.w900,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        );
      }),
    );
  }

  Widget _buildStudioGamePreview({
    required _StudioGameVisual visual,
    required String semanticsLabel,
    double height = 112,
    double borderRadius = 14,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    final storyIcons = visual.storyIcons.isEmpty
        ? const [
            Icons.toys_rounded,
            Icons.star_rounded,
            Icons.auto_awesome_rounded,
          ]
        : visual.storyIcons;
    final storyChips = visual.storyChips.isEmpty
        ? const ['JUEGO', 'CLASE']
        : visual.storyChips;

    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: Semantics(
        label: semanticsLabel,
        child: SizedBox(
          height: height,
          child: Stack(
            fit: StackFit.expand,
            children: [
              DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [visual.startColor, visual.endColor],
                  ),
                ),
              ),
              Positioned(
                right: -20,
                top: -20,
                child: Container(
                  width: 92,
                  height: 92,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.24),
                    shape: BoxShape.circle,
                  ),
                ),
              ),
              Positioned(
                left: -24,
                bottom: -26,
                child: Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.16),
                    shape: BoxShape.circle,
                  ),
                ),
              ),
              Positioned(
                left: 10,
                top: 10,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.92),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: UpperText(
                    visual.focusTag,
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ),
              Positioned.fill(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(12, 14, 12, 12),
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.90),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.95),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.08),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          alignment: WrapAlignment.center,
                          children: List<Widget>.generate(3, (index) {
                            final icon = storyIcons[index % storyIcons.length];
                            return Container(
                              width: 30,
                              height: 30,
                              decoration: BoxDecoration(
                                color: visual.endColor.withValues(alpha: 0.22),
                                borderRadius: BorderRadius.circular(9),
                              ),
                              child: Icon(
                                icon,
                                size: 18,
                                color: colorScheme.primary,
                              ),
                            );
                          }),
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          alignment: WrapAlignment.center,
                          children: storyChips.map((chip) {
                            return Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: visual.startColor.withValues(
                                  alpha: 0.20,
                                ),
                                borderRadius: BorderRadius.circular(999),
                              ),
                              child: UpperText(
                                chip,
                                style: const TextStyle(
                                  fontSize: 9,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              Positioned(
                right: 10,
                bottom: 8,
                child: Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.94),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    visual.icon,
                    color: colorScheme.primary,
                    size: 19,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStepTwoStudioDesign(BuildContext context) {
    final selectedVisual =
        _studioGameVisuals[_requestedGameType] ??
        _studioGameVisuals[ActivityType.imagenPalabra]!;
    final selectedCategoryColor = _category.color;
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const UpperText(
          '2) DISEÑA TU EXPERIENCIA',
          style: TextStyle(fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: 4),
        UpperText(
          'SELECCIONA UN SOLO JUEGO BASE Y COMPLETA LOS AJUSTES VISUALES.',
          style: Theme.of(
            context,
          ).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                selectedVisual.startColor,
                selectedVisual.endColor,
                Colors.white,
              ],
            ),
            border: Border.all(
              color: colorScheme.primary.withValues(alpha: 0.24),
              width: 1.4,
            ),
          ),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final compact = constraints.maxWidth < 760;
              final selectionBadge = Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.78),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.radio_button_checked_rounded, size: 14),
                    SizedBox(width: 4),
                    UpperText(
                      'SELECCIÓN ÚNICA',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
              );
              final gameInfo = Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  UpperText(
                    _studioGameLabel(_requestedGameType),
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 2),
                  UpperText(
                    _studioGameDescription(_requestedGameType),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              );
              final preview = _buildStudioGamePreview(
                visual: selectedVisual,
                semanticsLabel: _studioGameLabel(_requestedGameType),
                height: compact ? 94 : 88,
                borderRadius: 12,
              );

              if (compact) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    preview,
                    const SizedBox(height: 10),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(child: gameInfo),
                        const SizedBox(width: 8),
                        selectionBadge,
                      ],
                    ),
                  ],
                );
              }

              return Row(
                children: [
                  SizedBox(width: 210, child: preview),
                  const SizedBox(width: 12),
                  Expanded(child: gameInfo),
                  const SizedBox(width: 10),
                  selectionBadge,
                ],
              );
            },
          ),
        ),
        const SizedBox(height: 10),
        UpperText(
          'JUEGO APP A GENERAR',
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: 8),
        LayoutBuilder(
          builder: (context, constraints) {
            const spacing = 12.0;
            final width = constraints.maxWidth;
            final cardWidth = width >= 1060
                ? (width - (spacing * 3)) / 4
                : width >= 780
                ? (width - (spacing * 2)) / 3
                : width >= 520
                ? (width - spacing) / 2
                : width;

            return Wrap(
              spacing: spacing,
              runSpacing: spacing,
              children: _aiStudioGameChoices.map((gameType) {
                final visual = _studioGameVisuals[gameType]!;
                final selected = _requestedGameType == gameType;
                final borderColor = selected
                    ? colorScheme.primary
                    : colorScheme.outline.withValues(alpha: 0.35);
                final surfaceColor = selected
                    ? colorScheme.primary.withValues(alpha: 0.08)
                    : Colors.white;

                return SizedBox(
                  width: cardWidth,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    decoration: BoxDecoration(
                      color: surfaceColor,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                        color: borderColor,
                        width: selected ? 2.1 : 1.2,
                      ),
                      boxShadow: selected
                          ? [
                              BoxShadow(
                                color: colorScheme.primary.withValues(
                                  alpha: 0.20,
                                ),
                                blurRadius: 14,
                                offset: const Offset(0, 6),
                              ),
                            ]
                          : null,
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(18),
                        onTap: () =>
                            setState(() => _requestedGameType = gameType),
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    width: 30,
                                    height: 30,
                                    decoration: BoxDecoration(
                                      color: visual.endColor,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Icon(
                                      visual.icon,
                                      size: 18,
                                      color: colorScheme.primary,
                                    ),
                                  ),
                                  const Spacer(),
                                  Icon(
                                    selected
                                        ? Icons.check_circle_rounded
                                        : Icons.radio_button_unchecked_rounded,
                                    color: selected
                                        ? colorScheme.primary
                                        : colorScheme.outline,
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              SizedBox(
                                width: double.infinity,
                                child: _buildStudioGamePreview(
                                  visual: visual,
                                  semanticsLabel: _studioGameLabel(gameType),
                                  height: 118,
                                  borderRadius: 12,
                                ),
                              ),
                              const SizedBox(height: 8),
                              UpperText(
                                _studioGameLabel(gameType),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: Theme.of(context).textTheme.bodyMedium
                                    ?.copyWith(fontWeight: FontWeight.w900),
                              ),
                              const SizedBox(height: 3),
                              UpperText(
                                _studioGameDescription(gameType),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: Theme.of(context).textTheme.bodySmall
                                    ?.copyWith(fontWeight: FontWeight.w600),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            );
          },
        ),
        const SizedBox(height: 14),
        UpperText(
          'MODO',
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: 8),
        LayoutBuilder(
          builder: (context, constraints) {
            const spacing = 12.0;
            final width = constraints.maxWidth;
            final cardWidth = width >= 940
                ? (width - (spacing * 2)) / 3
                : width >= 620
                ? (width - spacing) / 2
                : width;

            return Wrap(
              spacing: spacing,
              runSpacing: spacing,
              children: _studioModeVisuals.map((option) {
                final selected = _mode == option.value;
                return SizedBox(
                  width: cardWidth,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      color: selected
                          ? option.color.withValues(alpha: 0.12)
                          : Colors.white,
                      border: Border.all(
                        color: selected
                            ? option.color
                            : colorScheme.outline.withValues(alpha: 0.40),
                        width: selected ? 1.8 : 1.1,
                      ),
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(16),
                        onTap: () => setState(() => _mode = option.value),
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                width: 34,
                                height: 34,
                                decoration: BoxDecoration(
                                  color: option.color.withValues(alpha: 0.18),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Icon(
                                  option.icon,
                                  size: 20,
                                  color: option.color,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    UpperText(
                                      option.title,
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodyMedium
                                          ?.copyWith(
                                            fontWeight: FontWeight.w900,
                                          ),
                                    ),
                                    const SizedBox(height: 2),
                                    UpperText(
                                      option.description,
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodySmall
                                          ?.copyWith(
                                            fontWeight: FontWeight.w600,
                                          ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 6),
                              Icon(
                                selected
                                    ? Icons.check_circle_rounded
                                    : Icons.circle_outlined,
                                color: selected
                                    ? option.color
                                    : colorScheme.outline,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            );
          },
        ),
        const SizedBox(height: 14),
        UpperText(
          'CATEGORÍA',
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: 8),
        LayoutBuilder(
          builder: (context, constraints) {
            const spacing = 10.0;
            final width = constraints.maxWidth;
            final cardWidth = width >= 1020
                ? (width - (spacing * 3)) / 4
                : width >= 730
                ? (width - (spacing * 2)) / 3
                : width >= 460
                ? (width - spacing) / 2
                : width;

            return Wrap(
              spacing: spacing,
              runSpacing: spacing,
              children: AppCategory.values.map((category) {
                final selected = _category == category;
                final color = category.color;
                return SizedBox(
                  width: cardWidth,
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(14),
                      onTap: () => setState(() => _category = category),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 11,
                        ),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(14),
                          color: selected
                              ? color.withValues(alpha: 0.16)
                              : Colors.white,
                          border: Border.all(
                            color: selected
                                ? color
                                : colorScheme.outline.withValues(alpha: 0.45),
                            width: selected ? 1.8 : 1.1,
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 30,
                              height: 30,
                              decoration: BoxDecoration(
                                color: color.withValues(alpha: 0.18),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(
                                category.icon,
                                color: color,
                                size: 18,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: UpperText(
                                category.label,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: Theme.of(context).textTheme.bodyMedium
                                    ?.copyWith(fontWeight: FontWeight.w800),
                              ),
                            ),
                            const SizedBox(width: 6),
                            Icon(
                              selected
                                  ? Icons.check_circle_rounded
                                  : Icons.radio_button_unchecked_rounded,
                              color: selected ? color : colorScheme.outline,
                              size: 18,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            );
          },
        ),
        const SizedBox(height: 10),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            color: selectedCategoryColor.withValues(alpha: 0.10),
            border: Border.all(
              color: selectedCategoryColor.withValues(alpha: 0.45),
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(_category.icon, color: selectedCategoryColor),
              const SizedBox(width: 8),
              Expanded(
                child: UpperText(
                  'CATEGORÍA ACTIVA: ${_category.label}. ESTA SE USARÁ PARA PRIORIZAR IMÁGENES Y VOCABULARIO EN LA GENERACIÓN.',
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _instructionController.dispose();
    _apiKeyController.dispose();
    _modelController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  List<String> _availableWordsForGeneration() {
    final dataset = ref.read(datasetRepositoryProvider);
    final all = dataset.getAllItems().where((item) {
      final word = (item.word ?? '').trim();
      return word.isNotEmpty &&
          item.activityType == ActivityType.imagenPalabra &&
          (_category == AppCategory.mixta || item.category == _category);
    });

    final unique =
        all.map((item) => item.word!.trim().toUpperCase()).toSet().toList()
          ..sort();
    if (unique.length <= 120) {
      return unique;
    }
    return unique.take(120).toList();
  }

  Map<String, String> _optionImageByWord(AiResource resource) {
    final dataset = ref.read(datasetRepositoryProvider);
    final all = dataset.getAllItems();
    final category = AppCategoryX.fromLabel(resource.categoryLabel);
    final output = <String, String>{};
    for (final item in all) {
      if (item.activityType != ActivityType.imagenPalabra) {
        continue;
      }
      final word = (item.word ?? '').trim();
      if (word.isEmpty) {
        continue;
      }
      if (category != AppCategory.mixta && item.category != category) {
        continue;
      }
      final normalized = normalizeWordForLetters(word);
      output.putIfAbsent(normalized, () => item.imageAsset);
    }
    return output;
  }

  Future<void> _generateResource() async {
    final instruction = _instructionController.text.trim();
    if (instruction.isEmpty) {
      return;
    }
    final settingsVm = ref.read(settingsViewModelProvider.notifier);
    final settings = ref.read(settingsViewModelProvider);

    if (!kIsWeb &&
        _apiKeyController.text.trim().isNotEmpty &&
        _apiKeyController.text.trim() != settings.openAiApiKey) {
      await settingsVm.setOpenAiApiKey(_apiKeyController.text.trim());
    }
    if (_modelController.text.trim().isNotEmpty &&
        _modelController.text.trim() != settings.openAiModel) {
      await settingsVm.setOpenAiModel(_modelController.text.trim());
    }

    final apiKey = _apiKeyController.text.trim().isNotEmpty
        ? _apiKeyController.text.trim()
        : settings.openAiApiKey;

    final generated = await ref
        .read(aiResourceStudioViewModelProvider.notifier)
        .generateAndSave(
          instruction: instruction,
          ageRange: _ageRange,
          duration: _duration,
          mode: _mode,
          categoryLabel: _category.label,
          difficultyLabel: 'AUTO POR EDAD',
          requestedGameType: _requestedGameType,
          apiKey: apiKey,
          allowedWords: _availableWordsForGeneration(),
          model: _modelController.text.trim(),
        );

    if (!mounted || generated == null) {
      return;
    }
    setState(() {
      _selectedResource = generated;
      _showWizard = false;
      _wizardStep = 0;
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(aiResourceStudioViewModelProvider);
    final settings = ref.watch(settingsViewModelProvider);
    if (!_didSyncKeyFromSettings) {
      _didSyncKeyFromSettings = true;
      if ((_modelController.text.trim().isEmpty ||
              _modelController.text.trim() == EnvConfig.openAiModel) &&
          settings.openAiModel.isNotEmpty) {
        _modelController.text = settings.openAiModel;
      }
    }
    final search = _searchController.text.trim().toUpperCase();
    final resources = state.resources.where((resource) {
      if (search.isEmpty) {
        return !_onlyFavorites || resource.isFavorite;
      }
      final matches =
          resource.title.toUpperCase().contains(search) ||
          resource.objective.toUpperCase().contains(search);
      if (!matches) {
        return false;
      }
      return !_onlyFavorites || resource.isFavorite;
    }).toList();
    AiResource? activeResource;
    if (_selectedResource != null) {
      for (final resource in resources) {
        if (resource.id == _selectedResource!.id) {
          activeResource = resource;
          break;
        }
      }
    }
    activeResource ??= resources.isEmpty ? null : resources.first;
    final imageMap = activeResource == null
        ? const <String, String>{}
        : _optionImageByWord(activeResource);

    return Scaffold(
      appBar: AppBar(
        title: const UpperText('CREA TU RECURSO IA'),
        actions: [
          IconButton(
            tooltip: 'WORKSPACE SESIONES',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => const SessionWorkspaceScreen(),
                ),
              );
            },
            icon: const Icon(Icons.view_kanban_rounded),
          ),
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1120),
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              if (_showWizard) ...[
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Color(0xFFFFEEF4), Color(0xFFEAF9F4)],
                    ),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: Theme.of(
                        context,
                      ).colorScheme.primary.withValues(alpha: 0.20),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const UpperText(
                        'ASISTENTE PASO A PASO',
                        style: TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 20,
                        ),
                      ),
                      const SizedBox(height: 6),
                      UpperText(
                        'PASO ${_wizardStep + 1} DE $_wizardTotalSteps',
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w900),
                      ),
                      const SizedBox(height: 8),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(999),
                        child: LinearProgressIndicator(
                          minHeight: 9,
                          value: (_wizardStep + 1) / _wizardTotalSteps,
                          backgroundColor: Theme.of(
                            context,
                          ).colorScheme.primary.withValues(alpha: 0.14),
                        ),
                      ),
                      const SizedBox(height: 10),
                      _buildWizardMilestones(context),
                      const SizedBox(height: 12),
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 220),
                        switchInCurve: Curves.easeOutCubic,
                        switchOutCurve: Curves.easeInCubic,
                        child: Container(
                          key: ValueKey(_wizardStep),
                          width: double.infinity,
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.72),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: Theme.of(
                                context,
                              ).colorScheme.primary.withValues(alpha: 0.20),
                            ),
                          ),
                          child: _wizardStep == 0
                              ? Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const UpperText(
                                      '1) CUÉNTAME EL CASO QUE QUIERES TRABAJAR',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w900,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    UpperText(
                                      'INSTRUCCIÓN (${_instructionController.text.length}/$_maxPromptLength)',
                                      style: Theme.of(
                                        context,
                                      ).textTheme.titleLarge,
                                    ),
                                    const SizedBox(height: 8),
                                    TextField(
                                      controller: _instructionController,
                                      maxLength: _maxPromptLength,
                                      minLines: 5,
                                      maxLines: 7,
                                      onChanged: (_) => setState(() {}),
                                      decoration: InputDecoration(
                                        hintText:
                                            'EJEMPLO: QUIERO TRABAJAR VOCAL E EN PRIMARIA, CON APOYO VISUAL Y PREGUNTAS CORTAS.',
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(
                                            16,
                                          ),
                                        ),
                                      ),
                                    ),
                                    UpperText(
                                      'ESCRIBE EL OBJETIVO COMO SI SE LO EXPLICARAS A OTRA PROFESIONAL.',
                                      style: Theme.of(
                                        context,
                                      ).textTheme.bodySmall,
                                    ),
                                  ],
                                )
                              : _wizardStep == 1
                              ? _buildStepTwoStudioDesign(context)
                              : Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const UpperText(
                                      '3) AJUSTES FINALES Y GENERACIÓN',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w900,
                                      ),
                                    ),
                                    const SizedBox(height: 10),
                                    UpperText(
                                      'RANGO DE EDAD',
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleMedium
                                          ?.copyWith(
                                            fontWeight: FontWeight.w900,
                                          ),
                                    ),
                                    const SizedBox(height: 6),
                                    Wrap(
                                      spacing: 8,
                                      runSpacing: 8,
                                      children: [
                                        ...[
                                          'AUTO',
                                          'INFANTIL (3-6)',
                                          'INFANTIL (7-12)',
                                          'ADOLESCENTES',
                                          'ADULTOS',
                                          'MAYORES',
                                        ].map((option) {
                                          return ChoiceChip(
                                            selected: _ageRange == option,
                                            label: UpperText(option),
                                            onSelected: (_) => setState(
                                              () => _ageRange = option,
                                            ),
                                          );
                                        }),
                                      ],
                                    ),
                                    const SizedBox(height: 10),
                                    UpperText(
                                      'DURACIÓN',
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleMedium
                                          ?.copyWith(
                                            fontWeight: FontWeight.w900,
                                          ),
                                    ),
                                    const SizedBox(height: 6),
                                    Wrap(
                                      spacing: 8,
                                      runSpacing: 8,
                                      children: [
                                        ...[
                                          'AUTO',
                                          '1-3 MIN',
                                          '5-10 MIN',
                                          '10-15 MIN',
                                          '15-20 MIN',
                                        ].map((option) {
                                          return ChoiceChip(
                                            selected: _duration == option,
                                            label: UpperText(option),
                                            onSelected: (_) => setState(
                                              () => _duration = option,
                                            ),
                                          );
                                        }),
                                      ],
                                    ),
                                    const SizedBox(height: 10),
                                    if (!kIsWeb) ...[
                                      TextField(
                                        controller: _apiKeyController,
                                        obscureText: true,
                                        onChanged: (value) {
                                          ref
                                              .read(
                                                settingsViewModelProvider
                                                    .notifier,
                                              )
                                              .setOpenAiApiKey(value);
                                        },
                                        decoration: InputDecoration(
                                          labelText:
                                              'OPENAI API KEY (SE GUARDA SOLO EN ESTE DISPOSITIVO)',
                                          border: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(
                                              14,
                                            ),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                    ],
                                    TextField(
                                      controller: _modelController,
                                      onChanged: (value) {
                                        ref
                                            .read(
                                              settingsViewModelProvider
                                                  .notifier,
                                            )
                                            .setOpenAiModel(value);
                                      },
                                      decoration: InputDecoration(
                                        labelText: 'MODELO OPENAI',
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(
                                            14,
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      kIsWeb
                                          ? 'En web la API key se usa solo en servidor.'
                                          : settings.openAiApiKey.isNotEmpty
                                          ? 'Usando API key guardada en ajustes locales.'
                                          : 'Introduce tu API key para usar funciones IA en este dispositivo.',
                                      style: Theme.of(
                                        context,
                                      ).textTheme.bodySmall,
                                    ),
                                    const SizedBox(height: 10),
                                    Container(
                                      width: double.infinity,
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(12),
                                        color: Theme.of(context)
                                            .colorScheme
                                            .primary
                                            .withValues(alpha: 0.10),
                                        border: Border.all(
                                          color: Theme.of(context)
                                              .colorScheme
                                              .primary
                                              .withValues(alpha: 0.25),
                                        ),
                                      ),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          const UpperText(
                                            'RESUMEN',
                                            style: TextStyle(
                                              fontWeight: FontWeight.w900,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          UpperText(
                                            'JUEGO: ${_studioGameLabel(_requestedGameType)}',
                                          ),
                                          UpperText('MODO: $_mode'),
                                          UpperText(
                                            'CATEGORÍA: ${_category.label}',
                                          ),
                                          UpperText('EDAD: $_ageRange'),
                                          UpperText('DURACIÓN: $_duration'),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 220),
                            child: OutlinedButton.icon(
                              style: OutlinedButton.styleFrom(
                                minimumSize: const Size(0, 50),
                              ),
                              onPressed: _wizardStep == 0
                                  ? null
                                  : _goToPreviousStep,
                              icon: const Icon(Icons.arrow_back_rounded),
                              label: const UpperText('ANTERIOR'),
                            ),
                          ),
                          const Spacer(),
                          ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 260),
                            child: _wizardStep < _wizardTotalSteps - 1
                                ? FilledButton.icon(
                                    onPressed: _goToNextStep,
                                    style: FilledButton.styleFrom(
                                      minimumSize: const Size(0, 50),
                                      backgroundColor: const Color(0xFF0D8A7C),
                                      foregroundColor: Colors.white,
                                      disabledBackgroundColor: const Color(
                                        0xFF7FB8B0,
                                      ),
                                      disabledForegroundColor: Colors.white,
                                    ),
                                    icon: const Icon(
                                      Icons.arrow_forward_rounded,
                                    ),
                                    label: const UpperText('SIGUIENTE'),
                                  )
                                : FilledButton.icon(
                                    onPressed: state.isGenerating
                                        ? null
                                        : _generateResource,
                                    style: FilledButton.styleFrom(
                                      minimumSize: const Size(0, 50),
                                    ),
                                    icon: state.isGenerating
                                        ? const SizedBox(
                                            width: 18,
                                            height: 18,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                            ),
                                          )
                                        : const Icon(
                                            Icons.auto_awesome_rounded,
                                          ),
                                    label: UpperText(
                                      state.isGenerating
                                          ? 'GENERANDO...'
                                          : 'CREAR RECURSO',
                                    ),
                                  ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                if (state.errorMessage != null) ...[
                  const SizedBox(height: 10),
                  Card(
                    color: Colors.red.shade50,
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Text(
                        state.errorMessage!,
                        style: TextStyle(color: Colors.red.shade800),
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 10),
                Align(
                  alignment: Alignment.centerLeft,
                  child: OutlinedButton.icon(
                    onPressed: () {
                      setState(() {
                        _showWizard = false;
                        _wizardStep = 0;
                      });
                    },
                    icon: const Icon(Icons.folder_open_rounded),
                    label: const UpperText('VER RECURSOS GUARDADOS'),
                  ),
                ),
              ] else ...[
                Align(
                  alignment: Alignment.centerLeft,
                  child: FilledButton.icon(
                    onPressed: () {
                      setState(() {
                        _showWizard = true;
                        _wizardStep = 0;
                      });
                    },
                    icon: const Icon(Icons.auto_awesome_rounded),
                    label: const UpperText('CREAR RECURSO POR PASOS'),
                  ),
                ),
                const SizedBox(height: 12),
                if (activeResource != null) ...[
                  const SizedBox(height: 12),
                  _GeneratedResourceCard(
                    resource: activeResource,
                    optionImageByWord: imageMap,
                    onToggleFavorite: () async {
                      await ref
                          .read(aiResourceStudioViewModelProvider.notifier)
                          .toggleFavorite(activeResource!.id);
                      if (!mounted) {
                        return;
                      }
                      setState(() {
                        _selectedResource = activeResource;
                      });
                    },
                  ),
                ],
                const SizedBox(height: 12),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        UpperText(
                          'MIS RECURSOS GUARDADOS (${resources.length})',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          children: [
                            ChoiceChip(
                              selected: !_onlyFavorites,
                              label: const UpperText('TODOS'),
                              onSelected: (_) {
                                setState(() => _onlyFavorites = false);
                              },
                            ),
                            ChoiceChip(
                              selected: _onlyFavorites,
                              label: const UpperText('SOLO FAVORITOS'),
                              onSelected: (_) {
                                setState(() => _onlyFavorites = true);
                              },
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        TextField(
                          controller: _searchController,
                          onChanged: (_) => setState(() {}),
                          decoration: InputDecoration(
                            hintText: 'BUSCAR RECURSOS...',
                            prefixIcon: const Icon(Icons.search),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        if (resources.isEmpty)
                          const Text('No hay recursos guardados todavía.')
                        else
                          ...resources.map((resource) {
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.outline,
                                  ),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      resource.title,
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleLarge
                                          ?.copyWith(
                                            fontWeight: FontWeight.w900,
                                          ),
                                    ),
                                    const SizedBox(height: 6),
                                    Text(resource.objective),
                                    const SizedBox(height: 6),
                                    Text(
                                      '${resource.ageRange} · ${resource.duration} · ${resource.mode}',
                                      style: Theme.of(
                                        context,
                                      ).textTheme.bodySmall,
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      _resourceRequestedGameLabel(resource),
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodySmall
                                          ?.copyWith(
                                            fontWeight: FontWeight.w800,
                                          ),
                                    ),
                                    const SizedBox(height: 8),
                                    Row(
                                      children: [
                                        IconButton(
                                          tooltip: 'FAVORITO',
                                          onPressed: () async {
                                            await ref
                                                .read(
                                                  aiResourceStudioViewModelProvider
                                                      .notifier,
                                                )
                                                .toggleFavorite(resource.id);
                                          },
                                          icon: Icon(
                                            resource.isFavorite
                                                ? Icons.star_rounded
                                                : Icons.star_outline_rounded,
                                            color: resource.isFavorite
                                                ? Colors.amber.shade700
                                                : null,
                                          ),
                                        ),
                                        OutlinedButton(
                                          onPressed: () {
                                            setState(() {
                                              _selectedResource = resource;
                                            });
                                          },
                                          child: const UpperText('ABRIR'),
                                        ),
                                        const SizedBox(width: 8),
                                        OutlinedButton(
                                          onPressed: () async {
                                            await ref
                                                .read(
                                                  aiResourceStudioViewModelProvider
                                                      .notifier,
                                                )
                                                .delete(resource.id);
                                            if (!mounted) {
                                              return;
                                            }
                                            if (_selectedResource?.id ==
                                                resource.id) {
                                              setState(() {
                                                _selectedResource = null;
                                              });
                                            }
                                          },
                                          child: const UpperText('ELIMINAR'),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }),
                      ],
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _GeneratedResourceCard extends StatelessWidget {
  const _GeneratedResourceCard({
    required this.resource,
    required this.optionImageByWord,
    required this.onToggleFavorite,
  });

  final AiResource resource;
  final Map<String, String> optionImageByWord;
  final VoidCallback onToggleFavorite;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    resource.title,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                IconButton(
                  tooltip: 'FAVORITO',
                  onPressed: onToggleFavorite,
                  icon: Icon(
                    resource.isFavorite
                        ? Icons.star_rounded
                        : Icons.star_outline_rounded,
                    color: resource.isFavorite ? Colors.amber.shade700 : null,
                  ),
                ),
              ],
            ),
            Text(
              '${resource.ageRange} · ${resource.duration} · ${resource.mode}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 4),
            Text(
              _resourceRequestedGameLabel(resource),
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 10),
            _PlayableResourcePanel(
              resource: resource,
              optionImageByWord: optionImageByWord,
            ),
            const SizedBox(height: 10),
            ExpansionTile(
              title: const Text(
                'SITUACIÓN DE APRENDIZAJE',
                style: TextStyle(fontWeight: FontWeight.w900),
              ),
              childrenPadding: const EdgeInsets.only(bottom: 8),
              children: [
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    resource.objective,
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                ),
                const SizedBox(height: 10),
                _ListSection(
                  title: 'Pasos de la actividad',
                  items: resource.activitySteps,
                ),
                _ListSection(
                  title: 'Preguntas sugeridas',
                  items: resource.questions,
                ),
                _ListSection(title: 'Mini-juegos', items: resource.miniGames),
                _ListSection(title: 'Materiales', items: resource.materials),
                _ListSection(
                  title: 'Adaptaciones',
                  items: resource.adaptations,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _PlayableResourcePanel extends StatefulWidget {
  const _PlayableResourcePanel({
    required this.resource,
    required this.optionImageByWord,
  });

  final AiResource resource;
  final Map<String, String> optionImageByWord;

  @override
  State<_PlayableResourcePanel> createState() => _PlayableResourcePanelState();
}

enum _PlayableMode { selectImage, selectWord, trueFalse }

class _PlayableResourcePanelState extends State<_PlayableResourcePanel> {
  final Random _random = Random();

  int _index = 0;
  int? _selectedOption;
  bool? _selectedTrueFalse;
  int _trueFalseCandidateIndex = 0;
  int _correct = 0;
  bool _answered = false;
  _PlayableMode _playMode = _PlayableMode.selectImage;
  int _gameIndex = 0;

  AiQuizQuestion get _current => widget.resource.playableQuestions[_index];
  bool get _isTrueStatement =>
      _trueFalseCandidateIndex == _current.correctIndex;

  @override
  void initState() {
    super.initState();
    _prepareTrueFalseCandidate();
  }

  @override
  void didUpdateWidget(covariant _PlayableResourcePanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.resource.id != widget.resource.id) {
      _resetSession();
    }
  }

  void _resetSession() {
    setState(() {
      _index = 0;
      _selectedOption = null;
      _selectedTrueFalse = null;
      _correct = 0;
      _answered = false;
      _playMode = _PlayableMode.selectImage;
      _gameIndex = 0;
      _prepareTrueFalseCandidate();
    });
  }

  List<String> get _gameLabels {
    final fromResource = widget.resource.miniGames
        .map((item) => item.trim())
        .where((item) => item.isNotEmpty)
        .toList();
    if (fromResource.isNotEmpty) {
      return fromResource.take(5).toList();
    }
    return const [
      'SELECCIONAR IMAGEN',
      'SELECCIONAR PALABRA',
      'VERDADERO/FALSO',
    ];
  }

  _PlayableMode _modeForGameIndex(int index) {
    final slot = index % 3;
    if (slot == 0) return _PlayableMode.selectImage;
    if (slot == 1) return _PlayableMode.selectWord;
    return _PlayableMode.trueFalse;
  }

  void _prepareTrueFalseCandidate() {
    if (_current.options.isEmpty) {
      _trueFalseCandidateIndex = 0;
      return;
    }
    _trueFalseCandidateIndex = _random.nextInt(_current.options.length);
  }

  void _setGameIndex(int index) {
    final mode = _modeForGameIndex(index);
    setState(() {
      _gameIndex = index;
      _playMode = mode;
      _index = 0;
      _selectedOption = null;
      _selectedTrueFalse = null;
      _answered = false;
      _correct = 0;
      _prepareTrueFalseCandidate();
    });
  }

  void _select(int option) {
    if (_answered) {
      return;
    }
    final ok = option == _current.correctIndex;
    setState(() {
      _selectedOption = option;
      _answered = true;
      if (ok) {
        _correct++;
      }
    });
  }

  void _selectTrueFalse(bool value) {
    if (_answered) {
      return;
    }
    final ok = value == _isTrueStatement;
    setState(() {
      _selectedTrueFalse = value;
      _answered = true;
      if (ok) {
        _correct++;
      }
    });
  }

  void _next() {
    if (_index + 1 >= widget.resource.playableQuestions.length) {
      setState(() {
        _index = 0;
        _selectedOption = null;
        _answered = false;
        _correct = 0;
      });
      return;
    }
    setState(() {
      _index++;
      _selectedOption = null;
      _selectedTrueFalse = null;
      _answered = false;
      _prepareTrueFalseCandidate();
    });
  }

  @override
  Widget build(BuildContext context) {
    if (widget.resource.playableQuestions.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.amber.shade50,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.amber.shade300),
        ),
        child: const Text(
          'Este recurso no incluye preguntas jugables todavía. Genera de nuevo para obtener actividad interactiva.',
        ),
      );
    }

    final width = MediaQuery.sizeOf(context).width;
    final wide = width >= 900;
    final readingTitle = widget.resource.investigationTitle.trim().isEmpty
        ? widget.resource.title
        : widget.resource.investigationTitle;
    final readingText = widget.resource.investigationText.trim().isEmpty
        ? widget.resource.objective
        : widget.resource.investigationText;
    final completed =
        _answered && _index + 1 == widget.resource.playableQuestions.length;
    final trueFalsePrompt =
        'Según la consigna: "${_current.prompt}"\n¿La opción mostrada es una respuesta correcta?';
    final isAnsweredCorrect = _playMode == _PlayableMode.trueFalse
        ? _selectedTrueFalse == _isTrueStatement
        : _selectedOption == _current.correctIndex;
    final optionCards = List<Widget>.generate(_current.options.length, (i) {
      final option = _current.options[i];
      final selected = _selectedOption == i;
      final correct = _answered && i == _current.correctIndex;
      final wrongSelected = _answered && selected && i != _current.correctIndex;
      final border = correct
          ? Colors.green.shade700
          : wrongSelected
          ? Colors.red.shade700
          : Theme.of(context).colorScheme.outline;
      final bg = correct
          ? Colors.green.shade50
          : wrongSelected
          ? Colors.red.shade50
          : Theme.of(context).colorScheme.surface;

      final normalized = normalizeWordForLetters(option);
      final imageAsset = widget.optionImageByWord[normalized];

      return InkWell(
        onTap: _answered ? null : () => _select(i),
        borderRadius: BorderRadius.circular(14),
        child: Ink(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: border,
              width: correct || wrongSelected ? 2.5 : 1.3,
            ),
          ),
          child: Column(
            children: [
              Expanded(
                child: imageAsset != null
                    ? ActivityAssetImage(
                        assetPath: imageAsset,
                        semanticsLabel: option,
                      )
                    : _WordFallbackVisual(word: option),
              ),
              const SizedBox(height: 6),
              Text(
                option,
                textAlign: TextAlign.center,
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
              ),
            ],
          ),
        ),
      );
    });

    String answerFeedback() {
      if (_playMode == _PlayableMode.trueFalse) {
        final correctWord = _current.options[_current.correctIndex];
        final shownWord = _current.options[_trueFalseCandidateIndex];
        final outcome = _selectedTrueFalse == _isTrueStatement
            ? 'RESPUESTA CORRECTA'
            : 'RESPUESTA INCORRECTA';
        return '$outcome. OPCIÓN MOSTRADA: $shownWord. RESPUESTA CORRECTA: $correctWord.';
      }
      return _current.feedback;
    }

    final questionPane = Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF2FFF8),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFBFE8D8)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFE4F0FF),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  'PREGUNTA ${_index + 1}/${widget.resource.playableQuestions.length}',
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFEAFBEA),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  'ACIERTOS: $_correct',
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: List<Widget>.generate(_gameLabels.length, (i) {
              return ChoiceChip(
                selected: _gameIndex == i,
                label: Text('JUEGO ${i + 1}: ${_gameLabels[i]}'),
                onSelected: (_) => _setGameIndex(i),
              );
            }),
          ),
          const SizedBox(height: 10),
          Text(
            _playMode == _PlayableMode.trueFalse
                ? trueFalsePrompt
                : _current.prompt,
            style: Theme.of(
              context,
            ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 10),
          if (_playMode == _PlayableMode.selectImage)
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: wide ? 3 : 2,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
                mainAxisExtent: wide ? 290 : 245,
              ),
              itemCount: optionCards.length,
              itemBuilder: (context, index) => optionCards[index],
            )
          else if (_playMode == _PlayableMode.selectWord)
            Column(
              children: List<Widget>.generate(_current.options.length, (i) {
                final selected = _selectedOption == i;
                final correct = _answered && i == _current.correctIndex;
                final wrongSelected =
                    _answered && selected && i != _current.correctIndex;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: _answered ? null : () => _select(i),
                      style: FilledButton.styleFrom(
                        backgroundColor: correct
                            ? Colors.green.shade700
                            : wrongSelected
                            ? Colors.red.shade700
                            : null,
                        padding: const EdgeInsets.symmetric(vertical: 20),
                      ),
                      child: Text(
                        _current.options[i],
                        style: Theme.of(context).textTheme.headlineSmall
                            ?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w900,
                            ),
                      ),
                    ),
                  ),
                );
              }),
            )
          else ...[
            Builder(
              builder: (context) {
                final shownWord = _current.options[_trueFalseCandidateIndex];
                final shownAsset = widget
                    .optionImageByWord[normalizeWordForLetters(shownWord)];

                return Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: Theme.of(context).colorScheme.outline,
                    ),
                  ),
                  child: Column(
                    children: [
                      SizedBox(
                        height: wide ? 260 : 210,
                        child: shownAsset != null
                            ? ActivityAssetImage(
                                assetPath: shownAsset,
                                semanticsLabel: shownWord,
                              )
                            : _WordFallbackVisual(word: shownWord),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        shownWord,
                        style: Theme.of(context).textTheme.headlineSmall
                            ?.copyWith(fontWeight: FontWeight.w900),
                      ),
                    ],
                  ),
                );
              },
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: FilledButton(
                    onPressed: _answered ? null : () => _selectTrueFalse(true),
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 18),
                    ),
                    child: const UpperText('VERDADERO'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: FilledButton(
                    onPressed: _answered ? null : () => _selectTrueFalse(false),
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 18),
                      backgroundColor: Colors.deepOrange.shade600,
                    ),
                    child: const UpperText('FALSO'),
                  ),
                ),
              ],
            ),
          ],
          if (_answered) ...[
            const SizedBox(height: 6),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: isAnsweredCorrect
                    ? Colors.green.shade50
                    : Colors.red.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isAnsweredCorrect
                      ? Colors.green.shade600
                      : Colors.red.shade600,
                ),
              ),
              child: Text(answerFeedback()),
            ),
            const SizedBox(height: 10),
            FilledButton.icon(
              onPressed: _next,
              icon: Icon(
                completed ? Icons.replay_rounded : Icons.navigate_next_rounded,
              ),
              label: UpperText(
                completed ? 'VOLVER A EMPEZAR' : 'SIGUIENTE PREGUNTA',
              ),
            ),
          ],
        ],
      ),
    );

    final readingPane = Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FFFC),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFCAE7DC)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'FICHA DE INVESTIGACIÓN',
            style: TextStyle(
              color: Color(0xFF2E9D6C),
              fontWeight: FontWeight.w900,
              letterSpacing: 0.6,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            readingTitle,
            style: Theme.of(
              context,
            ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 10),
          Text(
            readingText,
            style: Theme.of(
              context,
            ).textTheme.bodyLarge?.copyWith(height: 1.45),
          ),
        ],
      ),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'JUEGO INTERACTIVO',
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: 10),
        questionPane,
        const SizedBox(height: 12),
        Text(
          'APOYO DE LECTURA',
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: 8),
        readingPane,
      ],
    );
  }
}

class _WordFallbackVisual extends StatelessWidget {
  const _WordFallbackVisual({required this.word});

  final String word;

  static const _emojiByWord = {
    'PERRO': '🐶',
    'GATO': '🐱',
    'CABALLO': '🐴',
    'VACA': '🐮',
    'LEÓN': '🦁',
    'LEON': '🦁',
    'OSO': '🐻',
    'PÁJARO': '🐦',
    'PAJARO': '🐦',
    'PEZ': '🐟',
    'CONEJO': '🐰',
  };

  @override
  Widget build(BuildContext context) {
    final normalized = normalizeWordForLetters(word).toUpperCase();
    final emoji = _emojiByWord[normalized];
    return Container(
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Theme.of(context).colorScheme.outline),
      ),
      child: emoji != null
          ? Text(emoji, style: const TextStyle(fontSize: 92))
          : const Icon(Icons.image_not_supported_rounded, size: 62),
    );
  }
}

class _ListSection extends StatelessWidget {
  const _ListSection({required this.title, required this.items});

  final String title;
  final List<String> items;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return const SizedBox.shrink();
    }
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 6),
          ...items.map((item) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Text('• $item'),
            );
          }),
        ],
      ),
    );
  }
}
