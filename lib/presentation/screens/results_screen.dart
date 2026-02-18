import 'package:flutter/material.dart';

import '../../domain/models/activity_result.dart';
import '../../domain/models/activity_type.dart';
import '../widgets/upper_text.dart';

enum ResultAction { repetir, siguiente }

class ResultsScreen extends StatelessWidget {
  const ResultsScreen({super.key, required this.result});

  final ActivityResult result;

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
  Widget build(BuildContext context) {
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
                  ],
                ),
              ),
            ),
            const Spacer(),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(ResultAction.repetir),
              child: const UpperText('REPETIR'),
            ),
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
