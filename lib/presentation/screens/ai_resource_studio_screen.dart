import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/providers/app_providers.dart';
import '../../core/config/env_config.dart';
import '../../core/utils/text_utils.dart';
import '../../domain/models/ai_quiz_question.dart';
import '../../domain/models/ai_resource.dart';
import '../../domain/models/activity_type.dart';
import '../../domain/models/category.dart';
import '../viewmodels/ai_resource_studio_view_model.dart';
import '../viewmodels/settings_view_model.dart';
import '../widgets/activity_asset_image.dart';
import '../widgets/upper_text.dart';
import 'session_workspace_screen.dart';

class AiResourceStudioScreen extends ConsumerStatefulWidget {
  const AiResourceStudioScreen({super.key});

  @override
  ConsumerState<AiResourceStudioScreen> createState() =>
      _AiResourceStudioScreenState();
}

class _AiResourceStudioScreenState
    extends ConsumerState<AiResourceStudioScreen> {
  static const _maxPromptLength = 1000;

  final _instructionController = TextEditingController();
  final _apiKeyController = TextEditingController();
  final _modelController = TextEditingController(text: EnvConfig.openAiModel);
  final _searchController = TextEditingController();
  bool _didSyncKeyFromSettings = false;

  String _ageRange = 'INFANTIL (7-12)';
  String _duration = '10-15 MIN';
  String _mode = 'SITUACIÓN DE APRENDIZAJE';
  AppCategory _category = AppCategory.mixta;
  bool _onlyFavorites = false;
  AiResource? _selectedResource;

  @override
  void dispose() {
    _instructionController.dispose();
    _apiKeyController.dispose();
    _modelController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  List<String> _availableWordsForGeneration() {
    final dataset = ref.read(datasetRepositoryProvider);
    final all = dataset.getAllItems().where((item) {
      final word = (item.word ?? '').trim();
      return word.isNotEmpty &&
          item.activityType == ActivityType.imagenPalabra &&
          (_category == AppCategory.mixta || item.category == _category);
    });

    final unique =
        all.map((item) => item.word!.trim().toUpperCase()).toSet().toList()
          ..sort();
    if (unique.length <= 120) {
      return unique;
    }
    return unique.take(120).toList();
  }

  Map<String, String> _optionImageByWord(AiResource resource) {
    final dataset = ref.read(datasetRepositoryProvider);
    final all = dataset.getAllItems();
    final category = AppCategoryX.fromLabel(resource.categoryLabel);
    final output = <String, String>{};
    for (final item in all) {
      if (item.activityType != ActivityType.imagenPalabra) {
        continue;
      }
      final word = (item.word ?? '').trim();
      if (word.isEmpty) {
        continue;
      }
      if (category != AppCategory.mixta && item.category != category) {
        continue;
      }
      final normalized = normalizeWordForLetters(word);
      output.putIfAbsent(normalized, () => item.imageAsset);
    }
    return output;
  }

  Future<void> _generateResource() async {
    final instruction = _instructionController.text.trim();
    if (instruction.isEmpty) {
      return;
    }
    final settingsVm = ref.read(settingsViewModelProvider.notifier);
    final settings = ref.read(settingsViewModelProvider);

    if (_apiKeyController.text.trim().isNotEmpty &&
        _apiKeyController.text.trim() != settings.openAiApiKey) {
      await settingsVm.setOpenAiApiKey(_apiKeyController.text.trim());
    }
    if (_modelController.text.trim().isNotEmpty &&
        _modelController.text.trim() != settings.openAiModel) {
      await settingsVm.setOpenAiModel(_modelController.text.trim());
    }

    final apiKey = _apiKeyController.text.trim().isNotEmpty
        ? _apiKeyController.text.trim()
        : settings.openAiApiKey.isNotEmpty
        ? settings.openAiApiKey
        : EnvConfig.openAiApiKey;

    final generated = await ref
        .read(aiResourceStudioViewModelProvider.notifier)
        .generateAndSave(
          instruction: instruction,
          ageRange: _ageRange,
          duration: _duration,
          mode: _mode,
          categoryLabel: _category.label,
          difficultyLabel: 'AUTO POR EDAD',
          apiKey: apiKey,
          allowedWords: _availableWordsForGeneration(),
          model: _modelController.text.trim(),
        );

    if (!mounted || generated == null) {
      return;
    }
    setState(() {
      _selectedResource = generated;
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(aiResourceStudioViewModelProvider);
    final settings = ref.watch(settingsViewModelProvider);
    if (!_didSyncKeyFromSettings) {
      _didSyncKeyFromSettings = true;
      if ((_modelController.text.trim().isEmpty ||
              _modelController.text.trim() == EnvConfig.openAiModel) &&
          settings.openAiModel.isNotEmpty) {
        _modelController.text = settings.openAiModel;
      }
    }
    final search = _searchController.text.trim().toUpperCase();
    final resources = state.resources.where((resource) {
      if (search.isEmpty) {
        return !_onlyFavorites || resource.isFavorite;
      }
      final matches =
          resource.title.toUpperCase().contains(search) ||
          resource.objective.toUpperCase().contains(search);
      if (!matches) {
        return false;
      }
      return !_onlyFavorites || resource.isFavorite;
    }).toList();
    AiResource? activeResource;
    if (_selectedResource != null) {
      for (final resource in resources) {
        if (resource.id == _selectedResource!.id) {
          activeResource = resource;
          break;
        }
      }
    }
    activeResource ??= resources.isEmpty ? null : resources.first;
    final imageMap = activeResource == null
        ? const <String, String>{}
        : _optionImageByWord(activeResource);

    return Scaffold(
      appBar: AppBar(
        title: const UpperText('CREA TU RECURSO IA'),
        actions: [
          IconButton(
            tooltip: 'WORKSPACE SESIONES',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => const SessionWorkspaceScreen(),
                ),
              );
            },
            icon: const Icon(Icons.view_kanban_rounded),
          ),
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1120),
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFFFFEEF4), Color(0xFFEAF9F4)],
                  ),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: Theme.of(
                      context,
                    ).colorScheme.primary.withValues(alpha: 0.20),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const UpperText(
                      'DESCRIBE TU OBJETIVO Y LA IA GENERARÁ LA ACTIVIDAD EN SEGUNDOS',
                      style: TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 20,
                      ),
                    ),
                    const SizedBox(height: 12),
                    UpperText(
                      'TU INSTRUCCIÓN (${_instructionController.text.length}/$_maxPromptLength)',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _instructionController,
                      maxLength: _maxPromptLength,
                      minLines: 4,
                      maxLines: 6,
                      onChanged: (_) => setState(() {}),
                      decoration: InputDecoration(
                        hintText:
                            'EJEMPLO: CREA UNA ACTIVIDAD CON VOCAL E PARA NIÑOS DE 7 A 12, CON 8 PREGUNTAS Y APOYO VISUAL.',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        ...[
                          'AUTO',
                          'INFANTIL (3-6)',
                          'INFANTIL (7-12)',
                          'ADOLESCENTES',
                          'ADULTOS',
                          'MAYORES',
                        ].map((option) {
                          return ChoiceChip(
                            selected: _ageRange == option,
                            label: UpperText(option),
                            onSelected: (_) =>
                                setState(() => _ageRange = option),
                          );
                        }),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        ...[
                          'AUTO',
                          '1-3 MIN',
                          '5-10 MIN',
                          '10-15 MIN',
                          '15-20 MIN',
                        ].map((option) {
                          return ChoiceChip(
                            selected: _duration == option,
                            label: UpperText(option),
                            onSelected: (_) =>
                                setState(() => _duration = option),
                          );
                        }),
                      ],
                    ),
                    const SizedBox(height: 8),
                    ExpansionTile(
                      initiallyExpanded: true,
                      tilePadding: EdgeInsets.zero,
                      title: const UpperText('CONFIGURACIÓN AVANZADA'),
                      childrenPadding: const EdgeInsets.only(bottom: 8),
                      children: [
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            ...[
                              'SITUACIÓN DE APRENDIZAJE',
                              'ACTIVIDAD DE PREGUNTAS',
                              'MINI-JUEGO GUIADO',
                            ].map((option) {
                              return ChoiceChip(
                                selected: _mode == option,
                                label: UpperText(option),
                                onSelected: (_) =>
                                    setState(() => _mode = option),
                              );
                            }),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: AppCategory.values.map((category) {
                            return ChoiceChip(
                              selected: _category == category,
                              label: UpperText(category.label),
                              onSelected: (_) =>
                                  setState(() => _category = category),
                            );
                          }).toList(),
                        ),
                        const SizedBox(height: 8),
                        TextField(
                          controller: _apiKeyController,
                          obscureText: true,
                          onChanged: (value) {
                            ref
                                .read(settingsViewModelProvider.notifier)
                                .setOpenAiApiKey(value);
                          },
                          decoration: InputDecoration(
                            labelText:
                                'OPENAI API KEY (SE GUARDA SOLO EN ESTE DISPOSITIVO)',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextField(
                          controller: _modelController,
                          onChanged: (value) {
                            ref
                                .read(settingsViewModelProvider.notifier)
                                .setOpenAiModel(value);
                          },
                          decoration: InputDecoration(
                            labelText: 'MODELO OPENAI',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          EnvConfig.openAiApiKey.isNotEmpty
                              ? 'Se detectó OPENAI_API_KEY en entorno.'
                              : settings.openAiApiKey.isNotEmpty
                              ? 'Usando API key guardada en ajustes locales.'
                              : 'Si no pones key aquí, usa el archivo .env con OPENAI_API_KEY.',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    FilledButton.icon(
                      onPressed: state.isGenerating ? null : _generateResource,
                      icon: state.isGenerating
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.auto_awesome_rounded),
                      label: UpperText(
                        state.isGenerating ? 'GENERANDO...' : 'CREAR RECURSO',
                      ),
                    ),
                  ],
                ),
              ),
              if (state.errorMessage != null) ...[
                const SizedBox(height: 10),
                Card(
                  color: Colors.red.shade50,
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Text(
                      state.errorMessage!,
                      style: TextStyle(color: Colors.red.shade800),
                    ),
                  ),
                ),
              ],
              if (activeResource != null) ...[
                const SizedBox(height: 12),
                _GeneratedResourceCard(
                  resource: activeResource,
                  optionImageByWord: imageMap,
                  onToggleFavorite: () async {
                    await ref
                        .read(aiResourceStudioViewModelProvider.notifier)
                        .toggleFavorite(activeResource!.id);
                    if (!mounted) {
                      return;
                    }
                    setState(() {
                      _selectedResource = activeResource;
                    });
                  },
                ),
              ],
              const SizedBox(height: 12),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      UpperText(
                        'MIS RECURSOS GUARDADOS (${resources.length})',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        children: [
                          ChoiceChip(
                            selected: !_onlyFavorites,
                            label: const UpperText('TODOS'),
                            onSelected: (_) {
                              setState(() => _onlyFavorites = false);
                            },
                          ),
                          ChoiceChip(
                            selected: _onlyFavorites,
                            label: const UpperText('SOLO FAVORITOS'),
                            onSelected: (_) {
                              setState(() => _onlyFavorites = true);
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _searchController,
                        onChanged: (_) => setState(() {}),
                        decoration: InputDecoration(
                          hintText: 'BUSCAR RECURSOS...',
                          prefixIcon: const Icon(Icons.search),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      if (resources.isEmpty)
                        const Text('No hay recursos guardados todavía.')
                      else
                        ...resources.map((resource) {
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                  color: Theme.of(context).colorScheme.outline,
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    resource.title,
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleLarge
                                        ?.copyWith(fontWeight: FontWeight.w900),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(resource.objective),
                                  const SizedBox(height: 6),
                                  Text(
                                    '${resource.ageRange} · ${resource.duration} · ${resource.mode}',
                                    style: Theme.of(
                                      context,
                                    ).textTheme.bodySmall,
                                  ),
                                  const SizedBox(height: 8),
                                  Row(
                                    children: [
                                      IconButton(
                                        tooltip: 'FAVORITO',
                                        onPressed: () async {
                                          await ref
                                              .read(
                                                aiResourceStudioViewModelProvider
                                                    .notifier,
                                              )
                                              .toggleFavorite(resource.id);
                                        },
                                        icon: Icon(
                                          resource.isFavorite
                                              ? Icons.star_rounded
                                              : Icons.star_outline_rounded,
                                          color: resource.isFavorite
                                              ? Colors.amber.shade700
                                              : null,
                                        ),
                                      ),
                                      OutlinedButton(
                                        onPressed: () {
                                          setState(() {
                                            _selectedResource = resource;
                                          });
                                        },
                                        child: const UpperText('ABRIR'),
                                      ),
                                      const SizedBox(width: 8),
                                      OutlinedButton(
                                        onPressed: () async {
                                          await ref
                                              .read(
                                                aiResourceStudioViewModelProvider
                                                    .notifier,
                                              )
                                              .delete(resource.id);
                                          if (!mounted) {
                                            return;
                                          }
                                          if (_selectedResource?.id ==
                                              resource.id) {
                                            setState(() {
                                              _selectedResource = null;
                                            });
                                          }
                                        },
                                        child: const UpperText('ELIMINAR'),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          );
                        }),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _GeneratedResourceCard extends StatelessWidget {
  const _GeneratedResourceCard({
    required this.resource,
    required this.optionImageByWord,
    required this.onToggleFavorite,
  });

  final AiResource resource;
  final Map<String, String> optionImageByWord;
  final VoidCallback onToggleFavorite;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    resource.title,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                IconButton(
                  tooltip: 'FAVORITO',
                  onPressed: onToggleFavorite,
                  icon: Icon(
                    resource.isFavorite
                        ? Icons.star_rounded
                        : Icons.star_outline_rounded,
                    color: resource.isFavorite ? Colors.amber.shade700 : null,
                  ),
                ),
              ],
            ),
            Text(
              '${resource.ageRange} · ${resource.duration} · ${resource.mode}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 10),
            _PlayableResourcePanel(
              resource: resource,
              optionImageByWord: optionImageByWord,
            ),
            const SizedBox(height: 10),
            ExpansionTile(
              title: const Text(
                'SITUACIÓN DE APRENDIZAJE',
                style: TextStyle(fontWeight: FontWeight.w900),
              ),
              childrenPadding: const EdgeInsets.only(bottom: 8),
              children: [
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    resource.objective,
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                ),
                const SizedBox(height: 10),
                _ListSection(
                  title: 'Pasos de la actividad',
                  items: resource.activitySteps,
                ),
                _ListSection(
                  title: 'Preguntas sugeridas',
                  items: resource.questions,
                ),
                _ListSection(title: 'Mini-juegos', items: resource.miniGames),
                _ListSection(title: 'Materiales', items: resource.materials),
                _ListSection(
                  title: 'Adaptaciones',
                  items: resource.adaptations,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _PlayableResourcePanel extends StatefulWidget {
  const _PlayableResourcePanel({
    required this.resource,
    required this.optionImageByWord,
  });

  final AiResource resource;
  final Map<String, String> optionImageByWord;

  @override
  State<_PlayableResourcePanel> createState() => _PlayableResourcePanelState();
}

enum _PlayableMode { selectImage, selectWord, trueFalse }

class _PlayableResourcePanelState extends State<_PlayableResourcePanel> {
  final Random _random = Random();

  int _index = 0;
  int? _selectedOption;
  bool? _selectedTrueFalse;
  int _trueFalseCandidateIndex = 0;
  int _correct = 0;
  bool _answered = false;
  _PlayableMode _playMode = _PlayableMode.selectImage;
  int _gameIndex = 0;

  AiQuizQuestion get _current => widget.resource.playableQuestions[_index];
  bool get _isTrueStatement =>
      _trueFalseCandidateIndex == _current.correctIndex;

  @override
  void initState() {
    super.initState();
    _prepareTrueFalseCandidate();
  }

  @override
  void didUpdateWidget(covariant _PlayableResourcePanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.resource.id != widget.resource.id) {
      _resetSession();
    }
  }

  void _resetSession() {
    setState(() {
      _index = 0;
      _selectedOption = null;
      _selectedTrueFalse = null;
      _correct = 0;
      _answered = false;
      _playMode = _PlayableMode.selectImage;
      _gameIndex = 0;
      _prepareTrueFalseCandidate();
    });
  }

  List<String> get _gameLabels {
    final fromResource = widget.resource.miniGames
        .map((item) => item.trim())
        .where((item) => item.isNotEmpty)
        .toList();
    if (fromResource.isNotEmpty) {
      return fromResource.take(5).toList();
    }
    return const [
      'SELECCIONAR IMAGEN',
      'SELECCIONAR PALABRA',
      'VERDADERO/FALSO',
    ];
  }

  _PlayableMode _modeForGameIndex(int index) {
    final slot = index % 3;
    if (slot == 0) return _PlayableMode.selectImage;
    if (slot == 1) return _PlayableMode.selectWord;
    return _PlayableMode.trueFalse;
  }

  void _prepareTrueFalseCandidate() {
    if (_current.options.isEmpty) {
      _trueFalseCandidateIndex = 0;
      return;
    }
    _trueFalseCandidateIndex = _random.nextInt(_current.options.length);
  }

  void _setGameIndex(int index) {
    final mode = _modeForGameIndex(index);
    setState(() {
      _gameIndex = index;
      _playMode = mode;
      _index = 0;
      _selectedOption = null;
      _selectedTrueFalse = null;
      _answered = false;
      _correct = 0;
      _prepareTrueFalseCandidate();
    });
  }

  void _select(int option) {
    if (_answered) {
      return;
    }
    final ok = option == _current.correctIndex;
    setState(() {
      _selectedOption = option;
      _answered = true;
      if (ok) {
        _correct++;
      }
    });
  }

  void _selectTrueFalse(bool value) {
    if (_answered) {
      return;
    }
    final ok = value == _isTrueStatement;
    setState(() {
      _selectedTrueFalse = value;
      _answered = true;
      if (ok) {
        _correct++;
      }
    });
  }

  void _next() {
    if (_index + 1 >= widget.resource.playableQuestions.length) {
      setState(() {
        _index = 0;
        _selectedOption = null;
        _answered = false;
        _correct = 0;
      });
      return;
    }
    setState(() {
      _index++;
      _selectedOption = null;
      _selectedTrueFalse = null;
      _answered = false;
      _prepareTrueFalseCandidate();
    });
  }

  @override
  Widget build(BuildContext context) {
    if (widget.resource.playableQuestions.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.amber.shade50,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.amber.shade300),
        ),
        child: const Text(
          'Este recurso no incluye preguntas jugables todavía. Genera de nuevo para obtener actividad interactiva.',
        ),
      );
    }

    final width = MediaQuery.sizeOf(context).width;
    final wide = width >= 900;
    final readingTitle = widget.resource.investigationTitle.trim().isEmpty
        ? widget.resource.title
        : widget.resource.investigationTitle;
    final readingText = widget.resource.investigationText.trim().isEmpty
        ? widget.resource.objective
        : widget.resource.investigationText;
    final completed =
        _answered && _index + 1 == widget.resource.playableQuestions.length;
    final trueFalsePrompt =
        'Según la consigna: "${_current.prompt}"\n¿La opción mostrada es una respuesta correcta?';
    final isAnsweredCorrect = _playMode == _PlayableMode.trueFalse
        ? _selectedTrueFalse == _isTrueStatement
        : _selectedOption == _current.correctIndex;
    final optionCards = List<Widget>.generate(_current.options.length, (i) {
      final option = _current.options[i];
      final selected = _selectedOption == i;
      final correct = _answered && i == _current.correctIndex;
      final wrongSelected = _answered && selected && i != _current.correctIndex;
      final border = correct
          ? Colors.green.shade700
          : wrongSelected
          ? Colors.red.shade700
          : Theme.of(context).colorScheme.outline;
      final bg = correct
          ? Colors.green.shade50
          : wrongSelected
          ? Colors.red.shade50
          : Theme.of(context).colorScheme.surface;

      final normalized = normalizeWordForLetters(option);
      final imageAsset = widget.optionImageByWord[normalized];

      return InkWell(
        onTap: _answered ? null : () => _select(i),
        borderRadius: BorderRadius.circular(14),
        child: Ink(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: border,
              width: correct || wrongSelected ? 2.5 : 1.3,
            ),
          ),
          child: Column(
            children: [
              Expanded(
                child: imageAsset != null
                    ? ActivityAssetImage(
                        assetPath: imageAsset,
                        semanticsLabel: option,
                      )
                    : _WordFallbackVisual(word: option),
              ),
              const SizedBox(height: 6),
              Text(
                option,
                textAlign: TextAlign.center,
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
              ),
            ],
          ),
        ),
      );
    });

    String answerFeedback() {
      if (_playMode == _PlayableMode.trueFalse) {
        final correctWord = _current.options[_current.correctIndex];
        final shownWord = _current.options[_trueFalseCandidateIndex];
        final outcome = _selectedTrueFalse == _isTrueStatement
            ? 'RESPUESTA CORRECTA'
            : 'RESPUESTA INCORRECTA';
        return '$outcome. OPCIÓN MOSTRADA: $shownWord. RESPUESTA CORRECTA: $correctWord.';
      }
      return _current.feedback;
    }

    final questionPane = Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF2FFF8),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFBFE8D8)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFE4F0FF),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  'PREGUNTA ${_index + 1}/${widget.resource.playableQuestions.length}',
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFEAFBEA),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  'ACIERTOS: $_correct',
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: List<Widget>.generate(_gameLabels.length, (i) {
              return ChoiceChip(
                selected: _gameIndex == i,
                label: Text('JUEGO ${i + 1}: ${_gameLabels[i]}'),
                onSelected: (_) => _setGameIndex(i),
              );
            }),
          ),
          const SizedBox(height: 10),
          Text(
            _playMode == _PlayableMode.trueFalse
                ? trueFalsePrompt
                : _current.prompt,
            style: Theme.of(
              context,
            ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 10),
          if (_playMode == _PlayableMode.selectImage)
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: wide ? 3 : 2,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
                mainAxisExtent: wide ? 290 : 245,
              ),
              itemCount: optionCards.length,
              itemBuilder: (context, index) => optionCards[index],
            )
          else if (_playMode == _PlayableMode.selectWord)
            Column(
              children: List<Widget>.generate(_current.options.length, (i) {
                final selected = _selectedOption == i;
                final correct = _answered && i == _current.correctIndex;
                final wrongSelected =
                    _answered && selected && i != _current.correctIndex;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: _answered ? null : () => _select(i),
                      style: FilledButton.styleFrom(
                        backgroundColor: correct
                            ? Colors.green.shade700
                            : wrongSelected
                            ? Colors.red.shade700
                            : null,
                        padding: const EdgeInsets.symmetric(vertical: 20),
                      ),
                      child: Text(
                        _current.options[i],
                        style: Theme.of(context).textTheme.headlineSmall
                            ?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w900,
                            ),
                      ),
                    ),
                  ),
                );
              }),
            )
          else ...[
            Builder(
              builder: (context) {
                final shownWord = _current.options[_trueFalseCandidateIndex];
                final shownAsset = widget
                    .optionImageByWord[normalizeWordForLetters(shownWord)];

                return Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: Theme.of(context).colorScheme.outline,
                    ),
                  ),
                  child: Column(
                    children: [
                      SizedBox(
                        height: wide ? 260 : 210,
                        child: shownAsset != null
                            ? ActivityAssetImage(
                                assetPath: shownAsset,
                                semanticsLabel: shownWord,
                              )
                            : _WordFallbackVisual(word: shownWord),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        shownWord,
                        style: Theme.of(context).textTheme.headlineSmall
                            ?.copyWith(fontWeight: FontWeight.w900),
                      ),
                    ],
                  ),
                );
              },
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: FilledButton(
                    onPressed: _answered ? null : () => _selectTrueFalse(true),
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 18),
                    ),
                    child: const UpperText('VERDADERO'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: FilledButton(
                    onPressed: _answered ? null : () => _selectTrueFalse(false),
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 18),
                      backgroundColor: Colors.deepOrange.shade600,
                    ),
                    child: const UpperText('FALSO'),
                  ),
                ),
              ],
            ),
          ],
          if (_answered) ...[
            const SizedBox(height: 6),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: isAnsweredCorrect
                    ? Colors.green.shade50
                    : Colors.red.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isAnsweredCorrect
                      ? Colors.green.shade600
                      : Colors.red.shade600,
                ),
              ),
              child: Text(answerFeedback()),
            ),
            const SizedBox(height: 10),
            FilledButton.icon(
              onPressed: _next,
              icon: Icon(
                completed ? Icons.replay_rounded : Icons.navigate_next_rounded,
              ),
              label: UpperText(
                completed ? 'VOLVER A EMPEZAR' : 'SIGUIENTE PREGUNTA',
              ),
            ),
          ],
        ],
      ),
    );

    final readingPane = Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FFFC),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFCAE7DC)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'FICHA DE INVESTIGACIÓN',
            style: TextStyle(
              color: Color(0xFF2E9D6C),
              fontWeight: FontWeight.w900,
              letterSpacing: 0.6,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            readingTitle,
            style: Theme.of(
              context,
            ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 10),
          Text(
            readingText,
            style: Theme.of(
              context,
            ).textTheme.bodyLarge?.copyWith(height: 1.45),
          ),
        ],
      ),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'JUEGO INTERACTIVO',
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: 10),
        questionPane,
        const SizedBox(height: 12),
        Text(
          'APOYO DE LECTURA',
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: 8),
        readingPane,
      ],
    );
  }
}

class _WordFallbackVisual extends StatelessWidget {
  const _WordFallbackVisual({required this.word});

  final String word;

  static const _emojiByWord = {
    'PERRO': '🐶',
    'GATO': '🐱',
    'CABALLO': '🐴',
    'VACA': '🐮',
    'LEÓN': '🦁',
    'LEON': '🦁',
    'OSO': '🐻',
    'PÁJARO': '🐦',
    'PAJARO': '🐦',
    'PEZ': '🐟',
    'CONEJO': '🐰',
  };

  @override
  Widget build(BuildContext context) {
    final normalized = normalizeWordForLetters(word).toUpperCase();
    final emoji = _emojiByWord[normalized];
    return Container(
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Theme.of(context).colorScheme.outline),
      ),
      child: emoji != null
          ? Text(emoji, style: const TextStyle(fontSize: 92))
          : const Icon(Icons.image_not_supported_rounded, size: 62),
    );
  }
}

class _ListSection extends StatelessWidget {
  const _ListSection({required this.title, required this.items});

  final String title;
  final List<String> items;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return const SizedBox.shrink();
    }
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 6),
          ...items.map((item) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Text('• $item'),
            );
          }),
        ],
      ),
    );
  }
}
