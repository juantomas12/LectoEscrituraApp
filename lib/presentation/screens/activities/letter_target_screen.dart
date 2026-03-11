import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../application/providers/app_providers.dart';
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
  static const _vowels = ['A', 'E', 'I', 'O', 'U'];
  final Random _random = Random();

  List<Item> _items = [];
  final Map<String, bool> _classifiedByItem = {};
  late final bool _allowVowelSwitcher;
  String? _selectedPlayableLetter;
  String _targetLetter = 'A';
  bool _isLoading = true;
  String? _lastFailedItemId;
  String? _lastFailedMessage;

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

  @override
  void initState() {
    super.initState();
    final normalizedTarget = (widget.targetLetter ?? '').trim().toUpperCase();
    _allowVowelSwitcher =
        widget.matchMode == LetterMatchMode.contiene &&
        _vowels.contains(normalizedTarget);
    if (_allowVowelSwitcher) {
      _selectedPlayableLetter = normalizedTarget;
    }
    _prepareActivity();
  }

  Future<void> _prepareActivity() async {
    final dataset = ref.read(datasetRepositoryProvider);
    final source = dataset
        .getRandomizedPool(
          category: widget.category,
          activityType: ActivityType.imagenPalabra,
          difficulty: widget.difficulty,
          poolSize: 50,
        )
        .where((item) => (item.word ?? '').trim().isNotEmpty)
        .toList();
    source.shuffle(_random);

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

    final forcedLetter = _allowVowelSwitcher
        ? _selectedPlayableLetter
        : widget.targetLetter?.toUpperCase();
    final selectedCandidates = forcedLetter != null
        ? [forcedLetter]
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
      if (_allowVowelSwitcher) {
        _selectedPlayableLetter = selectedLetter;
      }
      _classifiedByItem.clear();
      _lastFailedItemId = null;
      _lastFailedMessage = null;
      _correct = 0;
      _incorrect = 0;
      _streak = 0;
      _bestStreak = 0;
      _consecutiveErrors = 0;
      _startedAt = DateTime.now();
      _isLoading = false;
    });
  }

  Future<void> _changePlayableLetter(String letter) async {
    final normalized = letter.trim().toUpperCase();
    if (!_allowVowelSwitcher ||
        _isLoading ||
        normalized.isEmpty ||
        normalized == _targetLetter) {
      return;
    }

    setState(() {
      _isLoading = true;
      _selectedPlayableLetter = normalized;
    });

    await _prepareActivity();
  }

  Future<void> _playFailureSound() async {
    final settings = ref.read(settingsViewModelProvider);
    if (!settings.audioEnabled) {
      return;
    }
    await SystemSound.play(SystemSoundType.alert);
  }

  Future<void> _handleDrop(Item item, {required bool toHasLetter}) async {
    if (_classifiedByItem.containsKey(item.id)) {
      return;
    }

    final actualHasLetter = _matchesWord(item.word ?? '', _targetLetter);
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

    if (!isCorrect) {
      await _playFailureSound();
    }

    setState(() {
      if (isCorrect) {
        _classifiedByItem[item.id] = toHasLetter;
        _correct++;
        _streak++;
        _consecutiveErrors = 0;
        _bestStreak = max(_bestStreak, _streak);
        if (_lastFailedItemId == item.id) {
          _lastFailedItemId = null;
          _lastFailedMessage = null;
        }
      } else {
        _incorrect++;
        _streak = 0;
        _lastFailedItemId = item.id;
        final expectedZone = actualHasLetter
            ? '${widget.matchMode.label} $_targetLetter'
            : 'NO ${widget.matchMode.label} $_targetLetter';
        _lastFailedMessage =
            '${item.word ?? 'ESTE OBJETO'} VA EN $expectedZone';
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

  Widget _buildFailureBanner(BuildContext context, {bool desktop = false}) {
    if (_lastFailedMessage == null) {
      return const SizedBox.shrink();
    }

    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(
        horizontal: desktop ? 18 : 12,
        vertical: desktop ? 14 : 10,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFFFFECEC),
        borderRadius: BorderRadius.circular(desktop ? 22 : 14),
        border: Border.all(color: const Color(0xFFF28A8A), width: 2),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_rounded, color: Color(0xFFCF3535), size: 30),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                UpperText(
                  'ÚLTIMO FALLO',
                  style: TextStyle(
                    fontSize: desktop ? 18 : 14,
                    fontWeight: FontWeight.w900,
                    color: const Color(0xFFB82929),
                  ),
                ),
                const SizedBox(height: 4),
                UpperText(
                  _lastFailedMessage!,
                  style: TextStyle(
                    fontSize: desktop ? 16 : 13,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFFB82929),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Container(
            padding: EdgeInsets.symmetric(
              horizontal: desktop ? 14 : 10,
              vertical: desktop ? 10 : 6,
            ),
            decoration: BoxDecoration(
              color: const Color(0xFFFFD7D7),
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: const Color(0xFFF28A8A)),
            ),
            child: UpperText(
              'FALLOS: $_incorrect',
              style: TextStyle(
                fontSize: desktop ? 14 : 12,
                fontWeight: FontWeight.w900,
                color: const Color(0xFFB82929),
              ),
            ),
          ),
        ],
      ),
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

  Widget _buildVowelSwitcher() {
    if (!_allowVowelSwitcher) {
      return const SizedBox.shrink();
    }

    return GamePanel(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      backgroundColor: const Color(0xFFF4F8FF),
      borderColor: const Color(0xFFCFE0FF),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const UpperText(
            'CAMBIAR VOCAL',
            style: TextStyle(
              fontSize: 14,
              color: Color(0xFF2C86EA),
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _vowels.map((letter) {
              final selected = _targetLetter == letter;
              return InkWell(
                borderRadius: BorderRadius.circular(999),
                onTap: () => _changePlayableLetter(letter),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: selected
                        ? const Color(0xFF2C86EA)
                        : const Color(0xFFEAF2FF),
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(
                      color: selected
                          ? const Color(0xFF2C86EA)
                          : const Color(0xFFBED5FF),
                      width: selected ? 2 : 1.4,
                    ),
                  ),
                  child: UpperText(
                    letter,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w900,
                      color: selected ? Colors.white : const Color(0xFF2C86EA),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final isLandscape =
        MediaQuery.orientationOf(context) == Orientation.landscape;
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

    return GameScaffold(
      title: widget.customTitle ?? 'LETRAS Y VOCALES',
      instructionText: _instructionQuestion(),
      progressCurrent: solvedCount,
      progressTotal: _items.length,
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
                  physics: isTabletLandscape
                      ? const NeverScrollableScrollPhysics()
                      : null,
                  padding: const EdgeInsets.all(16),
                  children: [
                    if (!isTabletLandscape) ...[
                      GameProgressHeader(
                        label: 'TU PROGRESO',
                        current: solvedCount,
                        total: _items.length,
                        trailingLabel: '⭐ $_correct',
                      ),
                      const SizedBox(height: 10),
                    ],
                    GamePanel(
                      padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
                      backgroundColor: const Color(0xFFFFF8F2),
                      borderColor: const Color(0xFFFFD8BF),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const UpperText(
                            'MISIÓN ACTUAL',
                            style: TextStyle(
                              fontSize: 16,
                              color: Color(0xFFB65117),
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          const SizedBox(height: 6),
                          UpperText(
                            'CLASIFICA LAS TARJETAS CON LA LETRA $_targetLetter',
                            style: const TextStyle(
                              fontSize: 15,
                              color: Color(0xFF4E6188),
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 10),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(999),
                            child: LinearProgressIndicator(
                              value: _items.isEmpty
                                  ? 0
                                  : (solvedCount / _items.length).clamp(
                                      0.0,
                                      1.0,
                                    ),
                              minHeight: 10,
                              backgroundColor: const Color(0xFFFFE8D7),
                              color: const Color(0xFFEF5B10),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              UpperText(
                                'COMPLETADAS: $solvedCount/${_items.length}',
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: Color(0xFF4E6188),
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              const Spacer(),
                              UpperText(
                                '${_items.isEmpty ? 0 : ((solvedCount / _items.length) * 100).round()}%',
                                style: const TextStyle(
                                  color: Color(0xFFEF5B10),
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),
                    if (_allowVowelSwitcher) ...[
                      _buildVowelSwitcher(),
                      const SizedBox(height: 10),
                    ],
                    if (!isTabletLandscape) ...[
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
                    ],
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
                    if (_lastFailedMessage != null) ...[
                      const SizedBox(height: 10),
                      _buildFailureBanner(context),
                    ],
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
                                      isErrorMarked:
                                          nextItem.id == _lastFailedItemId,
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
                                    isErrorMarked:
                                        nextItem.id == _lastFailedItemId,
                                    onSpeak: () =>
                                        _speakWord(nextItem.word ?? ''),
                                  ),
                                ),
                                child: _LetterCard(
                                  item: nextItem,
                                  tabletLarge: true,
                                  isErrorMarked:
                                      nextItem.id == _lastFailedItemId,
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
                                        isErrorMarked:
                                            item.id == _lastFailedItemId,
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
                                      isErrorMarked:
                                          item.id == _lastFailedItemId,
                                      onSpeak: () =>
                                          _speakWord(item.word ?? ''),
                                    ),
                                  ),
                                  child: _LetterCard(
                                    item: item,
                                    mobileLarge: isPhone,
                                    tabletLarge: isTablet && !isTabletLandscape,
                                    isErrorMarked: item.id == _lastFailedItemId,
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
                                isErrorMarked: item.id == _lastFailedItemId,
                                onSpeak: () => _speakWord(item.word ?? ''),
                              ),
                            ),
                            child: _LetterCard(
                              item: item,
                              isErrorMarked: item.id == _lastFailedItemId,
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
    this.isErrorMarked = false,
    this.onSpeak,
  });

  final Item item;
  final bool mobileLarge;
  final bool tabletLarge;
  final bool isErrorMarked;
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
        color: isErrorMarked ? const Color(0xFFFFF6F6) : null,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(
            color: isErrorMarked
                ? const Color(0xFFE86A6A)
                : const Color(0xFFDDE3EE),
            width: isErrorMarked ? 2.4 : 1.2,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Column(
            children: [
              if (isErrorMarked)
                Container(
                  width: double.infinity,
                  margin: const EdgeInsets.only(bottom: 6),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFE3E3),
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(color: const Color(0xFFF28A8A)),
                  ),
                  child: const UpperText(
                    'REVISA ESTA TARJETA',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 12,
                      color: Color(0xFFB82929),
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
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
