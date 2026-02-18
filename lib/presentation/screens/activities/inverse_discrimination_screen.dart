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
import '../../widgets/upper_text.dart';
import '../results_screen.dart';

class InverseDiscriminationScreen extends ConsumerStatefulWidget {
  const InverseDiscriminationScreen({
    super.key,
    required this.category,
    required this.difficulty,
    required this.level,
  });

  final AppCategory category;
  final Difficulty difficulty;
  final AppLevel level;

  @override
  ConsumerState<InverseDiscriminationScreen> createState() =>
      _InverseDiscriminationScreenState();
}

class _InverseDiscriminationScreenState
    extends ConsumerState<InverseDiscriminationScreen> {
  final Random _random = Random();

  final Map<AppCategory, List<Item>> _poolByCategory = {};
  AppCategory _focusCategory = AppCategory.cosasDeCasa;

  int _currentRound = 0;
  int _roundCount = 5;
  bool _isLoading = true;
  bool _answered = false;
  String _feedback = 'TOCA LA QUE NO PERTENECE';

  List<Item> _options = [];
  Item? _odd;
  String? _selectedId;

  int _correct = 0;
  int _incorrect = 0;
  int _streak = 0;
  int _bestStreak = 0;
  DateTime _startedAt = DateTime.now();

  int get _optionsCount {
    return switch (widget.level) {
      AppLevel.uno => widget.difficulty == Difficulty.primaria ? 3 : 4,
      AppLevel.dos => widget.difficulty == Difficulty.primaria ? 4 : 5,
      _ => widget.difficulty == Difficulty.primaria ? 4 : 6,
    };
  }

  @override
  void initState() {
    super.initState();
    _prepare();
  }

  Future<void> _prepare() async {
    final dataset = ref.read(datasetRepositoryProvider);
    final all = dataset.getAllItems();
    _poolByCategory.clear();
    for (final category in AppCategoryLists.reales) {
      final items = all
          .where(
            (item) =>
                item.category == category &&
                item.activityType == ActivityType.imagenPalabra &&
                (item.word ?? '').isNotEmpty,
          )
          .toList()
        ..shuffle(_random);
      _poolByCategory[category] = items;
    }

    _roundCount = switch (widget.level) {
      AppLevel.uno => 4,
      AppLevel.dos => 5,
      _ => 6,
    };

    if (!mounted) {
      return;
    }

    setState(() {
      _isLoading = false;
      _currentRound = 0;
      _correct = 0;
      _incorrect = 0;
      _streak = 0;
      _bestStreak = 0;
      _feedback = 'TOCA LA QUE NO PERTENECE';
      _startedAt = DateTime.now();
    });

    _prepareRound();
  }

  void _prepareRound() {
    if (_currentRound >= _roundCount) {
      _finish();
      return;
    }

    final focusCategory = widget.category == AppCategory.mixta
        ? _randomAvailableCategory()
        : widget.category;
    _focusCategory = focusCategory;

    final insidePool = List<Item>.from(_poolByCategory[focusCategory] ?? const []);
    final outsidePool = _poolByCategory.entries
        .where((entry) => entry.key != focusCategory)
        .expand((entry) => entry.value)
        .toList();

    if (insidePool.length < _optionsCount - 1 || outsidePool.isEmpty) {
      _finish();
      return;
    }

    final odd = outsidePool[_random.nextInt(outsidePool.length)];
    final insiders = insidePool..shuffle(_random);
    final options = <Item>[odd, ...insiders.take(_optionsCount - 1)]..shuffle(_random);

    setState(() {
      _odd = odd;
      _options = options;
      _selectedId = null;
      _answered = false;
      _feedback = 'TOCA LA QUE NO ES DE ${focusCategory.label}';
    });
  }

  AppCategory _randomAvailableCategory() {
    final candidates = AppCategoryLists.reales.where((category) {
      final ownSize = (_poolByCategory[category] ?? const []).length;
      final otherSize = _poolByCategory.entries
          .where((entry) => entry.key != category)
          .fold<int>(0, (sum, entry) => sum + entry.value.length);
      return ownSize >= _optionsCount - 1 && otherSize >= 1;
    }).toList();

    if (candidates.isEmpty) {
      return AppCategory.cosasDeCasa;
    }
    return candidates[_random.nextInt(candidates.length)];
  }

  Future<void> _answer(Item selected) async {
    if (_answered || _odd == null) {
      return;
    }

    final isCorrect = selected.id == _odd!.id;

    await ref.read(progressViewModelProvider.notifier).registerAttempt(
      itemId: _odd!.id,
      correct: isCorrect,
      activityType: ActivityType.discriminacionInversa,
    );

    if (!mounted) {
      return;
    }

    setState(() {
      _answered = true;
      _selectedId = selected.id;
      if (isCorrect) {
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
          hint: 'BUSCA LA QUE NO ES DE ${_focusCategory.label}',
        );
      }
    });
  }

  void _nextRound() {
    if (!_answered) {
      return;
    }
    setState(() {
      _currentRound++;
    });
    _prepareRound();
  }

  Future<void> _finish() async {
    final result = ActivityResult(
      id: 'RES-${DateTime.now().millisecondsSinceEpoch}',
      category: widget.category,
      level: widget.level,
      activityType: ActivityType.discriminacionInversa,
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
      setState(() {
        _isLoading = true;
      });
      await _prepare();
    } else {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final crossAxisCount = width < 760
        ? 2
        : width < 1100
        ? 3
        : 4;

    return Scaffold(
      appBar: AppBar(title: const UpperText('DISCRIMINACIÓN INVERSA')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _odd == null
          ? const Center(child: UpperText('NO HAY CONTENIDO DISPONIBLE'))
          : Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1160),
                child: ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(14),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            UpperText('RONDA ${_currentRound + 1} DE $_roundCount'),
                            const SizedBox(height: 8),
                            UpperText(
                              _feedback,
                              style: Theme.of(context).textTheme.titleLarge,
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: crossAxisCount,
                        crossAxisSpacing: 10,
                        mainAxisSpacing: 10,
                        mainAxisExtent: 200,
                      ),
                      itemCount: _options.length,
                      itemBuilder: (context, index) {
                        final option = _options[index];
                        final isSelected = _selectedId == option.id;
                        final isOdd = _odd!.id == option.id;
                        final showGood = _answered && isOdd;
                        final showBad = _answered && isSelected && !isOdd;

                        return InkWell(
                          onTap: _answered ? null : () => _answer(option),
                          borderRadius: BorderRadius.circular(14),
                          child: Ink(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: showGood
                                    ? Colors.green.shade700
                                    : showBad
                                    ? Colors.red.shade700
                                    : Theme.of(context).colorScheme.outline,
                                width: showGood || showBad ? 3 : 1.4,
                              ),
                              color: showGood
                                  ? Colors.green.shade50
                                  : showBad
                                  ? Colors.red.shade50
                                  : Theme.of(context).colorScheme.surface,
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(10),
                              child: Column(
                                children: [
                                  Expanded(
                                    child: ActivityAssetImage(
                                      assetPath: option.imageAsset,
                                      semanticsLabel: option.word,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  UpperText(
                                    option.word ?? '',
                                    textAlign: TextAlign.center,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 14),
                    FilledButton.icon(
                      onPressed: _answered ? _nextRound : null,
                      icon: const Icon(Icons.navigate_next_rounded),
                      label: UpperText(
                        _currentRound + 1 >= _roundCount
                            ? 'VER RESULTADOS'
                            : 'SIGUIENTE',
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
