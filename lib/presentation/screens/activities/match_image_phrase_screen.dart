import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../application/providers/app_providers.dart';
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
  List<String> _phrases = [];
  final Map<String, String> _matchedByItem = {};

  bool _isLoading = true;
  String _feedback = 'UNE CADA FRASE CON SU IMAGEN';

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
      level: AppLevel.tres,
      activityType: ActivityType.imagenFrase,
      difficulty: widget.difficulty,
      progressMap: progressMap,
      limit: limit,
    );

    final selectedItems = items.isNotEmpty
        ? items
        : dataset.getItems(
            category: widget.category,
            level: AppLevel.tres,
            activityType: ActivityType.imagenFrase,
          );

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
      _feedback = 'UNE CADA FRASE CON SU IMAGEN';
      _correct = 0;
      _incorrect = 0;
      _streak = 0;
      _bestStreak = 0;
      _startedAt = DateTime.now();
      _isLoading = false;
    });
  }

  Future<void> _handleDrop(Item item, String phrase) async {
    if (_matchedByItem.containsKey(item.id)) {
      return;
    }

    final expected = _expectedPhraseByItem[item.id] ?? '';
    final isCorrect = phrase == expected;

    await ref
        .read(progressViewModelProvider.notifier)
        .registerAttempt(itemId: item.id, correct: isCorrect);

    if (!mounted) {
      return;
    }

    setState(() {
      if (isCorrect) {
        _matchedByItem[item.id] = phrase;
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
      appBar: AppBar(title: const UpperText('RELACIONAR FRASES CON IMÁGENES')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _items.isEmpty
          ? const Center(child: UpperText('NO HAY CONTENIDO DISPONIBLE'))
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
                            crossAxisSpacing: 10,
                            mainAxisSpacing: 10,
                            childAspectRatio: 0.9,
                          ),
                      itemCount: _items.length,
                      itemBuilder: (context, index) {
                        final item = _items[index];
                        final matched = _matchedByItem[item.id];
                        final expected = _expectedPhraseByItem[item.id] ?? '';

                        return Card(
                          child: Padding(
                            padding: const EdgeInsets.all(10),
                            child: Column(
                              children: [
                                Expanded(
                                  child: ActivityAssetImage(
                                    assetPath: item.imageAsset,
                                    semanticsLabel: expected,
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
                                      border: Border.all(
                                        color: Colors.green.shade700,
                                      ),
                                    ),
                                    child: UpperText(
                                      matched,
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
                                            padding: const EdgeInsets.all(8),
                                            decoration: BoxDecoration(
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                              border: Border.all(
                                                width: 2,
                                                color: candidateData.isNotEmpty
                                                    ? Theme.of(
                                                        context,
                                                      ).colorScheme.primary
                                                    : Theme.of(
                                                        context,
                                                      ).colorScheme.outline,
                                              ),
                                            ),
                                            child: const UpperText(
                                              'SUELTA AQUÍ',
                                              textAlign: TextAlign.center,
                                            ),
                                          );
                                        },
                                  ),
                                if (settings.showHints && matched == null)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 6),
                                    child: UpperText(
                                      'PISTA: ${countWords(expected)} PALABRAS',
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
                      'FRASES DISPONIBLES',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _phrases
                        .where(
                          (phrase) => !_matchedByItem.values.contains(phrase),
                        )
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
                              constraints: const BoxConstraints(maxWidth: 220),
                              child: Chip(
                                label: UpperText(phrase, maxLines: 3),
                              ),
                            ),
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
