import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/providers/app_providers.dart';
import '../../core/utils/text_utils.dart';
import '../../domain/models/ai_resource.dart';
import '../viewmodels/ai_resource_studio_view_model.dart';
import '../widgets/activity_asset_image.dart';
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
      return Scaffold(
        appBar: AppBar(title: const UpperText('JUEGO GENERADO')),
        body: const Center(
          child: Text('No se encontró el recurso de la sesión.'),
        ),
      );
    }

    if (resource.playableQuestions.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const UpperText('JUEGO GENERADO')),
        body: const Center(
          child: Text('Este recurso no tiene preguntas jugables todavía.'),
        ),
      );
    }

    final totalQuestions = resource.playableQuestions.length;
    final question = resource.playableQuestions[_index];
    final imageByWord = _optionImageByWord(resource);
    final completed = _answered && _index == totalQuestions - 1;

    return Scaffold(
      appBar: AppBar(title: UpperText('JUEGO · ${widget.sessionTitle}')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
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
              child: GridView.builder(
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: MediaQuery.sizeOf(context).width > 900
                      ? 3
                      : 2,
                  mainAxisSpacing: 10,
                  crossAxisSpacing: 10,
                  childAspectRatio: 1.1,
                ),
                itemCount: question.options.length,
                itemBuilder: (context, i) {
                  final option = question.options[i];
                  final normalized = normalizeWordForLetters(option);
                  final imageAsset = imageByWord[normalized];
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
                              child: imageAsset == null
                                  ? Container(
                                      decoration: BoxDecoration(
                                        color: Colors.grey.shade100,
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      alignment: Alignment.center,
                                      child: const Icon(
                                        Icons.image_not_supported,
                                      ),
                                    )
                                  : ActivityAssetImage(
                                      assetPath: imageAsset,
                                      semanticsLabel: option,
                                    ),
                            ),
                            const SizedBox(height: 8),
                            UpperText(
                              option,
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
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

  Map<String, String> _optionImageByWord(AiResource resource) {
    final dataset = ref.read(datasetRepositoryProvider);
    final all = dataset.getAllItems();
    final output = <String, String>{};
    for (final item in all) {
      final word = (item.word ?? '').trim();
      if (word.isEmpty) {
        continue;
      }
      final normalized = normalizeWordForLetters(word);
      output.putIfAbsent(normalized, () => item.imageAsset);
    }
    return output;
  }
}
