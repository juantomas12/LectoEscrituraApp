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
import '../../../domain/models/level.dart';
import '../../viewmodels/progress_view_model.dart';
import '../../viewmodels/settings_view_model.dart';
import '../../widgets/activity_asset_image.dart';
import '../../widgets/game_style.dart';
import '../../widgets/upper_text.dart';
import '../results_screen.dart';

class MatchImagePhraseScreen extends ConsumerStatefulWidget {
  const MatchImagePhraseScreen({
    super.key,
    required this.category,
    required this.difficulty,
  });

  final AppCategory category;
  final Difficulty difficulty;

  @override
  ConsumerState<MatchImagePhraseScreen> createState() =>
      _MatchImagePhraseScreenState();
}

class _MatchImagePhraseScreenState
    extends ConsumerState<MatchImagePhraseScreen> {
  final Random _random = Random();

  List<Item> _items = [];
  final Map<String, String> _expectedPhraseByItem = {};
  final Set<String> _failedItemIds = {};
  final Map<String, int> _attemptsByItem = {};
  List<String> _phrases = [];
  final Map<String, String> _matchedByItem = {};

  bool _isLoading = true;
  String _feedback = 'UNE CADA FRASE CON SU IMAGEN';
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
    List<Item>? customItems,
    bool reinforcement = false,
  }) async {
    final selectedItems = customItems ?? await _loadItemsFromDataset();

    final phraseMap = <String, String>{};
    for (final item in selectedItems) {
      if (item.phrases.isEmpty) {
        phraseMap[item.id] = '';
        continue;
      }
      item.phrases.sort((a, b) => countWords(a).compareTo(countWords(b)));
      phraseMap[item.id] = widget.difficulty == Difficulty.primaria
          ? item.phrases.first
          : item.phrases.last;
    }

    final phrases = phraseMap.values.where((value) => value.isNotEmpty).toList()
      ..shuffle(_random);

    if (!mounted) {
      return;
    }

    setState(() {
      _items = selectedItems;
      _expectedPhraseByItem
        ..clear()
        ..addAll(phraseMap);
      _phrases = phrases;
      _matchedByItem.clear();
      _failedItemIds.clear();
      _attemptsByItem.clear();
      _isReinforcementRound = reinforcement;
      _feedback = reinforcement
          ? 'MINI-RONDA: REFUERZA LAS FRASES FALLADAS'
          : 'UNE CADA FRASE CON SU IMAGEN';
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
    final progressMap = ref.read(itemProgressMapProvider);
    final limit = widget.difficulty == Difficulty.primaria ? 4 : 6;

    final items = dataset.getPrioritizedItems(
      category: widget.category,
      level: AppLevel.tres,
      activityType: ActivityType.imagenFrase,
      difficulty: widget.difficulty,
      progressMap: progressMap,
      limit: limit,
    );
    if (items.isNotEmpty) {
      return items;
    }
    return dataset.getItems(
      category: widget.category,
      level: AppLevel.tres,
      activityType: ActivityType.imagenFrase,
    );
  }

  Future<void> _handleDrop(Item item, String phrase) async {
    if (_matchedByItem.containsKey(item.id)) {
      return;
    }

    final expected = _expectedPhraseByItem[item.id] ?? '';
    final isCorrect = phrase == expected;
    final attemptsOnCurrent = (_attemptsByItem[item.id] ?? 0) + 1;

    await ref
        .read(progressViewModelProvider.notifier)
        .registerAttempt(
          itemId: item.id,
          correct: isCorrect,
          activityType: ActivityType.imagenFrase,
        );

    if (!mounted) {
      return;
    }

    setState(() {
      _attemptsByItem[item.id] = attemptsOnCurrent;
      if (isCorrect) {
        _matchedByItem[item.id] = phrase;
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
          hint: 'LEE DESPACIO LA FRASE',
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
      level: AppLevel.tres,
      activityType: ActivityType.imagenFrase,
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
    required bool showHints,
    required double imageHeight,
    required bool compactDesktop,
  }) {
    final matched = _matchedByItem[item.id];
    final expected = _expectedPhraseByItem[item.id] ?? '';
    final imageZoom = compactDesktop ? 1.35 : 1.0;

    return GamePanel(
      padding: const EdgeInsets.all(10),
      child: Column(
        children: [
          SizedBox(
            height: imageHeight,
            child: Transform.scale(
              scale: imageZoom,
              child: ActivityAssetImage(
                assetPath: item.imageAsset,
                semanticsLabel: expected,
              ),
            ),
          ),
          const SizedBox(height: 8),
          if (matched != null)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                color: Colors.green.shade100,
                border: Border.all(color: Colors.green.shade700),
              ),
              child: UpperText(matched, textAlign: TextAlign.center),
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
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      width: 2,
                      color: candidateData.isNotEmpty
                          ? Theme.of(context).colorScheme.primary
                          : Theme.of(context).colorScheme.outline,
                    ),
                  ),
                  child: const UpperText(
                    'SUELTA AQUÍ',
                    textAlign: TextAlign.center,
                  ),
                );
              },
            ),
          if (showHints && matched == null)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: UpperText(
                'PISTA: ${countWords(expected)} PALABRAS',
                style: Theme.of(
                  context,
                ).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w700),
              ),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(settingsViewModelProvider);
    final width = MediaQuery.sizeOf(context).width;
    final isTabletLandscapePrimary = isPrimaryTabletLandscape(context);
    final isMobile = width < 900;
    final isDesktop = width >= 1000;
    final contentWidth = isDesktop ? 1180.0 : 900.0;
    final maxColumnsByWidth = width >= 1450
        ? 4
        : width >= 1180
        ? 3
        : 2;
    final desiredColumns = _items.length >= 4 ? (_items.length / 2).ceil() : 2;
    final crossAxisCount = desiredColumns.clamp(2, maxColumnsByWidth).toInt();
    final imageHeight = isTabletLandscapePrimary
        ? 150.0
        : isDesktop
        ? 175.0
        : 190.0;
    final gridItemExtent = isTabletLandscapePrimary
        ? 254.0
        : isDesktop
        ? 305.0
        : 370.0;
    final solvedCount = _matchedByItem.length;

    return GameScaffold(
      title: 'RELACIONAR FRASES CON IMÁGENES',
      instructionText: 'ARRASTRA LA FRASE HASTA LA IMAGEN CORRECTA',
      progressCurrent: solvedCount,
      progressTotal: _items.length,
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _items.isEmpty
          ? const Center(child: UpperText('NO HAY CONTENIDO DISPONIBLE'))
          : Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: contentWidth),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      if (!isTabletLandscapePrimary) ...[
                        GameProgressHeader(
                          label: 'TU PROGRESO',
                          current: solvedCount,
                          total: _items.length,
                          trailingLabel: '⭐ $_correct',
                        ),
                        const SizedBox(height: 10),
                      ],
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
                        const SizedBox(height: 10),
                      ],
                      GamePanel(
                        child: Row(
                          children: [
                            const Icon(Icons.info_outline),
                            const SizedBox(width: 10),
                            Expanded(child: UpperText(_feedback)),
                          ],
                        ),
                      ),
                      const SizedBox(height: 10),
                      Expanded(
                        child: isMobile
                            ? Builder(
                                builder: (context) {
                                  final nextItem = _nextUnmatchedItem();
                                  if (nextItem == null) {
                                    return const Center(
                                      child: UpperText('COMPLETANDO...'),
                                    );
                                  }
                                  return ListView(
                                    children: [
                                      UpperText(
                                        'ARRASTRA LA FRASE A LA IMAGEN',
                                        style: Theme.of(
                                          context,
                                        ).textTheme.titleLarge,
                                        textAlign: TextAlign.center,
                                      ),
                                      const SizedBox(height: 8),
                                      _buildItemCard(
                                        context: context,
                                        item: nextItem,
                                        showHints: settings.showHints,
                                        imageHeight: 210,
                                        compactDesktop: false,
                                      ),
                                    ],
                                  );
                                },
                              )
                            : GridView.builder(
                                gridDelegate:
                                    SliverGridDelegateWithFixedCrossAxisCount(
                                      crossAxisCount: crossAxisCount,
                                      crossAxisSpacing: 10,
                                      mainAxisSpacing: 10,
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
                      ),
                      const SizedBox(height: 10),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: UpperText(
                          'FRASES DISPONIBLES',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Builder(
                        builder: (context) {
                          final availablePhrases = _phrases
                              .where(
                                (phrase) =>
                                    !_matchedByItem.values.contains(phrase),
                              )
                              .toList();
                          if (isTabletLandscapePrimary) {
                            return GridView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: availablePhrases.length,
                              gridDelegate:
                                  const SliverGridDelegateWithFixedCrossAxisCount(
                                    crossAxisCount: 3,
                                    mainAxisSpacing: 8,
                                    crossAxisSpacing: 8,
                                    mainAxisExtent: 64,
                                  ),
                              itemBuilder: (context, index) {
                                final phrase = availablePhrases[index];
                                return Draggable<String>(
                                  data: phrase,
                                  feedback: Material(
                                    color: Colors.transparent,
                                    child: ConstrainedBox(
                                      constraints: const BoxConstraints(
                                        maxWidth: 260,
                                      ),
                                      child: Chip(
                                        label: UpperText(phrase, maxLines: 3),
                                      ),
                                    ),
                                  ),
                                  childWhenDragging: Opacity(
                                    opacity: 0.35,
                                    child: Chip(
                                      label: UpperText(phrase, maxLines: 2),
                                    ),
                                  ),
                                  child: Chip(
                                    label: UpperText(phrase, maxLines: 2),
                                  ),
                                );
                              },
                            );
                          }
                          return Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: availablePhrases
                                .map(
                                  (phrase) => Draggable<String>(
                                    data: phrase,
                                    feedback: Material(
                                      color: Colors.transparent,
                                      child: ConstrainedBox(
                                        constraints: const BoxConstraints(
                                          maxWidth: 220,
                                        ),
                                        child: Chip(
                                          label: UpperText(phrase, maxLines: 3),
                                        ),
                                      ),
                                    ),
                                    childWhenDragging: Opacity(
                                      opacity: 0.35,
                                      child: ConstrainedBox(
                                        constraints: const BoxConstraints(
                                          maxWidth: 220,
                                        ),
                                        child: Chip(
                                          label: UpperText(phrase, maxLines: 3),
                                        ),
                                      ),
                                    ),
                                    child: ConstrainedBox(
                                      constraints: const BoxConstraints(
                                        maxWidth: 220,
                                      ),
                                      child: Chip(
                                        label: UpperText(phrase, maxLines: 3),
                                      ),
                                    ),
                                  ),
                                )
                                .toList(),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ),
    );
  }
}
