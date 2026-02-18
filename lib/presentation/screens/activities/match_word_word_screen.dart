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
  List<String> _leftWords = [];
  List<String> _rightWords = [];

  final Set<String> _matchedLeft = {};
  final Set<String> _matchedRight = {};

  PairMode _mode = PairMode.iguales;
  String? _selectedLeft;
  String _feedback = 'SELECCIONA UNA PALABRA DE CADA COLUMNA';
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
    final limit = widget.difficulty == Difficulty.primaria ? 6 : 8;

    final pairs = dataset.getPrioritizedItems(
      category: widget.category,
      level: AppLevel.dos,
      activityType: ActivityType.palabraPalabra,
      difficulty: widget.difficulty,
      progressMap: progressMap,
      limit: limit,
    );

    final selectedPairs = pairs.isNotEmpty
        ? pairs
        : dataset.getItems(
            category: widget.category,
            level: AppLevel.dos,
            activityType: ActivityType.palabraPalabra,
          );

    if (!mounted) {
      return;
    }

    setState(() {
      _pairs = selectedPairs;
      _mode = PairMode.iguales;
      _correct = 0;
      _incorrect = 0;
      _streak = 0;
      _bestStreak = 0;
      _startedAt = DateTime.now();
      _feedback = 'SELECCIONA UNA PALABRA DE CADA COLUMNA';
      _isLoading = false;
    });
    _rebuildColumns();
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

    if (pair.id.isNotEmpty) {
      await ref
          .read(progressViewModelProvider.notifier)
          .registerAttempt(itemId: pair.id, correct: isCorrect);
    }

    if (!mounted) {
      return;
    }

    setState(() {
      if (isCorrect) {
        _matchedLeft.add(leftWord);
        _matchedRight.add(rightWord);
        _correct++;
        _streak++;
        _bestStreak = max(_bestStreak, _streak);
        _feedback = 'CORRECTO';
      } else {
        _incorrect++;
        _streak = 0;
        _feedback = 'INTÉNTALO DE NUEVO';
      }
      _selectedLeft = null;
    });

    if (_matchedLeft.length == _leftWords.length && _leftWords.isNotEmpty) {
      await _finishActivity();
    }
  }

  Future<void> _finishActivity() async {
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
    return Scaffold(
      appBar: AppBar(
        title: const UpperText('RELACIONAR PALABRAS CON PALABRAS'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _pairs.isEmpty
          ? const Center(child: UpperText('NO HAY CONTENIDO DISPONIBLE'))
          : Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  SegmentedButton<PairMode>(
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
                  const SizedBox(height: 10),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Row(
                        children: [
                          const Icon(Icons.sync_alt),
                          const SizedBox(width: 10),
                          Expanded(child: UpperText(_feedback)),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Expanded(
                    child: Row(
                      children: [
                        Expanded(
                          child: _WordColumn(
                            title: 'COLUMNA A',
                            words: _leftWords,
                            selected: _selectedLeft,
                            matched: _matchedLeft,
                            onTap: (word) {
                              if (_matchedLeft.contains(word)) {
                                return;
                              }
                              setState(() {
                                _selectedLeft = word;
                                _feedback = 'AHORA ELIGE EN COLUMNA B';
                              });
                            },
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _WordColumn(
                            title: 'COLUMNA B',
                            words: _rightWords,
                            selected: null,
                            matched: _matchedRight,
                            onTap: (word) => _tryMatch(word),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
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
    required this.onTap,
  });

  final String title;
  final List<String> words;
  final String? selected;
  final Set<String> matched;
  final ValueChanged<String> onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Column(
          children: [
            UpperText(title, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            Expanded(
              child: ListView.separated(
                itemCount: words.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (context, index) {
                  final word = words[index];
                  final isMatched = matched.contains(word);
                  final isSelected = selected == word;

                  return FilledButton.tonal(
                    onPressed: isMatched ? null : () => onTap(word),
                    style: FilledButton.styleFrom(
                      backgroundColor: isMatched
                          ? Colors.green.shade100
                          : (isSelected ? Colors.blue.shade100 : null),
                      side: BorderSide(
                        color: isSelected
                            ? Colors.blue.shade700
                            : Colors.transparent,
                      ),
                    ),
                    child: Row(
                      children: [
                        if (isMatched) const Icon(Icons.check, size: 18),
                        if (isMatched) const SizedBox(width: 6),
                        Expanded(
                          child: UpperText(word, textAlign: TextAlign.center),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
