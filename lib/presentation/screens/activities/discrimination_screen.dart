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
import '../../widgets/routine_steps.dart';
import '../../widgets/upper_text.dart';
import '../results_screen.dart';

class DiscriminationScreen extends ConsumerStatefulWidget {
  const DiscriminationScreen({
    super.key,
    required this.category,
    required this.difficulty,
    required this.level,
  });

  final AppCategory category;
  final Difficulty difficulty;
  final AppLevel level;

  @override
  ConsumerState<DiscriminationScreen> createState() =>
      _DiscriminationScreenState();
}

class _DiscriminationScreenState extends ConsumerState<DiscriminationScreen> {
  final Random _random = Random();

  List<Item> _pool = [];
  late List<Item> _roundTargets;

  int _currentRound = 0;
  bool _isLoading = true;
  bool _answered = false;
  String _feedback = 'TOCA LA IMAGEN CORRECTA';

  Item? _target;
  List<Item> _options = [];
  String? _selectedId;

  int _correct = 0;
  int _incorrect = 0;
  int _streak = 0;
  int _bestStreak = 0;
  int _consecutiveErrors = 0;
  DateTime _startedAt = DateTime.now();

  @override
  void initState() {
    super.initState();
    _roundTargets = [];
    _prepare();
  }

  int get _optionsCount {
    return switch (widget.level) {
      AppLevel.uno => widget.difficulty == Difficulty.primaria ? 2 : 3,
      AppLevel.dos => widget.difficulty == Difficulty.primaria ? 3 : 4,
      _ => widget.difficulty == Difficulty.primaria ? 4 : 6,
    };
  }

  int get _roundCount {
    return switch (widget.level) {
      AppLevel.uno => 4,
      AppLevel.dos => 5,
      _ => 6,
    };
  }

  Future<void> _prepare() async {
    final dataset = ref.read(datasetRepositoryProvider);
    final progressMap = ref.read(itemProgressMapProvider);
    final source = dataset.getPrioritizedItems(
      category: widget.category,
      level: AppLevel.uno,
      activityType: ActivityType.imagenPalabra,
      difficulty: widget.difficulty,
      progressMap: progressMap,
      limit: 36,
    );

    final fallback = dataset.getItems(
      category: widget.category,
      level: AppLevel.uno,
      activityType: ActivityType.imagenPalabra,
    );

    _pool = (source.isNotEmpty ? source : fallback)
        .where((item) => (item.word ?? '').isNotEmpty)
        .toList();

    _pool.shuffle(_random);
    _roundTargets = _pool.take(min(_roundCount, _pool.length)).toList();

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
      _consecutiveErrors = 0;
      _feedback = 'TOCA LA IMAGEN CORRECTA';
      _startedAt = DateTime.now();
    });

    _prepareRound();
  }

  void _prepareRound() {
    if (_currentRound >= _roundTargets.length) {
      _finish();
      return;
    }

    final target = _roundTargets[_currentRound];
    final distractors = _pool.where((item) => item.id != target.id).toList()
      ..shuffle(_random);

    final options = <Item>[target, ...distractors.take(_optionsCount - 1)]
      ..shuffle(_random);

    setState(() {
      _target = target;
      _options = options;
      _selectedId = null;
      _answered = false;
      _feedback = 'TOCA LA IMAGEN DE: ${target.word ?? ''}';
    });
  }

  Future<void> _answer(Item selected) async {
    if (_answered || _target == null) {
      return;
    }

    final isCorrect = selected.id == _target!.id;

    await ref.read(progressViewModelProvider.notifier).registerAttempt(
      itemId: _target!.id,
      correct: isCorrect,
      activityType: ActivityType.discriminacion,
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
        _consecutiveErrors = 0;
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
          hint: _target?.word,
        );
        _consecutiveErrors++;
      }
    });
  }

  Future<void> _nextRound() async {
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
      activityType: ActivityType.discriminacion,
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
      appBar: AppBar(title: const UpperText('DISCRIMINACIÓN VISUAL')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _target == null
          ? const Center(child: UpperText('NO HAY CONTENIDO DISPONIBLE'))
          : Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1160),
                child: ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    RoutineSteps(currentStep: _answered ? 4 : 2),
                    const SizedBox(height: 10),
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(14),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            UpperText(
                              'RONDA ${_currentRound + 1} DE ${_roundTargets.length}',
                            ),
                            const SizedBox(height: 8),
                            UpperText(
                              _feedback,
                              style: Theme.of(context).textTheme.titleLarge,
                            ),
                          ],
                        ),
                      ),
                    ),
                    if (!_answered && _consecutiveErrors >= 2) ...[
                      const SizedBox(height: 10),
                      Card(
                        color: Colors.amber.shade50,
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Row(
                            children: [
                              Icon(
                                Icons.lightbulb_rounded,
                                color: Colors.amber.shade800,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: UpperText(
                                  'AYUDA: TOCA ${_target?.word ?? ''}',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
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
                        final isCorrectOption = _target!.id == option.id;
                        final showGood = _answered && isCorrectOption;
                        final showBad =
                            _answered && isSelected && !isCorrectOption;
                        final showAssist =
                            !_answered &&
                            _consecutiveErrors >= 2 &&
                            isCorrectOption;

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
                                    : showAssist
                                    ? Colors.blue.shade700
                                    : Theme.of(context).colorScheme.outline,
                                width: showGood || showBad || showAssist
                                    ? 3
                                    : 1.4,
                              ),
                              color: showGood
                                  ? Colors.green.shade50
                                  : showBad
                                  ? Colors.red.shade50
                                  : showAssist
                                  ? Colors.blue.shade50
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
                        _currentRound + 1 >= _roundTargets.length
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
