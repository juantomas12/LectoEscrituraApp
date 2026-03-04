import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../application/providers/app_providers.dart';
import '../../../core/utils/pedagogical_feedback.dart';
import '../../../core/utils/text_utils.dart';
import '../../../domain/models/activity_result.dart';
import '../../../domain/models/activity_type.dart';
import '../../../domain/models/category.dart';
import '../../../domain/models/difficulty.dart';
import '../../../domain/models/item.dart';
import '../../../domain/models/letter_match_mode.dart';
import '../../../domain/models/level.dart';
import '../../viewmodels/progress_view_model.dart';
import '../../viewmodels/settings_view_model.dart';
import '../../widgets/activity_asset_image.dart';
import '../../widgets/game_style.dart';
import '../../widgets/routine_steps.dart';
import '../../widgets/upper_text.dart';
import '../results_screen.dart';

class LetterTargetScreen extends ConsumerStatefulWidget {
  const LetterTargetScreen({
    super.key,
    required this.category,
    required this.difficulty,
    required this.level,
    this.targetLetter,
    this.matchMode = LetterMatchMode.contiene,
    this.customTitle,
  });

  final AppCategory category;
  final Difficulty difficulty;
  final AppLevel level;
  final String? targetLetter;
  final LetterMatchMode matchMode;
  final String? customTitle;

  @override
  ConsumerState<LetterTargetScreen> createState() => _LetterTargetScreenState();
}

class _LetterTargetScreenState extends ConsumerState<LetterTargetScreen> {
  final Random _random = Random();

  List<Item> _items = [];
  final Map<String, bool> _classifiedByItem = {};
  String _targetLetter = 'A';
  String _feedback = 'ARRASTRA A LA CAJA CORRECTA';
  bool _isLoading = true;

  int _correct = 0;
  int _incorrect = 0;
  int _streak = 0;
  int _bestStreak = 0;
  int _consecutiveErrors = 0;
  DateTime _startedAt = DateTime.now();

  bool _matchesWord(String word, String letter) {
    return switch (widget.matchMode) {
      LetterMatchMode.contiene => containsLetter(word, letter),
      LetterMatchMode.inicia => startsWithLetter(word, letter),
      LetterMatchMode.medio => containsLetterInMiddle(word, letter),
      LetterMatchMode.termina => endsWithLetter(word, letter),
    };
  }

  String _hintForMode() {
    return switch (widget.matchMode) {
      LetterMatchMode.contiene => 'PIENSA SI SUENA LA LETRA $_targetLetter',
      LetterMatchMode.inicia => 'PIENSA SI EMPIEZA CON $_targetLetter',
      LetterMatchMode.medio => 'PIENSA SI $_targetLetter SUENA EN MEDIO',
      LetterMatchMode.termina => 'PIENSA SI TERMINA EN $_targetLetter',
    };
  }

  @override
  void initState() {
    super.initState();
    _prepareActivity();
  }

