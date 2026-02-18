import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/providers/app_providers.dart';
import '../../core/utils/text_utils.dart';
import '../../domain/models/activity_result.dart';
import '../../domain/models/activity_type.dart';
import '../../domain/models/category.dart';
import '../../domain/models/item.dart';
import '../../domain/models/item_progress.dart';
import '../viewmodels/progress_view_model.dart';
import '../widgets/upper_text.dart';

class ProgressDashboardScreen extends ConsumerWidget {
  const ProgressDashboardScreen({
    super.key,
    required this.category,
  });

  final AppCategory category;

  static const _trackedGames = [
    ActivityType.imagenPalabra,
    ActivityType.escribirPalabra,
    ActivityType.palabraPalabra,
    ActivityType.imagenFrase,
    ActivityType.letraObjetivo,
    ActivityType.discriminacion,
    ActivityType.discriminacionInversa,
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(progressViewModelProvider);

    final results = ref.read(progressViewModelProvider.notifier).getAllResults();
    final gameItemProgress = ref.watch(gameItemProgressMapProvider);
    final dataset = ref.read(datasetRepositoryProvider);
    final allItems = dataset.getAllItems();

    final filteredResults = category == AppCategory.mixta
        ? results
        : results.where((result) => result.category == category).toList();

    return Scaffold(
      appBar: AppBar(title: const UpperText('PANEL DE PROGRESO')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1100),
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      UpperText(
                        category == AppCategory.mixta
                            ? 'RESUMEN GENERAL DE TODAS LAS CATEGORÍAS'
                            : 'RESUMEN DE ${category.label}',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 8),
                      UpperText('SESIONES REGISTRADAS: ${filteredResults.length}'),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              if (filteredResults.isEmpty)
                const Card(
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: UpperText('AÚN NO HAY DATOS DE PROGRESO'),
                  ),
                )
              else
                ..._trackedGames.map((game) {
                  final gameResults = filteredResults
                      .where((result) => result.activityType == game)
                      .toList()
                    ..sort((a, b) => a.createdAt.compareTo(b.createdAt));

                  final letters = _computeProblemLetters(
                    game: game,
                    allItems: allItems,
                    gameItemProgressMap: gameItemProgress,
                    category: category,
                  );

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _GameProgressCard(
                      game: game,
                      results: gameResults,
                      problemLetters: letters,
                    ),
                  );
                }),
            ],
          ),
        ),
      ),
    );
  }

  List<String> _computeProblemLetters({
    required ActivityType game,
    required List<Item> allItems,
    required Map<String, ItemProgress> gameItemProgressMap,
    required AppCategory category,
  }) {
    final byId = <String, Item>{for (final item in allItems) item.id: item};
    final scoreByLetter = <String, int>{};

    for (final entry in gameItemProgressMap.entries) {
      final key = entry.key;
      final separatorIndex = key.indexOf('|');
      if (separatorIndex <= 0) {
        continue;
      }

      final gameKey = key.substring(0, separatorIndex);
      if (gameKey != game.key) {
        continue;
      }

      final itemId = key.substring(separatorIndex + 1);
      final item = byId[itemId];
      if (item == null) {
        continue;
      }

      if (category != AppCategory.mixta && item.category != category) {
        continue;
      }

      final diff = entry.value.incorrectAttempts - entry.value.correctAttempts;
      if (diff <= 0) {
        continue;
      }

      final word = item.word ?? (item.words.isNotEmpty ? item.words.first : '');
      if (word.isEmpty) {
        continue;
      }

      final letters = normalizeWordForLetters(word)
          .split('')
          .where((char) => RegExp(r'[A-ZÑ]').hasMatch(char))
          .toSet();

      for (final letter in letters) {
        scoreByLetter[letter] = (scoreByLetter[letter] ?? 0) + diff;
      }
    }

    final sorted = scoreByLetter.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return sorted.take(5).map((entry) => entry.key).toList();
  }
}

class _GameProgressCard extends StatelessWidget {
  const _GameProgressCard({
    required this.game,
    required this.results,
    required this.problemLetters,
  });

  final ActivityType game;
  final List<ActivityResult> results;
  final List<String> problemLetters;

  @override
  Widget build(BuildContext context) {
    final totalCorrect = results.fold<int>(0, (sum, result) => sum + result.correct);
    final totalIncorrect = results.fold<int>(0, (sum, result) => sum + result.incorrect);
    final totalTime = results.fold<int>(0, (sum, result) => sum + result.durationInSeconds);
    final totalAttempts = totalCorrect + totalIncorrect;
    final accuracy = totalAttempts == 0 ? 0.0 : totalCorrect / totalAttempts;

    final lastAccuracies = results
        .map((result) => result.accuracy)
        .toList()
        .takeLast(8);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            UpperText(
              game.label,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 10,
              runSpacing: 8,
              children: [
                _MetricChip(label: 'ACIERTOS', value: '$totalCorrect'),
                _MetricChip(label: 'FALLOS', value: '$totalIncorrect'),
                _MetricChip(label: 'TIEMPO', value: '$totalTime S'),
                _MetricChip(label: 'PRECISIÓN', value: '${(accuracy * 100).round()}%'),
              ],
            ),
            const SizedBox(height: 12),
            UpperText(
              'EVOLUCIÓN',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            _EvolutionBars(values: lastAccuracies),
            const SizedBox(height: 12),
            UpperText(
              problemLetters.isEmpty
                  ? 'LETRAS A REFORZAR: SIN DATOS'
                  : 'LETRAS A REFORZAR: ${problemLetters.join(', ')}',
              style: Theme.of(context).textTheme.bodyLarge,
            ),
          ],
        ),
      ),
    );
  }
}

class _MetricChip extends StatelessWidget {
  const _MetricChip({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          UpperText(
            label,
            style: Theme.of(context).textTheme.bodySmall,
          ),
          UpperText(
            value,
            style: Theme.of(context).textTheme.titleMedium,
          ),
        ],
      ),
    );
  }
}

class _EvolutionBars extends StatelessWidget {
  const _EvolutionBars({required this.values});

  final List<double> values;

  @override
  Widget build(BuildContext context) {
    if (values.isEmpty) {
      return const UpperText('AÚN NO HAY SESIONES PARA MOSTRAR EVOLUCIÓN');
    }

    return SizedBox(
      height: 80,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: values.map((value) {
          final barHeight = max(10.0, value * 74);
          final color = value >= 0.8
              ? Colors.green.shade600
              : value >= 0.6
              ? Colors.amber.shade700
              : Colors.red.shade600;
          return Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 3),
              child: Container(
                height: barHeight,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  color: color,
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

extension _TakeLastList on List<double> {
  List<double> takeLast(int count) {
    if (length <= count) {
      return this;
    }
    return sublist(length - count);
  }
}
