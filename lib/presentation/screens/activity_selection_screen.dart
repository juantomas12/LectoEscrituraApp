import 'package:flutter/material.dart';

import '../../domain/models/activity_type.dart';
import '../../domain/models/category.dart';
import '../../domain/models/difficulty.dart';
import '../../domain/models/level.dart';
import '../widgets/upper_text.dart';
import 'activities/discrimination_screen.dart';
import 'activities/inverse_discrimination_screen.dart';
import 'activities/letter_target_screen.dart';
import 'activities/match_image_phrase_screen.dart';
import 'activities/match_image_word_screen.dart';
import 'activities/match_word_word_screen.dart';
import 'activities/write_word_screen.dart';

class ActivitySelectionScreen extends StatefulWidget {
  const ActivitySelectionScreen({
    super.key,
    required this.category,
    required this.activityType,
    required this.difficulty,
  });

  final AppCategory category;
  final ActivityType activityType;
  final Difficulty difficulty;

  @override
  State<ActivitySelectionScreen> createState() => _ActivitySelectionScreenState();
}

class _ActivitySelectionScreenState extends State<ActivitySelectionScreen> {
  int _selectedGameLevel = 1;

  @override
  Widget build(BuildContext context) {
    final levels = _levelsForGame(widget.activityType);

    if (!levels.contains(_selectedGameLevel)) {
      _selectedGameLevel = levels.first;
    }

    return Scaffold(
      appBar: AppBar(title: const UpperText('SELECCIÓN DE JUEGO')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 980),
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.sports_esports_rounded),
                          SizedBox(width: 8),
                          UpperText(
                            'JUEGO SELECCIONADO',
                            style: TextStyle(fontWeight: FontWeight.w900),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      UpperText(
                        widget.activityType.label,
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 6),
                      UpperText(widget.category.label),
                      const SizedBox(height: 6),
                      UpperText('DIFICULTAD: ${widget.difficulty.label}'),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      UpperText(
                        'NIVELES DEL JUEGO',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: levels.map((level) {
                          final selected = _selectedGameLevel == level;
                          return ChoiceChip(
                            selected: selected,
                            label: UpperText('NIVEL $level'),
                            onSelected: (_) {
                              setState(() {
                                _selectedGameLevel = level;
                              });
                            },
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 10),
                      UpperText(_levelDescription(widget.activityType, _selectedGameLevel)),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 14),
              FilledButton.icon(
                onPressed: () => _openActivity(
                  context,
                  widget.activityType,
                  _selectedGameLevel,
                ),
                icon: const Icon(Icons.play_arrow_rounded),
                label: const UpperText('INICIAR JUEGO'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<int> _levelsForGame(ActivityType activityType) {
    return switch (activityType) {
      ActivityType.letraObjetivo => [1, 2, 3],
      ActivityType.discriminacion => [1, 2, 3],
      ActivityType.discriminacionInversa => [1, 2, 3],
      _ => [1],
    };
  }

  String _levelDescription(ActivityType activityType, int level) {
    return switch (activityType) {
      ActivityType.letraObjetivo => switch (level) {
        1 => 'VOCALES Y PALABRAS CORTAS',
        2 => 'LETRAS FRECUENTES Y PALABRAS MEDIAS',
        3 => 'LETRAS MIXTAS Y PALABRAS MÁS LARGAS',
        _ => 'NIVEL BASE',
      },
      ActivityType.discriminacion => switch (level) {
        1 => 'POCAS OPCIONES Y APOYO VISUAL',
        2 => 'MÁS OPCIONES Y MENOS PISTAS',
        3 => 'MÁXIMA DIFICULTAD Y MÁS RONDAS',
        _ => 'NIVEL BASE',
      },
      ActivityType.discriminacionInversa => switch (level) {
        1 => 'ENCUENTRA LA INTRUSA ENTRE POCAS OPCIONES',
        2 => 'MÁS OPCIONES Y MÁS ATENCIÓN',
        3 => 'INTRUSA CON DISTRACCIONES ALTAS',
        _ => 'NIVEL BASE',
      },
      _ => 'ESTE JUEGO TIENE UN NIVEL ACTIVO POR AHORA',
    };
  }

  void _openActivity(BuildContext context, ActivityType activity, int gameLevel) {
    switch (activity) {
      case ActivityType.imagenPalabra:
        Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => MatchImageWordScreen(
              category: widget.category,
              difficulty: widget.difficulty,
            ),
          ),
        );
        return;
      case ActivityType.escribirPalabra:
        Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => WriteWordScreen(
              category: widget.category,
              difficulty: widget.difficulty,
            ),
          ),
        );
        return;
      case ActivityType.palabraPalabra:
        Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => MatchWordWordScreen(
              category: widget.category,
              difficulty: widget.difficulty,
            ),
          ),
        );
        return;
      case ActivityType.imagenFrase:
        Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => MatchImagePhraseScreen(
              category: widget.category,
              difficulty: widget.difficulty,
            ),
          ),
        );
        return;
      case ActivityType.letraObjetivo:
        Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => LetterTargetScreen(
              category: widget.category,
              difficulty: widget.difficulty,
              level: AppLevelX.fromInt(gameLevel),
            ),
          ),
        );
        return;
      case ActivityType.discriminacion:
        Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => DiscriminationScreen(
              category: widget.category,
              difficulty: widget.difficulty,
              level: AppLevelX.fromInt(gameLevel),
            ),
          ),
        );
        return;
      case ActivityType.discriminacionInversa:
        Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => InverseDiscriminationScreen(
              category: widget.category,
              difficulty: widget.difficulty,
              level: AppLevelX.fromInt(gameLevel),
            ),
          ),
        );
        return;
    }
  }
}