  Future<void> _prepareActivity() async {
    final dataset = ref.read(datasetRepositoryProvider);
    final progressMap = ref.read(itemProgressMapProvider);

    final baseItems = dataset.getPrioritizedItems(
      category: widget.category,
      level: AppLevel.uno,
      activityType: ActivityType.imagenPalabra,
      difficulty: widget.difficulty,
      progressMap: progressMap,
      limit: 28,
    );

    final fallbackItems = dataset.getItems(
      category: widget.category,
      level: AppLevel.uno,
      activityType: ActivityType.imagenPalabra,
    );

    final source = baseItems.isNotEmpty ? baseItems : fallbackItems;

    final filteredBySyllables = source.where((item) {
      final word = item.word ?? '';
      final syllables = estimateSpanishSyllables(word);
      if (widget.level == AppLevel.uno) {
        return syllables <= 2;
      }
      if (widget.level == AppLevel.dos) {
        return syllables >= 2 && syllables <= 3;
      }
      return syllables >= 3;
    }).toList();

    final candidatesPool = filteredBySyllables.length >= 6
        ? filteredBySyllables
        : source;

    final targetSize = widget.difficulty == Difficulty.primaria ? 4 : 6;
    final half = (targetSize / 2).ceil();

    final candidateLetters = switch (widget.level) {
      AppLevel.uno => ['A', 'E', 'I', 'O', 'U'],
      AppLevel.dos => ['A', 'E', 'I', 'O', 'U', 'L', 'M', 'N', 'P', 'R', 'S'],
      _ => [
        'A',
        'E',
        'I',
        'O',
        'U',
        'L',
        'M',
        'N',
        'P',
        'R',
        'S',
        'T',
        'C',
        'D',
        'B',
      ],
    };

    final selectedCandidates = widget.targetLetter != null
        ? [widget.targetLetter!.toUpperCase()]
        : candidateLetters;

    String selectedLetter = selectedCandidates.first;
    List<Item> positives = [];
    List<Item> negatives = [];

    for (final letter in selectedCandidates) {
      final withLetter = candidatesPool
          .where((item) => _matchesWord(item.word ?? '', letter))
          .toList();
      final withoutLetter = candidatesPool
          .where((item) => !_matchesWord(item.word ?? '', letter))
          .toList();

      if (withLetter.length >= half && withoutLetter.length >= half) {
        selectedLetter = letter;
        positives = withLetter;
        negatives = withoutLetter;
        break;
      }
    }

    if (positives.isEmpty || negatives.isEmpty) {
      selectedLetter = selectedCandidates.first;
      positives = candidatesPool
          .where((item) => _matchesWord(item.word ?? '', selectedLetter))
          .toList();
      negatives = candidatesPool
          .where((item) => !_matchesWord(item.word ?? '', selectedLetter))
          .toList();
    }

    positives.shuffle(_random);
    negatives.shuffle(_random);

    final selectedItems = <Item>[
      ...positives.take(half),
      ...negatives.take(targetSize - half),
    ]..shuffle(_random);

    if (!mounted) {
      return;
    }

    setState(() {
      _items = selectedItems;
      _targetLetter = selectedLetter;
      _classifiedByItem.clear();
      _feedback = 'ARRASTRA A LA CAJA CORRECTA';
      _correct = 0;
      _incorrect = 0;
      _streak = 0;
      _bestStreak = 0;
      _consecutiveErrors = 0;
      _startedAt = DateTime.now();
      _isLoading = false;
    });
  }

  Future<void> _handleDrop(Item item, {required bool toHasLetter}) async {
    if (_classifiedByItem.containsKey(item.id)) {
      return;
    }

    final actualHasLetter = containsLetter(item.word ?? '', _targetLetter);
    final isCorrect = actualHasLetter == toHasLetter;

    await ref
        .read(progressViewModelProvider.notifier)
        .registerAttempt(
          itemId: item.id,
          correct: isCorrect,
          activityType: ActivityType.letraObjetivo,
        );

    if (!mounted) {
      return;
    }

    setState(() {
      if (isCorrect) {
        _classifiedByItem[item.id] = toHasLetter;
        _correct++;
        _streak++;
        _consecutiveErrors = 0;
        _bestStreak = max(_bestStreak, _streak);
        _feedback = PedagogicalFeedback.positive(
          streak: _streak,
          totalCorrect: _correct,
        );
      } else {
        _incorrect++;
        _streak = 0;
        _feedback = PedagogicalFeedback.retry(
          attemptsOnCurrent: _incorrect,
          hint: _hintForMode(),
        );
        _consecutiveErrors++;
      }
    });

    if (_classifiedByItem.length == _items.length && _items.isNotEmpty) {
      await _finishActivity();
    }
  }

