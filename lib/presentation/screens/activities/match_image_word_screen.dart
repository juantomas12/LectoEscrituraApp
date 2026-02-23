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
import '../../viewmodels/settings_view_model.dart';
import '../../widgets/activity_asset_image.dart';
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

  Future<void> _prepareActivity() async {
    final dataset = ref.read(datasetRepositoryProvider);
    final progressMap = ref.read(itemProgressMapProvider);

    final limit = widget.difficulty == Difficulty.primaria ? 4 : 6;

    final items = dataset.getPrioritizedItems(
      category: widget.category,
      level: AppLevel.uno,
      activityType: ActivityType.imagenPalabra,
      difficulty: widget.difficulty,
      progressMap: progressMap,
      limit: limit,
    );

    final selectedItems = items.isNotEmpty
        ? items
        : dataset.getItems(
            category: widget.category,
            level: AppLevel.uno,
            activityType: ActivityType.imagenPalabra,
          );

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
      _feedback = 'UNE CADA PALABRA CON SU IMAGEN';
      _correct = 0;
      _incorrect = 0;
      _streak = 0;
      _bestStreak = 0;
      _startedAt = DateTime.now();
      _isLoading = false;
    });
  }

  Future<void> _handleDrop(Item item, String droppedWord) async {
    if (_matchedByItem.containsKey(item.id)) {
      return;
    }

    final expected = item.word ?? '';
    final isCorrect = droppedWord == expected;

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
        _feedback = PedagogicalFeedback.retry(
          attemptsOnCurrent: _incorrect,
          hint: 'EMPIEZA POR ${expected.isNotEmpty ? expected[0] : ''}',
        );
      }
    });

    if (_matchedByItem.length == _items.length && _items.isNotEmpty) {
      await _finishActivity();
    }
  }

  Future<void> _finishActivity() async {
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
    required bool showHints,
    required double imageHeight,
    required bool compactDesktop,
  }) {
    final matchedWord = _matchedByItem[item.id];
    final imageZoom = compactDesktop ? 1.35 : 1.0;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Column(
          children: [
            SizedBox(
              height: imageHeight,
              child: matchedWord != null
                  ? Transform.scale(
                      scale: imageZoom,
                      child: ActivityAssetImage(
                        assetPath: item.imageAsset,
                        semanticsLabel: item.word,
                      ),
                    )
                  : DragTarget<String>(
                      onWillAcceptWithDetails: (details) {
                        return details.data.isNotEmpty;
                      },
                      onAcceptWithDetails: (details) {
                        _handleDrop(item, details.data);
                      },
                      builder: (context, candidateData, rejected) {
                        final isHovering = candidateData.isNotEmpty;
                        return Stack(
                          fit: StackFit.expand,
                          children: [
                            Transform.scale(
                              scale: imageZoom,
                              child: ActivityAssetImage(
                                assetPath: item.imageAsset,
                                semanticsLabel: item.word,
                              ),
                            ),
                            AnimatedContainer(
                              duration: const Duration(milliseconds: 140),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: isHovering
                                      ? Theme.of(context).colorScheme.primary
                                      : Colors.transparent,
                                  width: 3,
                                ),
                                color: isHovering
                                    ? Theme.of(context).colorScheme.primary
                                          .withValues(alpha: 0.08)
                                    : Colors.transparent,
                              ),
                            ),
                            if (isHovering)
                              Align(
                                alignment: Alignment.topCenter,
                                child: Container(
                                  margin: const EdgeInsets.only(top: 8),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.primary,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: UpperText(
                                    'SUELTA EN LA IMAGEN',
                                    style: Theme.of(context).textTheme.bodySmall
                                        ?.copyWith(
                                          color: Theme.of(
                                            context,
                                          ).colorScheme.onPrimary,
                                        ),
                                  ),
                                ),
                              ),
                          ],
                        );
                      },
                    ),
            ),
            const SizedBox(height: 8),
            if (matchedWord != null)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  color: Colors.green.shade100,
                  border: Border.all(color: Colors.green.shade600),
                ),
                child: UpperText(matchedWord, textAlign: TextAlign.center),
              )
            else
              DragTarget<String>(
                onWillAcceptWithDetails: (details) {
                  return details.data.isNotEmpty;
                },
                onAcceptWithDetails: (details) {
                  _handleDrop(item, details.data);
                },
                builder: (context, candidateData, rejected) {
                  return Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: candidateData.isNotEmpty
                            ? Theme.of(context).colorScheme.primary
                            : Theme.of(context).colorScheme.outline,
                        width: 2,
                      ),
                    ),
                    child: const UpperText(
                      'SUELTA AQUÍ',
                      textAlign: TextAlign.center,
                    ),
                  );
                },
              ),
            if (showHints && matchedWord == null)
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: UpperText(
                  'PISTA: ${item.word?.substring(0, 1) ?? ''}...',
                  style: Theme.of(
                    context,
                  ).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w700),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Chip _buildWordChip(BuildContext context, String word, double fontSize) {
    return Chip(
      label: SizedBox(
        width: double.infinity,
        child: UpperText(
          word,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: fontSize,
            fontWeight: FontWeight.w900,
            letterSpacing: 0.6,
          ),
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      side: BorderSide(color: Theme.of(context).colorScheme.primary),
      backgroundColor: Theme.of(context).colorScheme.surface,
    );
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(settingsViewModelProvider);
    final mediaSize = MediaQuery.sizeOf(context);
    final width = mediaSize.width;
    final orientation = MediaQuery.orientationOf(context);
    final isLandscape = orientation == Orientation.landscape;

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
        : isDesktop
        ? (isLandscape ? 4 : 3)
        : (isLandscape ? 3 : 2);

    final imageHeight = isDesktop
        ? 170.0
        : isTablet
        ? (isLandscape ? 155.0 : 165.0)
        : 210.0;

    final gridItemExtent = isDesktop
        ? 300.0
        : isTablet
        ? (isLandscape ? 270.0 : 300.0)
        : 360.0;

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

    final nextItem = _nextUnmatchedItem();

    return Scaffold(
      appBar: AppBar(
        title: const UpperText('RELACIONAR IMÁGENES CON PALABRAS'),
      ),
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
                  padding: const EdgeInsets.all(16),
                  children: [
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Row(
                          children: [
                            const Icon(Icons.info_outline),
                            const SizedBox(width: 10),
                            Expanded(child: UpperText(_feedback)),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    if (isPhone) ...[
                      UpperText(
                        'ARRASTRA LA PALABRA HASTA LA IMAGEN',
                        style: Theme.of(context).textTheme.titleLarge,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      if (nextItem == null)
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 20),
                          child: UpperText('COMPLETANDO...'),
                        )
                      else
                        _buildItemCard(
                          context: context,
                          item: nextItem,
                          showHints: settings.showHints,
                          imageHeight: 210,
                          compactDesktop: false,
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
                            showHints: settings.showHints,
                            imageHeight: imageHeight,
                            compactDesktop: isDesktop,
                          );
                        },
                      ),
                    const SizedBox(height: 10),
                    Center(
                      child: UpperText(
                        'PALABRAS DISPONIBLES',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w900,
                          fontSize: isPhone ? 30 : 34,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      alignment: WrapAlignment.center,
                      runAlignment: WrapAlignment.center,
                      spacing: 8,
                      runSpacing: 12,
                      children: _words
                          .where(
                            (word) => !_matchedByItem.values.contains(word),
                          )
                          .map(
                            (word) => Draggable<String>(
                              data: word,
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
                                    child: ConstrainedBox(
                                      constraints: BoxConstraints(
                                        minWidth: wordChipMinWidth,
                                      ),
                                      child: _buildWordChip(
                                        context,
                                        word,
                                        wordChipFontSize,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              childWhenDragging: Opacity(
                                opacity: 0.35,
                                child: ConstrainedBox(
                                  constraints: BoxConstraints(
                                    minWidth: wordChipMinWidth,
                                  ),
                                  child: _buildWordChip(
                                    context,
                                    word,
                                    wordChipFontSize,
                                  ),
                                ),
                              ),
                              child: ConstrainedBox(
                                constraints: BoxConstraints(
                                  minWidth: wordChipMinWidth,
                                ),
                                child: _buildWordChip(
                                  context,
                                  word,
                                  wordChipFontSize,
                                ),
                              ),
                            ),
                          )
                          .toList(),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
