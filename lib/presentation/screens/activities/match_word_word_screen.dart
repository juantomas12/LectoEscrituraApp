import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../application/providers/app_providers.dart';
import '../../../core/utils/pedagogical_feedback.dart';
import '../../../domain/models/activity_result.dart';
import '../../../domain/models/activity_type.dart';
import '../../../domain/models/category.dart';
import '../../../domain/models/difficulty.dart';
import '../../../domain/models/item.dart';
import '../../../domain/models/level.dart';
import '../../viewmodels/progress_view_model.dart';
import '../../widgets/game_style.dart';
import '../../widgets/upper_text.dart';
import '../results_screen.dart';

enum PairMode { iguales, relacionadas }

extension PairModeX on PairMode {
  String get label => switch (this) {
    PairMode.iguales => 'IGUALES',
    PairMode.relacionadas => 'RELACIONADAS',
  };
}

class MatchWordWordScreen extends ConsumerStatefulWidget {
  const MatchWordWordScreen({
    super.key,
    required this.category,
    required this.difficulty,
  });

  final AppCategory category;
  final Difficulty difficulty;

  @override
  ConsumerState<MatchWordWordScreen> createState() =>
      _MatchWordWordScreenState();
}

class _MatchWordWordScreenState extends ConsumerState<MatchWordWordScreen> {
  final Random _random = Random();

  List<Item> _pairs = [];
  final Set<String> _failedItemIds = {};
  final Map<String, int> _attemptsByItemId = {};
  List<String> _leftWords = [];
  List<String> _rightWords = [];

  final Set<String> _matchedLeft = {};
  final Set<String> _matchedRight = {};

  PairMode _mode = PairMode.iguales;
  String? _selectedLeft;
  String _feedback = 'SELECCIONA UNA PALABRA DE CADA COLUMNA';
  bool _isLoading = true;
  bool _isReinforcementRound = false;

  int _correct = 0;
  int _incorrect = 0;
  int _streak = 0;
  int _bestStreak = 0;

  DateTime _startedAt = DateTime.now();

  @override
  void initState() {
    super.initState();
    _prepareActivity();
  }

  Future<void> _prepareActivity({
    List<Item>? customPairs,
    bool reinforcement = false,
  }) async {
    final selectedPairs = customPairs ?? await _loadPairsFromDataset();
    final visiblePairs = selectedPairs.take(4).toList();

    if (!mounted) {
      return;
    }

    setState(() {
      _pairs = visiblePairs;
      _failedItemIds.clear();
      _attemptsByItemId.clear();
      _isReinforcementRound = reinforcement;
      _mode = PairMode.iguales;
      _correct = 0;
      _incorrect = 0;
      _streak = 0;
      _bestStreak = 0;
      _startedAt = DateTime.now();
      _feedback = reinforcement
          ? 'MINI-RONDA: REFUERZA LAS PALABRAS FALLADAS'
          : 'SELECCIONA UNA PALABRA DE CADA COLUMNA';
      _isLoading = false;
    });
    _rebuildColumns();
  }

  Future<List<Item>> _loadPairsFromDataset() async {
    final dataset = ref.read(datasetRepositoryProvider);
    final limit = widget.difficulty == Difficulty.primaria ? 6 : 8;
    final pool = dataset.getRandomizedPool(
      category: widget.category,
      activityType: ActivityType.palabraPalabra,
      difficulty: widget.difficulty,
      poolSize: 50,
    );
    if (pool.isEmpty) {
      return const [];
    }

    final shuffledPool = [...pool]..shuffle(_random);
    final selected = <Item>[];
    final usedPairs = <String>{};
    for (final item in shuffledPool) {
      final left = item.words.isNotEmpty
          ? item.words.first.trim().toUpperCase()
          : '';
      final right = item.words.length > 1
          ? item.words[1].trim().toUpperCase()
          : '';
      final pairKey = '$left|$right';
      if (left.isEmpty || right.isEmpty || !usedPairs.add(pairKey)) {
        continue;
      }
      selected.add(item);
      if (selected.length >= limit) {
        break;
      }
    }

    if (selected.length < limit) {
      final fallback = [...shuffledPool]..shuffle(_random);
      for (final item in fallback) {
        selected.add(
          item.copyWith(
            id: '${item.id}__EXTRA_${selected.length}_${_random.nextInt(99999)}',
          ),
        );
        if (selected.length >= limit) {
          break;
        }
      }
    }

    return selected;
  }