  Future<void> _finishActivity() async {
    final result = ActivityResult(
      id: 'RES-${DateTime.now().millisecondsSinceEpoch}',
      category: widget.category,
      level: widget.level,
      activityType: ActivityType.letraObjetivo,
      correct: _correct,
      incorrect: _incorrect,
      durationInSeconds: DateTime.now().difference(_startedAt).inSeconds,
      bestStreak: _bestStreak,
      createdAt: DateTime.now(),
    );

    await ref.read(progressViewModelProvider.notifier).saveResult(result);

    if (!mounted) {
      return;
    }

    final action = await Navigator.of(context).push<ResultAction>(
      MaterialPageRoute(builder: (_) => ResultsScreen(result: result)),
    );

    if (!mounted) {
      return;
    }

    if (action == ResultAction.repetir) {
      setState(() => _isLoading = true);
      await _prepareActivity();
    } else {
      Navigator.of(context).pop();
    }
  }

  String _instructionQuestion() {
    return switch (widget.matchMode) {
      LetterMatchMode.contiene =>
        '¿QUÉ OBJETOS TIENEN EL SONIDO DE LA LETRA $_targetLetter?',
      LetterMatchMode.inicia => '¿QUÉ OBJETOS EMPIEZAN POR $_targetLetter?',
      LetterMatchMode.medio => '¿QUÉ OBJETOS TIENEN $_targetLetter EN MEDIO?',
      LetterMatchMode.termina => '¿QUÉ OBJETOS TERMINAN EN $_targetLetter?',
    };
  }

