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
  final Set<String> _errorHighlightItemIds = {};

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
      _errorHighlightItemIds.clear();
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
        _errorHighlightItemIds.remove(item.id);
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
        _errorHighlightItemIds.add(item.id);
        _feedback = PedagogicalFeedback.retry(
          attemptsOnCurrent: attemptsOnCurrent,
          hint: 'LEE DESPACIO LA FRASE',
        );
      }
    });

    if (!isCorrect) {
      await Future<void>.delayed(const Duration(seconds: 1));
      if (!mounted) {
        return;
      }
      setState(() {
        _errorHighlightItemIds.remove(item.id);
      });
    }

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
    final imageZoom = compactDesktop ? 1.2 : 1.0;
    final hasErrorFlash = _errorHighlightItemIds.contains(item.id);

    Widget buildCard(bool isHovering) {
      final imageCardBorder = matched != null
          ? const Color(0xFF7FD39A)
          : hasErrorFlash
          ? const Color(0xFFF06A6A)
          : isHovering
          ? const Color(0xFF8DBEFF)
          : const Color(0xFFE3E8F1);
      final imageCardFill = matched != null
          ? const Color(0xFFEAF9EF)
          : hasErrorFlash
          ? const Color(0xFFFFEFEF)
          : const Color(0xFFF5F7FA);

      return Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(30),
          border: Border.all(color: const Color(0xFFE6EBF3), width: 1.8),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 140),
              height: imageHeight,
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: imageCardFill,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: imageCardBorder,
                  width: matched != null || hasErrorFlash || isHovering
                      ? 2.8
                      : 1.4,
                ),
              ),
              child: Transform.scale(
                scale: imageZoom,
                child: ActivityAssetImage(
                  assetPath: item.imageAsset,
                  semanticsLabel: expected,
                ),
              ),
            ),
            const SizedBox(height: 10),
            if (matched != null)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(999),
                  color: const Color(0xFFEAF9EF),
                  border: Border.all(color: const Color(0xFF7FD39A), width: 2),
                ),
                child: UpperText(
                  matched,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF1B6C3F),
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
                  color: hasErrorFlash
                      ? const Color(0xFFFFEAEA)
                      : isHovering
                      ? const Color(0xFFEAF3FF)
                      : const Color(0xFFF8FAFD),
                  border: Border.all(
                    color: hasErrorFlash
                        ? const Color(0xFFF06A6A)
                        : isHovering
                        ? const Color(0xFF8DBEFF)
                        : const Color(0xFFD9E1EE),
                    width: hasErrorFlash || isHovering ? 2.8 : 2,
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
            if (showHints && matched == null)
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: UpperText(
                  'PISTA: ${countWords(expected)} PALABRAS',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF5B6A87),
                  ),
                ),
              ),
          ],
        ),
      );
    }

    if (matched != null) {
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

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(settingsViewModelProvider);
    final width = MediaQuery.sizeOf(context).width;
    final isTabletLandscapePrimary = isPrimaryTabletLandscape(context);
    final isMobile = width < 900;
    final isTablet = width >= 700 && width < 1200;
    final isDesktop = width >= 1000;
    final contentWidth = isDesktop ? 1280.0 : 980.0;
    final crossAxisCount = isMobile
        ? 1
        : isTablet
        ? 2
        : width >= 1450
        ? 4
        : 3;
    final imageHeight = isTabletLandscapePrimary
        ? 170.0
        : isDesktop
        ? 185.0
        : 194.0;
    final gridItemExtent = isTabletLandscapePrimary
        ? 306.0
        : isDesktop
        ? 324.0
        : 334.0;
    final solvedCount = _matchedByItem.length;

    return GameScaffold(
      title: 'RELACIONAR FRASES CON IMÁGENES',
      instructionText: 'ARRASTRA LA FRASE HASTA LA IMAGEN CORRECTA',
      progressCurrent: solvedCount,
      progressTotal: _items.length,
      enableDesktopShell: false,
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
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(color: const Color(0xFFD8E1EE)),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.info_outline,
                              color: Color(0xFF5B6A87),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: UpperText(
                                _feedback,
                                style: const TextStyle(
                                  color: Color(0xFF2B3552),
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
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

                          return Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 16,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFEFF4FB),
                              borderRadius: BorderRadius.circular(28),
                              border: Border.all(
                                color: const Color(0xFFBFD6F6),
                                width: 2,
                              ),
                            ),
                            child: Wrap(
                              alignment: WrapAlignment.center,
                              spacing: 12,
                              runSpacing: 12,
                              children: availablePhrases.map((phrase) {
                                return Draggable<String>(
                                  data: phrase,
                                  affinity: Axis.vertical,
                                  maxSimultaneousDrags: 1,
                                  dragAnchorStrategy: pointerDragAnchorStrategy,
                                  feedback: Material(
                                    color: Colors.transparent,
                                    child: ConstrainedBox(
                                      constraints: const BoxConstraints(
                                        maxWidth: 280,
                                      ),
                                      child: Chip(
                                        label: UpperText(phrase, maxLines: 2),
                                      ),
                                    ),
                                  ),
                                  childWhenDragging: Opacity(
                                    opacity: 0.35,
                                    child: ConstrainedBox(
                                      constraints: const BoxConstraints(
                                        maxWidth: 280,
                                      ),
                                      child: Chip(
                                        label: UpperText(phrase, maxLines: 2),
                                      ),
                                    ),
                                  ),
                                  child: ConstrainedBox(
                                    constraints: const BoxConstraints(
                                      maxWidth: 280,
                                    ),
                                    child: Chip(
                                      label: UpperText(phrase, maxLines: 2),
                                    ),
                                  ),
                                );
                              }).toList(),
                            ),
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