  void _rebuildColumns() {
    final left = _pairs
        .map((item) => item.words.isNotEmpty ? item.words.first : '')
        .where((value) => value.isNotEmpty)
        .toList();

    final right = _mode == PairMode.iguales
        ? List<String>.from(left)
        : _pairs
              .map((item) => item.words.length > 1 ? item.words[1] : '')
              .where((value) => value.isNotEmpty)
              .toList();

    right.shuffle(_random);

    setState(() {
      _leftWords = left;
      _rightWords = right;
      _matchedLeft.clear();
      _matchedRight.clear();
      _selectedLeft = null;
      _feedback = 'SELECCIONA UNA PALABRA DE CADA COLUMNA';
    });
  }

  Future<void> _tryMatch(String rightWord) async {
    final leftWord = _selectedLeft;
    if (leftWord == null || _matchedLeft.contains(leftWord)) {
      if (mounted && leftWord == null) {
        setState(() {
          _feedback = 'PRIMERO ELIGE UNA PALABRA EN COLUMNA A';
        });
      }
      return;
    }

    final pair = _pairs.firstWhere(
      (item) => item.words.isNotEmpty && item.words.first == leftWord,
      orElse: () => Item(
        id: '',
        category: widget.category,
        level: AppLevel.dos,
        activityType: ActivityType.palabraPalabra,
        imageAsset: '',
      ),
    );

    final expected = _mode == PairMode.iguales
        ? leftWord
        : (pair.words.length > 1 ? pair.words[1] : '');

    final isCorrect = rightWord == expected;
    final attemptsOnCurrent = (_attemptsByItemId[pair.id] ?? 0) + 1;

    if (pair.id.isNotEmpty) {
      await ref
          .read(progressViewModelProvider.notifier)
          .registerAttempt(
            itemId: pair.id,
            correct: isCorrect,
            activityType: ActivityType.palabraPalabra,
          );
    }

    if (!mounted) {
      return;
    }

    setState(() {
      if (pair.id.isNotEmpty) {
        _attemptsByItemId[pair.id] = attemptsOnCurrent;
      }
      if (isCorrect) {
        _matchedLeft.add(leftWord);
        _matchedRight.add(rightWord);
        _correct++;
        _streak++;
        _bestStreak = max(_bestStreak, _streak);
        _feedback = PedagogicalFeedback.positive(
          streak: _streak,
          totalCorrect: _correct,
        );
      } else {
        _incorrect++;
        _streak = 0;
        if (pair.id.isNotEmpty) {
          _failedItemIds.add(pair.id);
        }
        _feedback = PedagogicalFeedback.retry(
          attemptsOnCurrent: attemptsOnCurrent,
          hint: expected.isNotEmpty ? expected.substring(0, 1) : null,
        );
      }
      _selectedLeft = null;
    });

    if (_matchedLeft.length == _leftWords.length && _leftWords.isNotEmpty) {
      await _finishActivity();
    }
  }