  Future<void> _speakText(String text) async {
    final settings = ref.read(settingsViewModelProvider);
    if (!settings.audioEnabled || text.trim().isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('ACTIVA EL AUDIO EN AYUDAS TÉCNICAS')),
        );
      }
      return;
    }
    await ref.read(ttsServiceProvider).speak(text);
  }

  Future<void> _speakInstruction() async {
    await _speakText('ARRASTRA A LA CAJA CORRECTA. ${_instructionQuestion()}');
  }

  Future<void> _speakWord(String word) async {
    await _speakText(word);
  }

  void _openTechnicalAidsSheet() {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) {
        return SafeArea(
          child: Consumer(
            builder: (context, ref, _) {
              final settings = ref.watch(settingsViewModelProvider);
              final vm = ref.read(settingsViewModelProvider.notifier);
              return Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 22),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const UpperText(
                      'AYUDAS TÉCNICAS',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 8),
                    SwitchListTile(
                      value: settings.showHints,
                      onChanged: (value) => vm.setShowHints(value),
                      title: const UpperText('MOSTRAR PISTAS'),
                    ),
                    SwitchListTile(
                      value: settings.audioEnabled,
                      onChanged: (value) => vm.setAudioEnabled(value),
                      title: const UpperText('AUDIO DE INSTRUCCIONES'),
                    ),
                    SwitchListTile(
                      value: settings.dyslexiaMode,
                      onChanged: (value) => vm.setDyslexiaMode(value),
                      title: const UpperText('MODO DISLEXIA'),
                    ),
                    SwitchListTile(
                      value: settings.highContrast,
                      onChanged: (value) => vm.setHighContrast(value),
                      title: const UpperText('ALTO CONTRASTE'),
                    ),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildDropZone({
    required BuildContext context,
    required bool toHasLetter,
    required List<Item> accepted,
  }) {
    return DragTarget<Item>(
      onWillAcceptWithDetails: (details) =>
          details.data.word != null &&
          !_classifiedByItem.containsKey(details.data.id),
      onAcceptWithDetails: (details) {
        _handleDrop(details.data, toHasLetter: toHasLetter);
      },
      builder: (context, candidateData, rejectedData) {
        final hovering = candidateData.isNotEmpty;
        final zoneColor = toHasLetter
            ? Colors.green.shade700
            : Colors.red.shade700;
        final zoneBgColor = toHasLetter
            ? Colors.green.shade50
            : Colors.red.shade50;
        final zoneIcon = toHasLetter
            ? Icons.check_circle_rounded
            : Icons.cancel_rounded;
        final zonePrefix = widget.matchMode.label;
        final zoneTitle = toHasLetter
            ? '$zonePrefix $_targetLetter'
            : 'NO $zonePrefix $_targetLetter';
        final zoneSubtitle = 'ARRASTRA AQUÍ';

        return AnimatedContainer(
          duration: const Duration(milliseconds: 130),
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: hovering
                ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.12)
                : Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: hovering
                  ? Theme.of(context).colorScheme.primary
                  : Theme.of(context).colorScheme.outline,
              width: 2,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: zoneBgColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(zoneIcon, color: zoneColor, size: 30),
                    const SizedBox(width: 8),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        UpperText(
                          zoneTitle,
                          style: Theme.of(context).textTheme.titleLarge
                              ?.copyWith(
                                color: zoneColor,
                                fontWeight: FontWeight.w800,
                              ),
                        ),
                        UpperText(
                          zoneSubtitle,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 6),
              UpperText('ACERTADAS: ${accepted.length}'),
              const SizedBox(height: 8),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: accepted
                    .map((item) => Chip(label: UpperText(item.word ?? '')))
                    .toList(),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDesktopDropZone({
    required BuildContext context,
    required bool toHasLetter,
    required List<Item> accepted,
  }) {
    return DragTarget<Item>(
      onWillAcceptWithDetails: (details) =>
          details.data.word != null &&
          !_classifiedByItem.containsKey(details.data.id),
      onAcceptWithDetails: (details) {
        _handleDrop(details.data, toHasLetter: toHasLetter);
      },
      builder: (context, candidateData, rejectedData) {
        final hovering = candidateData.isNotEmpty;
        final zoneColor = toHasLetter
            ? const Color(0xFF40C87C)
            : const Color(0xFFF47777);
        final zoneBgColor = toHasLetter
            ? const Color(0xFFE8F8EE)
            : const Color(0xFFFFF0F0);
        final icon = toHasLetter ? Icons.check_rounded : Icons.close_rounded;
        final zonePrefix = widget.matchMode.label;
        final zoneTitle = toHasLetter
            ? '$zonePrefix $_targetLetter'
            : 'NO $zonePrefix $_targetLetter';

        return AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          height: 190,
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: zoneBgColor,
            borderRadius: BorderRadius.circular(36),
            border: Border.all(
              color: hovering ? kGameAccent : zoneColor.withValues(alpha: 0.45),
              width: hovering ? 3 : 2.2,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircleAvatar(
                radius: 28,
                backgroundColor: zoneColor,
                foregroundColor: Colors.white,
                child: Icon(icon, size: 34),
              ),
              const SizedBox(height: 16),
              UpperText(
                zoneTitle,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 50,
                  fontWeight: FontWeight.w900,
                  color: zoneColor,
                  letterSpacing: 1.1,
                ),
              ),
              const SizedBox(height: 6),
              UpperText(
                'ACERTADAS: ${accepted.length}',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF1D2A49),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDesktopLayout({
    required BuildContext context,
    required List<Item> remainingItems,
    required List<Item> withLetter,
    required List<Item> withoutLetter,
    required int solvedCount,
    required bool showHints,
  }) {
    final progress = _items.isEmpty
        ? 0.0
        : (solvedCount / _items.length).clamp(0.0, 1.0);

    return Scaffold(
      backgroundColor: const Color(0xFFF1F3F7),
      body: SafeArea(
        child: Row(
          children: [
            Container(
              width: 330,
              decoration: const BoxDecoration(
                color: Color(0xFFF8FAFF),
                border: Border(right: BorderSide(color: Color(0xFFD7DFEC))),
              ),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 20, 24, 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 64,
                          height: 64,
                          decoration: BoxDecoration(
                            color: const Color(0xFFEAF1FF),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Icon(Icons.menu_book_rounded, size: 34),
                        ),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: UpperText(
                            'EDUMUNDO\nALFABETIZACIÓN',
                            style: TextStyle(
                              fontSize: 16,
                              height: 1.15,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(26),
                        color: const Color(0xFFEAF1FF),
                      ),
                      child: UpperText(
                        'LECCIÓN ACTUAL\n${widget.customTitle ?? 'LETRAS Y VOCALES'}',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                          height: 1.15,
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),
                    const _DesktopSidebarItem(
                      icon: Icons.menu_book_rounded,
                      label: 'APRENDER',
                      active: true,
                    ),
                    const SizedBox(height: 12),
                    const _DesktopSidebarItem(
                      icon: Icons.bar_chart_rounded,
                      label: 'MI PROGRESO',
                    ),
                    const SizedBox(height: 12),
                    const _DesktopSidebarItem(
                      icon: Icons.settings_rounded,
                      label: 'AJUSTES',
                    ),
                    const Spacer(),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(28),
                        color: const Color(0xFFEFF4FF),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          UpperText(
                            'TU PROGRESO',
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(
                                  fontWeight: FontWeight.w800,
                                  color: const Color(0xFF5D6E8C),
                                ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Expanded(
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(999),
                                  child: LinearProgressIndicator(
                                    value: progress,
                                    minHeight: 12,
                                    backgroundColor: const Color(0xFFD7DEEA),
                                    color: kGameAccent,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              UpperText(
                                '$solvedCount/${_items.length}',
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    FilledButton(
                      onPressed: _openTechnicalAidsSheet,
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFF0E1A3D),
                        minimumSize: const Size.fromHeight(56),
                      ),
                      child: const UpperText('AYUDA TÉCNICA'),
                    ),
                  ],
                ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(38, 24, 38, 20),
                child: Column(
                  children: [
                    UpperText(
                      'ARRASTRA A LA CAJA CORRECTA',
                      style: Theme.of(context).textTheme.headlineLarge
                          ?.copyWith(
                            fontWeight: FontWeight.w900,
                            color: const Color(0xFF121C3D),
                          ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 6),
                    UpperText(
                      _instructionQuestion(),
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF4D638C),
                      ),
                      textAlign: TextAlign.center,
                    ),
                    if (showHints) ...[
                      const SizedBox(height: 8),
                      UpperText(
                        'PISTA: ${_hintForMode()}',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF4D638C),
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        Expanded(
                          child: _buildDesktopDropZone(
                            context: context,
                            toHasLetter: true,
                            accepted: withLetter,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _buildDesktopDropZone(
                            context: context,
                            toHasLetter: false,
                            accepted: withoutLetter,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    Expanded(
                      child: remainingItems.isEmpty
                          ? const Center(
                              child: UpperText(
                                'COMPLETADO. NO QUEDAN TARJETAS.',
                              ),
                            )
                          : GridView.builder(
                              gridDelegate:
                                  const SliverGridDelegateWithFixedCrossAxisCount(
                                    crossAxisCount: 4,
                                    crossAxisSpacing: 14,
                                    mainAxisSpacing: 14,
                                    mainAxisExtent: 312,
                                  ),
                              itemCount: remainingItems.length,
                              itemBuilder: (context, index) {
                                final item = remainingItems[index];
                                return Draggable<Item>(
                                  data: item,
                                  feedback: Material(
                                    color: Colors.transparent,
                                    child: SizedBox(
                                      width: 220,
                                      child: _DesktopLetterCard(
                                        item: item,
                                        onSpeak: () =>
                                            _speakWord(item.word ?? ''),
                                      ),
                                    ),
                                  ),
                                  childWhenDragging: Opacity(
                                    opacity: 0.3,
                                    child: _DesktopLetterCard(
                                      item: item,
                                      onSpeak: () =>
                                          _speakWord(item.word ?? ''),
                                    ),
                                  ),
                                  child: _DesktopLetterCard(
                                    item: item,
                                    onSpeak: () => _speakWord(item.word ?? ''),
                                  ),
                                );
                              },
                            ),
                    ),
                    Align(
                      alignment: Alignment.centerRight,
                      child: OutlinedButton.icon(
                        onPressed: _speakInstruction,
                        icon: const Icon(Icons.headset_rounded),
                        label: const UpperText('ESCUCHAR INSTRUCCIÓN'),
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size(340, 66),
                          side: const BorderSide(
                            color: kGameAccent,
                            width: 2.5,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(44),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(settingsViewModelProvider);
    final width = MediaQuery.sizeOf(context).width;
    final isLandscape =
        MediaQuery.orientationOf(context) == Orientation.landscape;
    final isDesktopLandscape = width >= 1200 && isLandscape;
    final isPhone = width < 700;
    final isTablet = width >= 700 && width < 1200;
    final isTabletLandscape = isTablet && isLandscape;
    final useVerticalDropZones = isPhone || (isTablet && !isLandscape);
    final cardsCrossAxisCount = 2;
    final cardsMainAxisExtent = isPhone ? 210.0 : 240.0;
    final dragFeedbackWidth = isPhone ? 190.0 : 220.0;

    final remainingItems = _items
        .where((item) => !_classifiedByItem.containsKey(item.id))
        .toList();
    final nextItem = remainingItems.isNotEmpty ? remainingItems.first : null;

    final withLetter = _items
        .where((item) => _classifiedByItem[item.id] == true)
        .toList();

    final withoutLetter = _items
        .where((item) => _classifiedByItem[item.id] == false)
        .toList();
    final solvedCount = withLetter.length + withoutLetter.length;

    if (isDesktopLandscape) {
      return _buildDesktopLayout(
        context: context,
        remainingItems: remainingItems,
        withLetter: withLetter,
        withoutLetter: withoutLetter,
        solvedCount: solvedCount,
        showHints: settings.showHints,
      );
    }

    return GameScaffold(
      title: widget.customTitle ?? 'LETRAS Y VOCALES',
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _items.isEmpty
          ? const Center(
              child: Padding(
                padding: EdgeInsets.all(20),
                child: UpperText('NO HAY PALABRAS SUFICIENTES PARA ESTE NIVEL'),
              ),
            )
          : Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1180),
                child: ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    GameProgressHeader(
                      label: 'TU PROGRESO',
                      current: solvedCount,
                      total: _items.length,
                      trailingLabel: '⭐ $_correct',
                    ),
                    const SizedBox(height: 10),
                    RoutineSteps(currentStep: nextItem == null ? 4 : 2),
                    const SizedBox(height: 10),
                    GamePanel(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          UpperText(
                            'SEPARA LAS TARJETAS',
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          const SizedBox(height: 8),
                          UpperText(
                            'LETRA: $_targetLetter',
                            style: Theme.of(context).textTheme.titleLarge
                                ?.copyWith(fontWeight: FontWeight.w800),
                          ),
                          const SizedBox(height: 6),
                          UpperText(_feedback),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: [
                        OutlinedButton.icon(
                          onPressed: _openTechnicalAidsSheet,
                          icon: const Icon(Icons.tune_rounded),
                          label: const UpperText('AYUDA TÉCNICA'),
                        ),
                        OutlinedButton.icon(
                          onPressed: _speakInstruction,
                          icon: const Icon(Icons.headset_rounded),
                          label: const UpperText('ESCUCHAR INSTRUCCIÓN'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    if (useVerticalDropZones)
                      Column(
                        children: [
                          _buildDropZone(
                            context: context,
                            toHasLetter: true,
                            accepted: withLetter,
                          ),
                          const SizedBox(height: 10),
                          _buildDropZone(
                            context: context,
                            toHasLetter: false,
                            accepted: withoutLetter,
                          ),
                        ],
                      )
                    else
                      Row(
                        children: [
                          Expanded(
                            child: _buildDropZone(
                              context: context,
                              toHasLetter: true,
                              accepted: withLetter,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _buildDropZone(
                              context: context,
                              toHasLetter: false,
                              accepted: withoutLetter,
                            ),
                          ),
                        ],
                      ),
                    if (_consecutiveErrors >= 2 && nextItem != null) ...[
                      const SizedBox(height: 10),
                      GamePanel(
                        backgroundColor: Colors.amber.shade50,
                        borderColor: Colors.amber.shade300,
                        child: Row(
                          children: [
                            Icon(
                              Icons.lightbulb_rounded,
                              color: Colors.amber.shade800,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: UpperText(
                                'AYUDA: ${nextItem.word} VA EN ${_matchesWord(nextItem.word ?? '', _targetLetter) ? _targetLetter : 'NO $_targetLetter'}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    const SizedBox(height: 14),
                    UpperText(
                      'TARJETAS',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 8),
                    if (isPhone || isTablet)
                      Column(
                        children: [
                          if (remainingItems.isEmpty)
                            const UpperText('NO QUEDAN TARJETAS')
                          else if (isTabletLandscape && nextItem != null)
                            Center(
                              child: Draggable<Item>(
                                data: nextItem,
                                feedback: Material(
                                  color: Colors.transparent,
                                  child: SizedBox(
                                    width: 220,
                                    child: _LetterCard(
                                      item: nextItem,
                                      tabletLarge: true,
                                      onSpeak: () =>
                                          _speakWord(nextItem.word ?? ''),
                                    ),
                                  ),
                                ),
                                childWhenDragging: Opacity(
                                  opacity: 0.3,
                                  child: _LetterCard(
                                    item: nextItem,
                                    tabletLarge: true,
                                    onSpeak: () =>
                                        _speakWord(nextItem.word ?? ''),
                                  ),
                                ),
                                child: _LetterCard(
                                  item: nextItem,
                                  tabletLarge: true,
                                  onSpeak: () =>
                                      _speakWord(nextItem.word ?? ''),
                                ),
                              ),
                            )
                          else
                            GridView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              gridDelegate:
                                  SliverGridDelegateWithFixedCrossAxisCount(
                                    crossAxisCount: cardsCrossAxisCount,
                                    crossAxisSpacing: 10,
                                    mainAxisSpacing: 10,
                                    mainAxisExtent: cardsMainAxisExtent,
                                  ),
                              itemCount: remainingItems.length,
                              itemBuilder: (context, index) {
                                final item = remainingItems[index];
                                return Draggable<Item>(
                                  data: item,
                                  feedback: Material(
                                    color: Colors.transparent,
                                    child: SizedBox(
                                      width: dragFeedbackWidth,
                                      child: _LetterCard(
                                        item: item,
                                        mobileLarge: isPhone,
                                        tabletLarge:
                                            isTablet && !isTabletLandscape,
                                        onSpeak: () =>
                                            _speakWord(item.word ?? ''),
                                      ),
                                    ),
                                  ),
                                  childWhenDragging: Opacity(
                                    opacity: 0.3,
                                    child: _LetterCard(
                                      item: item,
                                      mobileLarge: isPhone,
                                      tabletLarge:
                                          isTablet && !isTabletLandscape,
                                      onSpeak: () =>
                                          _speakWord(item.word ?? ''),
                                    ),
                                  ),
                                  child: _LetterCard(
                                    item: item,
                                    mobileLarge: isPhone,
                                    tabletLarge: isTablet && !isTabletLandscape,
                                    onSpeak: () => _speakWord(item.word ?? ''),
                                  ),
                                );
                              },
                            ),
                          const SizedBox(height: 8),
                          UpperText(
                            'QUEDAN: ${remainingItems.length}',
                            style: Theme.of(context).textTheme.bodyLarge,
                          ),
                        ],
                      )
                    else
                      Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        children: remainingItems.map((item) {
                          return Draggable<Item>(
                            data: item,
                            feedback: Material(
                              color: Colors.transparent,
                              child: SizedBox(
                                width: 170,
                                child: Card(
                                  child: Padding(
                                    padding: const EdgeInsets.all(8),
                                    child: Column(
                                      children: [
                                        SizedBox(
                                          height: 78,
                                          child: ActivityAssetImage(
                                            assetPath: item.imageAsset,
                                          ),
                                        ),
                                        const SizedBox(height: 6),
                                        UpperText(item.word ?? ''),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            childWhenDragging: Opacity(
                              opacity: 0.3,
                              child: _LetterCard(
                                item: item,
                                onSpeak: () => _speakWord(item.word ?? ''),
                              ),
                            ),
                            child: _LetterCard(
                              item: item,
                              onSpeak: () => _speakWord(item.word ?? ''),
                            ),
                          );
                        }).toList(),
                      ),
                  ],
                ),
              ),
            ),
    );
  }
}

class _LetterCard extends StatelessWidget {
  const _LetterCard({
    required this.item,
    this.mobileLarge = false,
    this.tabletLarge = false,
    this.onSpeak,
  });

  final Item item;
  final bool mobileLarge;
  final bool tabletLarge;
  final VoidCallback? onSpeak;

  @override
  Widget build(BuildContext context) {
    final isLarge = mobileLarge || tabletLarge;
    final cardWidth = mobileLarge
        ? min(MediaQuery.sizeOf(context).width - 40, 280.0)
        : tabletLarge
        ? min(MediaQuery.sizeOf(context).width - 56, 360.0)
        : MediaQuery.sizeOf(context).width < 900
        ? 150.0
        : 176.0;
    return SizedBox(
      width: cardWidth,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Column(
            children: [
              SizedBox(
                height: isLarge ? 128 : 88,
                child: ActivityAssetImage(
                  assetPath: item.imageAsset,
                  semanticsLabel: item.word,
                ),
              ),
              const SizedBox(height: 6),
              UpperText(
                item.word ?? '',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                  fontSize: tabletLarge ? 28 : null,
                ),
              ),
              if (onSpeak != null) ...[
                const SizedBox(height: 8),
                IconButton.filledTonal(
                  onPressed: onSpeak,
                  icon: const Icon(Icons.volume_up_rounded),
                  tooltip: 'ESCUCHAR PALABRA',
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _DesktopSidebarItem extends StatelessWidget {
  const _DesktopSidebarItem({
    required this.icon,
    required this.label,
    this.active = false,
  });

  final IconData icon;
  final String label;
  final bool active;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: active ? kGameAccent : Colors.transparent,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            color: active ? Colors.white : const Color(0xFF51607C),
            size: 24,
          ),
          const SizedBox(width: 10),
          UpperText(
            label,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: active ? Colors.white : const Color(0xFF1D2A49),
            ),
          ),
        ],
      ),
    );
  }
}

class _DesktopLetterCard extends StatelessWidget {
  const _DesktopLetterCard({required this.item, this.onSpeak});

  final Item item;
  final VoidCallback? onSpeak;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: const Color(0xFFE0E5EF), width: 2),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
        child: Column(
          children: [
            Expanded(
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: const Color(0xFFF6F8FC),
                  borderRadius: BorderRadius.circular(26),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(8),
                  child: ActivityAssetImage(
                    assetPath: item.imageAsset,
                    semanticsLabel: item.word,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 10),
            UpperText(
              item.word ?? '',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 42,
                fontWeight: FontWeight.w900,
                color: Color(0xFF101A3D),
              ),
            ),
            const SizedBox(height: 8),
            IconButton.filledTonal(
              onPressed: onSpeak,
              icon: const Icon(Icons.volume_up_rounded),
              tooltip: 'ESCUCHAR PALABRA',
            ),
          ],
        ),
      ),
    );
  }
}
