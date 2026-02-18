import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../application/providers/app_providers.dart';
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
        .registerAttempt(itemId: item.id, correct: isCorrect);

    if (!mounted) {
      return;
    }

    setState(() {
      if (isCorrect) {
        _matchedByItem[item.id] = droppedWord;
        _correct++;
        _streak++;
        _bestStreak = max(_bestStreak, _streak);
        _feedback = 'CORRECTO';
      } else {
        _incorrect++;
        _streak = 0;
        _feedback = 'INTÉNTALO DE NUEVO';
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

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(settingsViewModelProvider);

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
          : Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
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
                  Expanded(
                    child: GridView.builder(
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            mainAxisSpacing: 10,
                            crossAxisSpacing: 10,
                            childAspectRatio: 0.92,
                          ),
                      itemCount: _items.length,
                      itemBuilder: (context, index) {
                        final item = _items[index];
                        final matchedWord = _matchedByItem[item.id];

                        return Card(
                          child: Padding(
                            padding: const EdgeInsets.all(10),
                            child: Column(
                              children: [
                                Expanded(
                                  child: matchedWord != null
                                      ? ActivityAssetImage(
                                          assetPath: item.imageAsset,
                                          semanticsLabel: item.word,
                                        )
                                      : DragTarget<String>(
                                          onWillAcceptWithDetails: (details) {
                                            return details.data.isNotEmpty;
                                          },
                                          onAcceptWithDetails: (details) {
                                            _handleDrop(item, details.data);
                                          },
                                          builder: (context, candidateData, rejected) {
                                            final isHovering =
                                                candidateData.isNotEmpty;
                                            return Stack(
                                              fit: StackFit.expand,
                                              children: [
                                                ActivityAssetImage(
                                                  assetPath: item.imageAsset,
                                                  semanticsLabel: item.word,
                                                ),
                                                AnimatedContainer(
                                                  duration: const Duration(
                                                    milliseconds: 140,
                                                  ),
                                                  decoration: BoxDecoration(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          12,
                                                        ),
                                                    border: Border.all(
                                                      color: isHovering
                                                          ? Theme.of(context)
                                                                .colorScheme
                                                                .primary
                                                          : Colors.transparent,
                                                      width: 3,
                                                    ),
                                                    color: isHovering
                                                        ? Theme.of(context)
                                                              .colorScheme
                                                              .primary
                                                              .withValues(
                                                                alpha: 0.08,
                                                              )
                                                        : Colors.transparent,
                                                  ),
                                                ),
                                                if (isHovering)
                                                  Align(
                                                    alignment:
                                                        Alignment.topCenter,
                                                    child: Container(
                                                      margin:
                                                          const EdgeInsets.only(
                                                            top: 8,
                                                          ),
                                                      padding:
                                                          const EdgeInsets.symmetric(
                                                            horizontal: 8,
                                                            vertical: 4,
                                                          ),
                                                      decoration: BoxDecoration(
                                                        color: Theme.of(
                                                          context,
                                                        ).colorScheme.primary,
                                                        borderRadius:
                                                            BorderRadius.circular(
                                                              8,
                                                            ),
                                                      ),
                                                      child: UpperText(
                                                        'SUELTA EN LA IMAGEN',
                                                        style: Theme.of(context)
                                                            .textTheme
                                                            .bodySmall
                                                            ?.copyWith(
                                                              color:
                                                                  Theme.of(
                                                                        context,
                                                                      )
                                                                      .colorScheme
                                                                      .onPrimary,
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
                                      border: Border.all(
                                        color: Colors.green.shade600,
                                      ),
                                    ),
                                    child: UpperText(
                                      matchedWord,
                                      textAlign: TextAlign.center,
                                    ),
                                  )
                                else
                                  DragTarget<String>(
                                    onWillAcceptWithDetails: (details) {
                                      return details.data.isNotEmpty;
                                    },
                                    onAcceptWithDetails: (details) {
                                      _handleDrop(item, details.data);
                                    },
                                    builder:
                                        (context, candidateData, rejected) {
                                          return Container(
                                            width: double.infinity,
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 8,
                                              vertical: 10,
                                            ),
                                            decoration: BoxDecoration(
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                              border: Border.all(
                                                color: candidateData.isNotEmpty
                                                    ? Theme.of(
                                                        context,
                                                      ).colorScheme.primary
                                                    : Theme.of(
                                                        context,
                                                      ).colorScheme.outline,
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
                                if (settings.showHints && matchedWord == null)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 6),
                                    child: UpperText(
                                      'PISTA: ${item.word?.substring(0, 1) ?? ''}...',
                                      style: Theme.of(
                                        context,
                                      ).textTheme.bodySmall,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 10),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: UpperText(
                      'PALABRAS DISPONIBLES',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _words
                        .where((word) => !_matchedByItem.values.contains(word))
                        .map(
                          (word) => Draggable<String>(
                            data: word,
                            feedback: Material(
                              color: Colors.transparent,
                              child: Chip(label: UpperText(word)),
                            ),
                            childWhenDragging: Opacity(
                              opacity: 0.35,
                              child: Chip(label: UpperText(word)),
                            ),
                            child: Chip(label: UpperText(word)),
                          ),
                        )
                        .toList(),
                  ),
                ],
              ),
            ),
    );
  }
}
