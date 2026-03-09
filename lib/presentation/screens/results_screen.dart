import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/models/activity_result.dart';
import '../../domain/models/activity_type.dart';
import '../../domain/models/category.dart';
import '../utils/category_visuals.dart';
import '../viewmodels/progress_view_model.dart';
import '../widgets/upper_text.dart';

enum ResultAction { repetir, reforzarErrores, siguiente }

class ResultsScreen extends ConsumerWidget {
  const ResultsScreen({
    super.key,
    required this.result,
    this.canReinforceErrors = false,
  });

  final ActivityResult result;
  final bool canReinforceErrors;

  int get _stars {
    final score = result.accuracy;
    if (score >= 0.9) {
      return 3;
    }
    if (score >= 0.7) {
      return 2;
    }
    if (score >= 0.5) {
      return 1;
    }
    return 0;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(progressViewModelProvider);
    final rewards = ref
        .read(progressViewModelProvider.notifier)
        .rewardsSummary();
    final categoryBadge =
        rewards.badgesByCategory[result.category] ?? BadgeTier.none;
    final categoryColor = result.category.color;

    return Scaffold(
      appBar: AppBar(title: const UpperText('RESULTADOS')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    UpperText(
                      result.activityType.label,
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 16),
                    UpperText('ACIERTOS: ${result.correct}'),
                    const SizedBox(height: 8),
                    UpperText('FALLOS: ${result.incorrect}'),
                    const SizedBox(height: 8),
                    UpperText('RACHA MÁXIMA: ${result.bestStreak}'),
                    const SizedBox(height: 8),
                    UpperText('TIEMPO: ${result.durationInSeconds} S'),
                    const SizedBox(height: 12),
                    Row(
                      children: List.generate(
                        3,
                        (index) => Icon(
                          index < _stars ? Icons.star : Icons.star_border,
                          size: 34,
                          color: index < _stars
                              ? Colors.amber.shade700
                              : Colors.grey.shade500,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    UpperText(
                      result.accuracy >= 0.7 ? 'MUY BIEN' : 'SIGUE PRACTICANDO',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 14),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        color: categoryColor.withValues(alpha: 0.10),
                        border: Border.all(
                          color: categoryColor.withValues(alpha: 0.30),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          UpperText(
                            'RECOMPENSAS',
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(fontWeight: FontWeight.w900),
                          ),
                          const SizedBox(height: 8),
                          UpperText(
                            'RACHA ACTUAL: ${rewards.currentStreak} DÍAS',
                          ),
                          const SizedBox(height: 4),
                          UpperText('RACHA MÁXIMA: ${rewards.longestStreak}'),
                          const SizedBox(height: 4),
                          UpperText(
                            'INSIGNIA ${result.category.label}: ${categoryBadge.label}',
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const Spacer(),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(ResultAction.repetir),
              child: const UpperText('REPETIR'),
            ),
            if (canReinforceErrors) ...[
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: () =>
                    Navigator.of(context).pop(ResultAction.reforzarErrores),
                icon: const Icon(Icons.fitness_center_rounded),
                label: const UpperText('REFORZAR ERRORES'),
              ),
            ],
            const SizedBox(height: 12),
            OutlinedButton(
              onPressed: () =>
                  Navigator.of(context).pop(ResultAction.siguiente),
              child: const UpperText('SIGUIENTE'),
            ),
          ],
        ),
      ),
    );
  }
}
