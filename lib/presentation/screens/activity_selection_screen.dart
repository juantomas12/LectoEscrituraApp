import 'package:flutter/material.dart';

import '../../domain/models/activity_type.dart';
import '../../domain/models/category.dart';
import '../../domain/models/difficulty.dart';
import '../../domain/models/level.dart';
import '../widgets/upper_text.dart';
import 'activities/match_image_phrase_screen.dart';
import 'activities/match_image_word_screen.dart';
import 'activities/match_word_word_screen.dart';
import 'activities/write_word_screen.dart';

class ActivitySelectionScreen extends StatelessWidget {
  const ActivitySelectionScreen({
    super.key,
    required this.category,
    required this.level,
    required this.difficulty,
  });

  final AppCategory category;
  final AppLevel level;
  final Difficulty difficulty;

  @override
  Widget build(BuildContext context) {
    final activities = switch (level) {
      AppLevel.uno => [
        ActivityType.imagenPalabra,
        ActivityType.escribirPalabra,
      ],
      AppLevel.dos => [ActivityType.palabraPalabra],
      AppLevel.tres => [ActivityType.imagenFrase],
    };

    return Scaffold(
      appBar: AppBar(title: const UpperText('SELECCIÓN DE ACTIVIDAD')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  UpperText(
                    category.label,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 6),
                  UpperText('NIVEL: ${level.label}'),
                  const SizedBox(height: 6),
                  UpperText('DIFICULTAD: ${difficulty.label}'),
                ],
              ),
            ),
          ),
          const SizedBox(height: 14),
          ...activities.map(
            (activity) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      UpperText(
                        activity.label,
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 10),
                      FilledButton(
                        onPressed: () => _openActivity(context, activity),
                        child: const UpperText('INICIAR ACTIVIDAD'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _openActivity(BuildContext context, ActivityType activity) {
    switch (activity) {
      case ActivityType.imagenPalabra:
        Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => MatchImageWordScreen(
              category: category,
              difficulty: difficulty,
            ),
          ),
        );
        return;
      case ActivityType.escribirPalabra:
        Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) =>
                WriteWordScreen(category: category, difficulty: difficulty),
          ),
        );
        return;
      case ActivityType.palabraPalabra:
        Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) =>
                MatchWordWordScreen(category: category, difficulty: difficulty),
          ),
        );
        return;
      case ActivityType.imagenFrase:
        Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => MatchImagePhraseScreen(
              category: category,
              difficulty: difficulty,
            ),
          ),
        );
        return;
    }
  }
}