  Future<void> _finishActivity() async {
    final failedPairs = _pairs
        .where((pair) => _failedItemIds.contains(pair.id))
        .toList();
    final result = ActivityResult(
      id: 'RES-${DateTime.now().millisecondsSinceEpoch}',
      category: widget.category,
      level: AppLevel.dos,
      activityType: ActivityType.palabraPalabra,
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
      MaterialPageRoute(
        builder: (_) => ResultsScreen(
          result: result,
          canReinforceErrors: failedPairs.isNotEmpty,
        ),
      ),
    );

    if (!mounted) {
      return;
    }

    if (action == ResultAction.repetir) {
      setState(() => _isLoading = true);
      await _prepareActivity();
      return;
    }

    if (action == ResultAction.reforzarErrores && failedPairs.isNotEmpty) {
      setState(() => _isLoading = true);
      await _prepareActivity(customPairs: failedPairs, reinforcement: true);
      return;
    }

    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.sizeOf(context);
    final width = media.width;
    final isTabletLandscapePrimary = isPrimaryTabletLandscape(context);
    final isDesktop = width >= 1000;
    final isWideLayout = width >= 860;
    final solvedCount = _matchedLeft.length;
    final contentWidth = isDesktop
        ? 1180.0
        : isTabletLandscapePrimary
        ? 1024.0
        : 920.0;

    return GameScaffold(
      title: 'RELACIONAR PALABRAS CON PALABRAS',
      desktopHeadline: '¡UNE LAS PAREJAS!',
      desktopLessonTitle: 'RELACIONAR PALABRAS',
      instructionText:
          'SELECCIONA UNA PALABRA DE CADA COLUMNA PARA FORMAR UN PAR',
      progressCurrent: solvedCount,
      progressTotal: _pairs.length,
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _pairs.isEmpty
          ? const Center(child: UpperText('NO HAY CONTENIDO DISPONIBLE'))
          : Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: contentWidth),
                child: Padding(
                  padding: EdgeInsets.fromLTRB(
                    isTabletLandscapePrimary ? 10 : 16,
                    isTabletLandscapePrimary ? 8 : 14,
                    isTabletLandscapePrimary ? 10 : 16,
                    isTabletLandscapePrimary ? 10 : 14,
                  ),
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final compact =
                          isTabletLandscapePrimary ||
                          constraints.maxHeight < 620;
                      final spacing = compact ? 8.0 : 12.0;

                      return Column(
                        children: [
                          if (_isReinforcementRound) ...[
                            GamePanel(
                              backgroundColor: Colors.orange.shade50,
                              borderColor: Colors.orange.shade200,
                              child: const Row(
                                children: [
                                  Icon(Icons.fitness_center_rounded),
                                  SizedBox(width: 8),
                                  Expanded(
                                    child: UpperText(
                                      'MINI-RONDA DE REFUERZO EN MARCHA',
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            SizedBox(height: spacing),
                          ],
                          Align(
                            child: SegmentedButton<PairMode>(
                              segments: const [
                                ButtonSegment(
                                  value: PairMode.iguales,
                                  label: UpperText('IGUALES'),
                                ),
                                ButtonSegment(
                                  value: PairMode.relacionadas,
                                  label: UpperText('RELACIONADAS'),
                                ),
                              ],
                              style: SegmentedButton.styleFrom(
                                foregroundColor: const Color(0xFF1B2949),
                                selectedForegroundColor: Colors.white,
                                selectedBackgroundColor: const Color(
                                  0xFF0F8A75,
                                ),
                                backgroundColor: Colors.white,
                                side: const BorderSide(
                                  color: Color(0xFF1B2949),
                                  width: 1.3,
                                ),
                                textStyle: TextStyle(
                                  fontWeight: FontWeight.w900,
                                  fontSize: compact ? 13 : 15,
                                ),
                              ),
                              selected: {_mode},
                              onSelectionChanged: (value) {
                                setState(() {
                                  _mode = value.first;
                                  _correct = 0;
                                  _incorrect = 0;
                                  _streak = 0;
                                  _bestStreak = 0;
                                  _startedAt = DateTime.now();
                                });
                                _rebuildColumns();
                              },
                            ),
                          ),
                          SizedBox(height: spacing),
                          GamePanel(
                            padding: EdgeInsets.symmetric(
                              horizontal: compact ? 12 : 14,
                              vertical: compact ? 10 : 12,
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.sync_alt_rounded),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: UpperText(
                                    _feedback,
                                    maxLines: compact ? 1 : 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          SizedBox(height: spacing),
                          Expanded(
                            child: isWideLayout
                                ? Row(
                                    children: [
                                      Expanded(
                                        child: _WordColumn(
                                          title: 'COLUMNA A',
                                          words: _leftWords,
                                          selected: _selectedLeft,
                                          matched: _matchedLeft,
                                          allowScroll:
                                              !isTabletLandscapePrimary,
                                          compact: compact,
                                          accentColor: const Color(0xFF2B8CEE),
                                          labelBackground: const Color(
                                            0xFFDCE8F7,
                                          ),
                                          isLeftColumn: true,
                                          onTap: (word) {
                                            if (_matchedLeft.contains(word)) {
                                              return;
                                            }
                                            setState(() {
                                              _selectedLeft = word;
                                              _feedback =
                                                  'AHORA ELIGE SU PAREJA EN COLUMNA B';
                                            });
                                          },
                                        ),
                                      ),
                                      SizedBox(width: spacing),
                                      Expanded(
                                        child: _WordColumn(
                                          title: 'COLUMNA B',
                                          words: _rightWords,
                                          selected: null,
                                          matched: _matchedRight,
                                          allowScroll:
                                              !isTabletLandscapePrimary,
                                          compact: compact,
                                          accentColor: const Color(0xFF0F8A75),
                                          labelBackground: const Color(
                                            0xFFDFF3EE,
                                          ),
                                          isLeftColumn: false,
                                          onTap: (word) => _tryMatch(word),
                                        ),
                                      ),
                                    ],
                                  )
                                : Column(
                                    children: [
                                      Expanded(
                                        child: _WordColumn(
                                          title: 'COLUMNA A',
                                          words: _leftWords,
                                          selected: _selectedLeft,
                                          matched: _matchedLeft,
                                          allowScroll:
                                              !isTabletLandscapePrimary,
                                          compact: compact,
                                          accentColor: const Color(0xFF2B8CEE),
                                          labelBackground: const Color(
                                            0xFFDCE8F7,
                                          ),
                                          isLeftColumn: true,
                                          onTap: (word) {
                                            if (_matchedLeft.contains(word)) {
                                              return;
                                            }
                                            setState(() {
                                              _selectedLeft = word;
                                              _feedback =
                                                  'AHORA ELIGE SU PAREJA EN COLUMNA B';
                                            });
                                          },
                                        ),
                                      ),
                                      SizedBox(height: spacing),
                                      Expanded(
                                        child: _WordColumn(
                                          title: 'COLUMNA B',
                                          words: _rightWords,
                                          selected: null,
                                          matched: _matchedRight,
                                          allowScroll:
                                              !isTabletLandscapePrimary,
                                          compact: compact,
                                          accentColor: const Color(0xFF0F8A75),
                                          labelBackground: const Color(
                                            0xFFDFF3EE,
                                          ),
                                          isLeftColumn: false,
                                          onTap: (word) => _tryMatch(word),
                                        ),
                                      ),
                                    ],
                                  ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ),
            ),
    );
  }
}

class _WordColumn extends StatelessWidget {
  const _WordColumn({
    required this.title,
    required this.words,
    required this.selected,
    required this.matched,
    required this.allowScroll,
    required this.compact,
    required this.accentColor,
    required this.labelBackground,
    required this.isLeftColumn,
    required this.onTap,
  });

  final String title;
  final List<String> words;
  final String? selected;
  final Set<String> matched;
  final bool allowScroll;
  final bool compact;
  final Color accentColor;
  final Color labelBackground;
  final bool isLeftColumn;
  final ValueChanged<String> onTap;

  @override
  Widget build(BuildContext context) {
    final itemSpacing = compact ? 8.0 : 12.0;

    return Column(
      children: [
        Container(
          padding: EdgeInsets.symmetric(
            horizontal: compact ? 22 : 26,
            vertical: compact ? 7 : 9,
          ),
          decoration: BoxDecoration(
            color: labelBackground,
            borderRadius: BorderRadius.circular(999),
          ),
          child: UpperText(
            title,
            style: TextStyle(
              fontSize: compact ? 14 : 16,
              fontWeight: FontWeight.w900,
              color: accentColor.withValues(alpha: 0.95),
              letterSpacing: 1.0,
            ),
          ),
        ),
        SizedBox(height: itemSpacing),
        Expanded(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final count = words.length;
              final rawHeight = count <= 0
                  ? 0.0
                  : (constraints.maxHeight - ((count - 1) * itemSpacing)) /
                        count;
              final cardHeight = allowScroll
                  ? (compact ? 72.0 : 84.0)
                  : rawHeight.clamp(
                      compact ? 56.0 : 64.0,
                      compact ? 86.0 : 98.0,
                    );

              return ListView.separated(
                physics: allowScroll
                    ? const BouncingScrollPhysics()
                    : const NeverScrollableScrollPhysics(),
                itemCount: words.length,
                padding: EdgeInsets.zero,
                separatorBuilder: (_, __) => SizedBox(height: itemSpacing),
                itemBuilder: (context, index) {
                  final word = words[index];
                  final isMatched = matched.contains(word);
                  final isSelected = selected == word;

                  return SizedBox(
                    height: cardHeight,
                    child: _WordChoiceCard(
                      word: word,
                      accentColor: accentColor,
                      compact: compact,
                      isLeftColumn: isLeftColumn,
                      isMatched: isMatched,
                      isSelected: isSelected,
                      enabled: !isMatched,
                      onTap: isMatched ? null : () => onTap(word),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}

class _WordChoiceCard extends StatelessWidget {
  const _WordChoiceCard({
    required this.word,
    required this.accentColor,
    required this.compact,
    required this.isLeftColumn,
    required this.isMatched,
    required this.isSelected,
    required this.enabled,
    this.onTap,
  });

  final String word;
  final Color accentColor;
  final bool compact;
  final bool isLeftColumn;
  final bool isMatched;
  final bool isSelected;
  final bool enabled;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final active = isSelected || isMatched;
    final radius = compact ? 32.0 : 36.0;

    final background = isMatched
        ? const Color(0xFFE7F7EF)
        : isSelected
        ? const Color(0xFFDCEBFF)
        : Colors.white;
    final borderColor = isMatched
        ? const Color(0xFF169865)
        : isSelected
        ? accentColor
        : Colors.transparent;

    final textStyle = TextStyle(
      fontSize: compact ? 16 : 18,
      fontWeight: FontWeight.w900,
      letterSpacing: 2.0,
      color: isMatched ? const Color(0xFF123A2E) : const Color(0xFF101938),
    );

    final circleSize = compact ? 32.0 : 40.0;
    final indicator = Container(
      width: circleSize,
      height: circleSize,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: active
            ? (isMatched ? const Color(0xFF169865) : accentColor)
            : accentColor.withValues(alpha: 0.13),
      ),
      child: Icon(
        active ? Icons.check_rounded : Icons.radio_button_unchecked_rounded,
        size: compact ? 19 : 24,
        color: active ? Colors.white : accentColor,
      ),
    );

    final cardChild = Row(
      children: [
        if (!isLeftColumn) indicator,
        if (!isLeftColumn) SizedBox(width: compact ? 10 : 14),
        Expanded(
          child: UpperText(
            word,
            textAlign: isLeftColumn ? TextAlign.left : TextAlign.right,
            style: textStyle,
          ),
        ),
        if (isLeftColumn) SizedBox(width: compact ? 10 : 14),
        if (isLeftColumn) indicator,
      ],
    );

    return AnimatedContainer(
      duration: const Duration(milliseconds: 140),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: borderColor, width: active ? 2.8 : 1.5),
        boxShadow: [
          if (!active)
            const BoxShadow(
              color: Color(0x12000000),
              blurRadius: 0,
              offset: Offset(0, 8),
            ),
          if (isSelected && !isMatched)
            BoxShadow(
              color: accentColor.withValues(alpha: 0.22),
              blurRadius: 18,
              offset: const Offset(0, 8),
            ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: enabled ? onTap : null,
          borderRadius: BorderRadius.circular(radius),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Padding(
                padding: EdgeInsets.symmetric(horizontal: compact ? 16 : 22),
                child: cardChild,
              ),
              if (isLeftColumn && isSelected && !isMatched)
                Positioned(
                  right: -16,
                  top: 0,
                  bottom: 0,
                  child: Center(
                    child: Container(
                      width: 18,
                      height: 4,
                      decoration: BoxDecoration(
                        color: accentColor,
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
