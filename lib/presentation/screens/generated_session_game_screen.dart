import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/providers/app_providers.dart';
import '../../core/utils/text_utils.dart';
import '../../domain/models/ai_resource.dart';
import '../../domain/models/ai_quiz_question.dart';
import '../viewmodels/ai_resource_studio_view_model.dart';
import '../widgets/activity_asset_image.dart';
import '../widgets/game_style.dart';
import '../widgets/upper_text.dart';

class GeneratedSessionGameScreen extends ConsumerStatefulWidget {
  const GeneratedSessionGameScreen({
    super.key,
    required this.resourceId,
    required this.sessionTitle,
  });

  final String resourceId;
  final String sessionTitle;

  @override
  ConsumerState<GeneratedSessionGameScreen> createState() =>
      _GeneratedSessionGameScreenState();
}

class _GeneratedSessionGameScreenState
    extends ConsumerState<GeneratedSessionGameScreen> {
  int _index = 0;
  int? _selected;
  int _correct = 0;
  bool _answered = false;
  late final Map<String, String> _imageByWord;
  late final Map<String, String> _wordByNormalized;

  @override
  void initState() {
    super.initState();
    final indexes = _buildWordIndexes();
    _imageByWord = indexes.$1;
    _wordByNormalized = indexes.$2;
  }

  @override
  Widget build(BuildContext context) {
    final resourceState = ref.watch(aiResourceStudioViewModelProvider);
    AiResource? resource;
    for (final item in resourceState.resources) {
      if (item.id == widget.resourceId) {
        resource = item;
        break;
      }
    }

    if (resource == null) {
      return const GameScaffold(
        title: 'JUEGO GENERADO',
        body: Center(child: Text('No se encontró el recurso de la sesión.')),
      );
    }

    if (resource.playableQuestions.isEmpty) {
      return const GameScaffold(
        title: 'JUEGO GENERADO',
        body: Center(
          child: Text('Este recurso no tiene preguntas jugables todavía.'),
        ),
      );
    }

    final targetLetter = _extractTargetLetter(widget.sessionTitle);
    final questions = _buildEffectiveQuestions(
      source: resource.playableQuestions,
      targetLetter: targetLetter,
    );
    if (questions.isEmpty) {
      return const GameScaffold(
        title: 'JUEGO GENERADO',
        body: Center(
          child: Text('No se pudieron preparar preguntas jugables.'),
        ),
      );
    }
    if (_index >= questions.length) {
      _index = 0;
    }

    final totalQuestions = questions.length;
    final question = questions[_index];
    final completed = _answered && _index == totalQuestions - 1;

    return GameScaffold(
      title: 'JUEGO · ${widget.sessionTitle}',
      instructionText: question.prompt,
      progressCurrent: _index + (_answered ? 1 : 0),
      progressTotal: totalQuestions,
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            GameProgressHeader(
              label: 'TU PROGRESO',
              current: _index + (_answered ? 1 : 0),
              total: totalQuestions,
              trailingLabel: '⭐ $_correct',
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _pill(context, 'PREGUNTA ${_index + 1}/$totalQuestions'),
                _pill(context, 'ACIERTOS $_correct'),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              question.prompt,
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final width = MediaQuery.sizeOf(context).width;
                  final crossAxisCount = width > 1080
                      ? 3
                      : width > 760
                      ? 2
                      : 1;
                  final rows = (question.options.length / crossAxisCount)
                      .ceil();
                  const spacing = 10.0;
                  final rawExtent =
                      (constraints.maxHeight - ((rows - 1) * spacing)) / rows;
                  final itemExtent = rawExtent.clamp(190.0, 340.0);

                  return GridView.builder(
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: crossAxisCount,
                      mainAxisSpacing: spacing,
                      crossAxisSpacing: spacing,
                      mainAxisExtent: itemExtent,
                    ),
                    itemCount: question.options.length,
                    itemBuilder: (context, i) {
                      final option = question.options[i];
                      final normalized = normalizeWordForLetters(option);
                      final imageAsset = _imageByWord[normalized];
                      final isSelected = _selected == i;
                      final isCorrect = _answered && i == question.correctIndex;
                      final isWrong =
                          _answered && isSelected && i != question.correctIndex;
                      final color = isCorrect
                          ? Colors.green
                          : isWrong
                          ? Colors.red
                          : Theme.of(context).colorScheme.outline;

                      return InkWell(
                        onTap: _answered
                            ? null
                            : () => _choose(i, question.correctIndex),
                        borderRadius: BorderRadius.circular(18),
                        child: Ink(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(
                              color: color,
                              width: isCorrect || isWrong ? 3 : 1.2,
                            ),
                            color: Theme.of(context).colorScheme.surface,
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(10),
                            child: Column(
                              children: [
                                Expanded(
                                  child: Container(
                                    width: double.infinity,
                                    decoration: BoxDecoration(
                                      color: Colors.grey.shade100,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    alignment: Alignment.center,
                                    child: imageAsset == null
                                        ? const Icon(Icons.image_not_supported)
                                        : ActivityAssetImage(
                                            assetPath: imageAsset,
                                            semanticsLabel: option,
                                            fit: BoxFit.contain,
                                          ),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                UpperText(
                                  option,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: _answered ? () => _next(totalQuestions) : null,
                icon: Icon(
                  completed
                      ? Icons.replay_rounded
                      : Icons.arrow_forward_rounded,
                ),
                label: UpperText(completed ? 'REINICIAR' : 'SIGUIENTE'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _pill(BuildContext context, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFEAF9F4),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Theme.of(context).colorScheme.outline),
      ),
      child: UpperText(
        text,
        style: const TextStyle(fontWeight: FontWeight.w900),
      ),
    );
  }

  void _choose(int index, int correctIndex) {
    if (_answered) {
      return;
    }
    setState(() {
      _selected = index;
      _answered = true;
      if (index == correctIndex) {
        _correct++;
      }
    });
  }

  void _next(int total) {
    setState(() {
      if (_index + 1 >= total) {
        _index = 0;
        _correct = 0;
      } else {
        _index++;
      }
      _selected = null;
      _answered = false;
    });
  }

  (Map<String, String>, Map<String, String>) _buildWordIndexes() {
    final dataset = ref.read(datasetRepositoryProvider);
    final all = dataset.getAllItems();
    final imageByWord = <String, String>{};
    final wordByNormalized = <String, String>{};
    for (final item in all) {
      final word = (item.word ?? '').trim();
      if (word.isEmpty) {
        continue;
      }
      final normalized = normalizeWordForLetters(word);
      imageByWord.putIfAbsent(normalized, () => item.imageAsset);
      wordByNormalized.putIfAbsent(normalized, () => toUpperSingleSpace(word));
    }
    return (imageByWord, wordByNormalized);
  }

  String? _extractTargetLetter(String input) {
    final match = RegExp(
      r'LETRA\s+([A-ZÑ])',
      caseSensitive: false,
    ).firstMatch(input);
    final letter = match?.group(1)?.toUpperCase();
    if (letter == null || letter.isEmpty) {
      return null;
    }
    return letter;
  }

  List<String> _datasetWordsWithLetter(String letter) {
    final words =
        _wordByNormalized.values
            .where((word) => containsLetter(word, letter))
            .toSet()
            .toList()
          ..shuffle();
    return words;
  }

  List<AiQuizQuestion> _buildEffectiveQuestions({
    required List<AiQuizQuestion> source,
    required String? targetLetter,
  }) {
    if (targetLetter == null) {
      return source;
    }

    final candidates = _datasetWordsWithLetter(targetLetter);
    var candidateIndex = 0;
    final output = <AiQuizQuestion>[];

    for (final q in source) {
      final options = q.options
          .map((item) => toUpperSingleSpace(item))
          .where((item) => item.isNotEmpty)
          .toList();
      if (options.length < 2) {
        continue;
      }
      while (options.length > 3) {
        options.removeLast();
      }
      var correctIndex = q.correctIndex.clamp(0, options.length - 1);
      final hasTarget = options.any(
        (option) => containsLetter(option, targetLetter),
      );
      if (!hasTarget && candidates.isNotEmpty) {
        final replacement = candidates[candidateIndex % candidates.length];
        candidateIndex++;
        if (options.length < 3) {
          options.add(replacement);
          correctIndex = options.length - 1;
        } else {
          options[options.length - 1] = replacement;
          correctIndex = options.length - 1;
        }
      }
      output.add(
        AiQuizQuestion(
          prompt: q.prompt,
          options: options,
          correctIndex: correctIndex,
          feedback: q.feedback,
        ),
      );
    }
    return output;
  }
}
