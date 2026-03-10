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
import '../../widgets/activity_asset_image.dart';
import '../../widgets/game_style.dart';
import '../../widgets/upper_text.dart';
import '../results_screen.dart';

class MatchImageWordScreen extends ConsumerStatefulWidget {
  const MatchImageWordScreen({
    super.key,
    required this.category,
    required this.difficulty,
  });

  final AppCategory category;
  final Difficulty difficulty;

  @override
  ConsumerState<MatchImageWordScreen> createState() =>
      _MatchImageWordScreenState();
}

class _MatchImageWordScreenState extends ConsumerState<MatchImageWordScreen> {
  final Random _random = Random();

  List<Item> _items = [];
  List<String> _words = [];
  final Map<String, String> _matchedByItem = {};
  final Map<String, int> _attemptsByItem = {};
  final Set<String> _failedItemIds = {};

  String _feedback = 'UNE CADA PALABRA CON SU IMAGEN';
  bool _isLoading = true;

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
    List<Item>? customItems,
    bool reinforcement = false,
  }) async {
    final selectedItems = customItems ?? await _loadItemsFromDataset();

    final words =
        selectedItems
            .map((item) => item.word ?? '')
            .where((word) => word.isNotEmpty)
            .toList()
          ..shuffle(_random);

    if (!mounted) {
      return;
    }

    setState(() {
      _items = selectedItems;
      _words = words;
      _matchedByItem.clear();
      _attemptsByItem.clear();
      _failedItemIds.clear();
      _feedback = reinforcement
          ? 'MINI-RONDA: REFUERZA LAS PALABRAS FALLADAS'
          : 'UNE CADA PALABRA CON SU IMAGEN';
      _correct = 0;
      _incorrect = 0;
      _streak = 0;
      _bestStreak = 0;
      _startedAt = DateTime.now();
      _isLoading = false;
    });
  }

  Future<List<Item>> _loadItemsFromDataset() async {
    final dataset = ref.read(datasetRepositoryProvider);
    final limit = 4;
    final pool = dataset.getRandomizedPool(
      category: widget.category,
      activityType: ActivityType.imagenPalabra,
      difficulty: widget.difficulty,
      poolSize: 50,
    );
    if (pool.isEmpty) {
      return const [];
    }

    final shuffledPool = [...pool]..shuffle(_random);
    final selected = <Item>[];
    final usedWords = <String>{};
    for (final item in shuffledPool) {
      final word = (item.word ?? '').trim().toUpperCase();
      if (word.isEmpty || !usedWords.add(word)) {
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

  Future<void> _handleDrop(Item item, String droppedWord) async {
    if (_matchedByItem.containsKey(item.id)) {
      return;
    }

    final expected = item.word ?? '';
    final isCorrect = droppedWord == expected;
    final attemptsOnCurrent = (_attemptsByItem[item.id] ?? 0) + 1;

    await ref
        .read(progressViewModelProvider.notifier)
        .registerAttempt(
          itemId: item.id,
          correct: isCorrect,
          activityType: ActivityType.imagenPalabra,
        );

    if (!mounted) {
      return;
    }

    setState(() {
      _attemptsByItem[item.id] = attemptsOnCurrent;
      if (isCorrect) {
        _matchedByItem[item.id] = droppedWord;
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
        _failedItemIds.add(item.id);
        _feedback = PedagogicalFeedback.retry(
          attemptsOnCurrent: attemptsOnCurrent,
          hint: 'EMPIEZA POR ${expected.isNotEmpty ? expected[0] : ''}',
        );
      }
    });

    if (_matchedByItem.length == _items.length && _items.isNotEmpty) {
      await _finishActivity();
    }
  }

  Future<void> _finishActivity() async {
    final failedItems = _items
        .where((item) => _failedItemIds.contains(item.id))
        .toList();
    final result = ActivityResult(
      id: 'RES-${DateTime.now().millisecondsSinceEpoch}',
      category: widget.category,
      level: AppLevel.uno,
      activityType: ActivityType.imagenPalabra,
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
          canReinforceErrors: failedItems.isNotEmpty,
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

    if (action == ResultAction.reforzarErrores && failedItems.isNotEmpty) {
      setState(() => _isLoading = true);
      await _prepareActivity(customItems: failedItems, reinforcement: true);
      return;
    }

    Navigator.of(context).pop();
  }

  Item? _nextUnmatchedItem() {
    for (final item in _items) {
      if (!_matchedByItem.containsKey(item.id)) {
        return item;
      }
    }
    return null;
  }

  Widget _buildItemCard({
    required BuildContext context,
    required Item item,
    required double imageHeight,
  }) {
    final matchedWord = _matchedByItem[item.id];

    Widget buildCard(bool isHovering) {
      return Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(34),
          border: Border.all(color: const Color(0xFFE6EBF3), width: 1.8),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        padding: const EdgeInsets.all(14),
        child: Column(
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 140),
              height: imageHeight,
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF5F7FA),
                borderRadius: BorderRadius.circular(30),
                border: Border.all(
                  color: isHovering
                      ? const Color(0xFF8DBEFF)
                      : const Color(0xFFE3E8F1),
                  width: isHovering ? 2.8 : 1.4,
                ),
              ),
              child: ActivityAssetImage(
                assetPath: item.imageAsset,
                semanticsLabel: item.word,
                fit: BoxFit.contain,
              ),
            ),
            const SizedBox(height: 8),
            if (matchedWord != null)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(999),
                  color: const Color(0xFFE8F0FF),
                  border: Border.all(color: const Color(0xFFBFD4F8), width: 2),
                ),
                child: UpperText(
                  matchedWord,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF152241),
                  ),
                ),
              )
            else
              AnimatedContainer(
                duration: const Duration(milliseconds: 140),
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(999),
                  color: isHovering
                      ? const Color(0xFFEAF3FF)
                      : const Color(0xFFF8FAFD),
                  border: Border.all(
                    color: isHovering
                        ? const Color(0xFF8DBEFF)
                        : const Color(0xFFD9E1EE),
                    width: isHovering ? 2.8 : 2,
                  ),
                ),
                child: const UpperText(
                  'ARRASTRA AQUÍ',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFFA4B3CA),
                    letterSpacing: 1.2,
                  ),
                ),
              ),
          ],
        ),
      );
    }

    if (matchedWord != null) {
      return buildCard(false);
    }

    return DragTarget<String>(
      onWillAcceptWithDetails: (details) => details.data.isNotEmpty,
      onAcceptWithDetails: (details) => _handleDrop(item, details.data),
      builder: (context, candidateData, rejected) {
        return buildCard(candidateData.isNotEmpty);
      },
    );
  }

  Chip _buildWordChip(
    BuildContext context,
    String word,
    double fontSize, {
    bool expand = true,
  }) {
    final label = UpperText(
      word,
      textAlign: TextAlign.center,
      style: TextStyle(
        fontSize: fontSize,
        fontWeight: FontWeight.w900,
        letterSpacing: 0.6,
      ),
    );

    return Chip(
      label: expand ? SizedBox(width: double.infinity, child: label) : label,
      padding: const EdgeInsets.symmetric(horizontal: 26, vertical: 14),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
      side: const BorderSide(color: Color(0xFFE2E8F2), width: 1.4),
      backgroundColor: Colors.white,
      shadowColor: Colors.black.withValues(alpha: 0.08),
      elevation: 2,
    );
  }

  @override
  Widget build(BuildContext context) {
    final mediaSize = MediaQuery.sizeOf(context);
    final width = mediaSize.width;
    final orientation = MediaQuery.orientationOf(context);
    final isLandscape = orientation == Orientation.landscape;
    final isTabletLandscapePrimary = isPrimaryTabletLandscape(context);

    final isPhone = width < 700;
    final isTablet = width >= 700 && width < 1200;
    final isDesktop = width >= 1200;

    final contentWidth = isDesktop
        ? 1320.0
        : isTablet
        ? (isLandscape ? 1120.0 : 980.0)
        : 920.0;

    final crossAxisCount = isPhone
        ? 1
        : isTabletLandscapePrimary
        ? 4
        : isDesktop
        ? (isLandscape ? 4 : 3)
        : (isLandscape ? 3 : 2);

    final imageHeight = isDesktop
        ? 198.0
        : isTablet
        ? (isTabletLandscapePrimary ? 180.0 : (isLandscape ? 176.0 : 188.0))
        : 190.0;

    final gridItemExtent = isDesktop
        ? 334.0
        : isTablet
        ? (isTabletLandscapePrimary ? 314.0 : (isLandscape ? 304.0 : 318.0))
        : 320.0;

    final wordChipFontSize = isPhone
        ? 28.0
        : isTablet
        ? 34.0
        : 30.0;
    final wordChipMinWidth = isPhone
        ? 170.0
        : isTablet
        ? 230.0
        : 210.0;
    final availableWords = _words
        .where((word) => !_matchedByItem.values.contains(word))
        .toList();
    final solvedCount = _matchedByItem.length;

    final nextItem = _nextUnmatchedItem();

    return GameScaffold(
      title: 'RELACIONAR IMÁGENES CON PALABRAS',
      instructionText: 'ARRASTRA LA PALABRA HASTA LA IMAGEN CORRECTA',
      progressCurrent: solvedCount,
      progressTotal: _items.length,
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _items.isEmpty
          ? const Center(
              child: Padding(
                padding: EdgeInsets.all(20),
                child: UpperText('NO HAY CONTENIDO PARA ESTA CATEGORÍA'),
              ),
            )
          : Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: contentWidth),
                child: ListView(
                  physics: isTabletLandscapePrimary
                      ? const NeverScrollableScrollPhysics()
                      : null,
                  padding: const EdgeInsets.all(16),
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const UpperText(
                                '¡RELACIONA CADA IMAGEN!',
                                style: TextStyle(
                                  fontSize: 28,
                                  fontWeight: FontWeight.w900,
                                  color: Color(0xFF121B38),
                                ),
                              ),
                              const SizedBox(height: 4),
                              UpperText(
                                _feedback,
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: Color(0xFF5B6A87),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (!isPhone)
                          CircleAvatar(
                            radius: 28,
                            backgroundColor: Colors.white,
                            child: IconButton(
                              onPressed: () => ref
                                  .read(ttsServiceProvider)
                                  .speak(
                                    'ARRASTRA LA PALABRA CORRECTA DEBAJO DE SU IMAGEN',
                                  ),
                              icon: const Icon(
                                Icons.volume_up_rounded,
                                color: Color(0xFF2B8CEE),
                              ),
                              tooltip: 'ESCUCHAR',
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    if (isPhone) ...[
                      if (nextItem == null)
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 20),
                          child: UpperText('COMPLETANDO...'),
                        )
                      else
                        _buildItemCard(
                          context: context,
                          item: nextItem,
                          imageHeight: 210,
                        ),
                      const SizedBox(height: 12),
                    ] else
                      GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: crossAxisCount,
                          mainAxisSpacing: 10,
                          crossAxisSpacing: 10,
                          mainAxisExtent: gridItemExtent,
                        ),
                        itemCount: _items.length,
                        itemBuilder: (context, index) {
                          final item = _items[index];
                          return _buildItemCard(
                            context: context,
                            item: item,
                            imageHeight: imageHeight,
                          );
                        },
                      ),
                    const SizedBox(height: 20),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 16,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEFF4FB),
                        borderRadius: BorderRadius.circular(38),
                        border: Border.all(
                          color: const Color(0xFFBFD6F6),
                          width: 2,
                        ),
                      ),
                      child: Wrap(
                        alignment: WrapAlignment.center,
                        spacing: 12,
                        runSpacing: 12,
                        children: availableWords.map((word) {
                          return Draggable<String>(
                            data: word,
                            affinity: Axis.vertical,
                            maxSimultaneousDrags: 1,
                            dragAnchorStrategy: pointerDragAnchorStrategy,
                            feedback: Material(
                              color: Colors.transparent,
                              child: Transform.translate(
                                offset: const Offset(0, -28),
                                child: DecoratedBox(
                                  decoration: BoxDecoration(
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withValues(
                                          alpha: 0.22,
                                        ),
                                        blurRadius: 14,
                                        offset: const Offset(0, 8),
                                      ),
                                    ],
                                  ),
                                  child: SizedBox(
                                    width: wordChipMinWidth,
                                    child: _buildWordChip(
                                      context,
                                      word,
                                      wordChipFontSize,
                                      expand: false,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            childWhenDragging: Opacity(
                              opacity: 0.35,
                              child: SizedBox(
                                width: wordChipMinWidth,
                                child: _buildWordChip(
                                  context,
                                  word,
                                  wordChipFontSize,
                                  expand: false,
                                ),
                              ),
                            ),
                            child: SizedBox(
                              width: wordChipMinWidth,
                              child: _buildWordChip(
                                context,
                                word,
                                wordChipFontSize,
                                expand: false,
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
