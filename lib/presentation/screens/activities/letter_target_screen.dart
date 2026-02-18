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
import '../../widgets/activity_asset_image.dart';
import '../../widgets/upper_text.dart';
import '../results_screen.dart';

class LetterTargetScreen extends ConsumerStatefulWidget {
  const LetterTargetScreen({
    super.key,
    required this.category,
    required this.difficulty,
    required this.level,
  });

  final AppCategory category;
  final Difficulty difficulty;
  final AppLevel level;

  @override
  ConsumerState<LetterTargetScreen> createState() => _LetterTargetScreenState();
}

class _LetterTargetScreenState extends ConsumerState<LetterTargetScreen> {
  final Random _random = Random();

  List<Item> _items = [];
  final Map<String, bool> _classifiedByItem = {};
  String _targetLetter = 'A';
  String _feedback = 'ARRASTRA CADA TARJETA A SU CAJA';
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
      _ => ['A', 'E', 'I', 'O', 'U', 'L', 'M', 'N', 'P', 'R', 'S', 'T', 'C', 'D', 'B'],
    };

    String selectedLetter = candidateLetters.first;
    List<Item> positives = [];
    List<Item> negatives = [];

    for (final letter in candidateLetters) {
      final withLetter = candidatesPool
          .where((item) => containsLetter(item.word ?? '', letter))
          .toList();
      final withoutLetter = candidatesPool
          .where((item) => !containsLetter(item.word ?? '', letter))
          .toList();

      if (withLetter.length >= half && withoutLetter.length >= half) {
        selectedLetter = letter;
        positives = withLetter;
        negatives = withoutLetter;
        break;
      }
    }

    if (positives.isEmpty || negatives.isEmpty) {
      selectedLetter = 'A';
      positives = candidatesPool
          .where((item) => containsLetter(item.word ?? '', selectedLetter))
          .toList();
      negatives = candidatesPool
          .where((item) => !containsLetter(item.word ?? '', selectedLetter))
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
      _feedback = 'ARRASTRA CADA TARJETA A SU CAJA';
      _correct = 0;
      _incorrect = 0;
      _streak = 0;
      _bestStreak = 0;
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
        .registerAttempt(itemId: item.id, correct: isCorrect);

    if (!mounted) {
      return;
    }

    setState(() {
      if (isCorrect) {
        _classifiedByItem[item.id] = toHasLetter;
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

  Widget _buildDropZone({
    required BuildContext context,
    required String title,
    required bool toHasLetter,
    required List<Item> accepted,
  }) {
    return DragTarget<Item>(
      onWillAcceptWithDetails: (details) =>
          details.data.word != null && !_classifiedByItem.containsKey(details.data.id),
      onAcceptWithDetails: (details) {
        _handleDrop(details.data, toHasLetter: toHasLetter);
      },
      builder: (context, candidateData, rejectedData) {
        final hovering = candidateData.isNotEmpty;
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
              UpperText(
                title,
                style: Theme.of(context).textTheme.titleLarge,
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

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final isMobile = width < 900;

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

    return Scaffold(
      appBar: AppBar(title: const UpperText('NIVEL LETRAS Y VOCALES')),
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
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            UpperText(
                              switch (widget.level) {
                                AppLevel.uno =>
                                  'NIVEL 1: BUSCA VOCALES EN PALABRAS CORTAS CON LA LETRA $_targetLetter',
                                AppLevel.dos =>
                                  'NIVEL 2: BUSCA LETRAS FRECUENTES EN PALABRAS MEDIAS CON LA LETRA $_targetLetter',
                                _ =>
                                  'NIVEL 3: BUSCA LETRAS EN PALABRAS LARGAS CON LA LETRA $_targetLetter',
                              },
                              style: Theme.of(context).textTheme.titleLarge,
                            ),
                            const SizedBox(height: 8),
                            UpperText(_feedback),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    if (isMobile)
                      Column(
                        children: [
                          _buildDropZone(
                            context: context,
                            title: 'TIENE LA LETRA $_targetLetter',
                            toHasLetter: true,
                            accepted: withLetter,
                          ),
                          const SizedBox(height: 10),
                          _buildDropZone(
                            context: context,
                            title: 'NO TIENE LA LETRA $_targetLetter',
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
                              title: 'TIENE LA LETRA $_targetLetter',
                              toHasLetter: true,
                              accepted: withLetter,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _buildDropZone(
                              context: context,
                              title: 'NO TIENE LA LETRA $_targetLetter',
                              toHasLetter: false,
                              accepted: withoutLetter,
                            ),
                          ),
                        ],
                      ),
                    const SizedBox(height: 14),
                    UpperText(
                      isMobile ? 'TARJETA ACTUAL' : 'TARJETAS',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 8),
                    if (isMobile)
                      Column(
                        children: [
                          if (nextItem != null)
                            Draggable<Item>(
                              data: nextItem,
                              feedback: Material(
                                color: Colors.transparent,
                                child: SizedBox(
                                  width: 220,
                                  child: _LetterCard(item: nextItem, mobileLarge: true),
                                ),
                              ),
                              childWhenDragging: Opacity(
                                opacity: 0.3,
                                child: _LetterCard(item: nextItem, mobileLarge: true),
                              ),
                              child: _LetterCard(item: nextItem, mobileLarge: true),
                            )
                          else
                            const UpperText('NO QUEDAN TARJETAS'),
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
                                          child: ActivityAssetImage(assetPath: item.imageAsset),
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
                              child: _LetterCard(item: item),
                            ),
                            child: _LetterCard(item: item),
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
  const _LetterCard({required this.item, this.mobileLarge = false});

  final Item item;
  final bool mobileLarge;

  @override
  Widget build(BuildContext context) {
    final cardWidth = mobileLarge
        ? min(MediaQuery.sizeOf(context).width - 40, 280.0)
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
                height: mobileLarge ? 120 : 88,
                child: ActivityAssetImage(
                  assetPath: item.imageAsset,
                  semanticsLabel: item.word,
                ),
              ),
              const SizedBox(height: 6),
              UpperText(
                item.word ?? '',
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
