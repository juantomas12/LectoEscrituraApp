import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../application/providers/app_providers.dart';
import '../../../core/utils/text_utils.dart';
import '../../../domain/models/activity_result.dart';
import '../../../domain/models/activity_type.dart';
import '../../../domain/models/category.dart';
import '../../../domain/models/difficulty.dart';
import '../../../domain/models/item.dart';
import '../../../domain/models/level.dart';
import '../../viewmodels/progress_view_model.dart';
import '../../viewmodels/settings_view_model.dart';
import '../../widgets/activity_asset_image.dart';
import '../../widgets/upper_text.dart';
import '../results_screen.dart';

enum WriteMode { copia, semicopia, dictado }

extension WriteModeX on WriteMode {
  String get label => switch (this) {
    WriteMode.copia => 'COPIA',
    WriteMode.semicopia => 'SEMICOPIA',
    WriteMode.dictado => 'DICTADO',
  };
}

class WriteWordScreen extends ConsumerStatefulWidget {
  const WriteWordScreen({
    super.key,
    required this.category,
    required this.difficulty,
  });

  final AppCategory category;
  final Difficulty difficulty;

  @override
  ConsumerState<WriteWordScreen> createState() => _WriteWordScreenState();
}

class _WriteWordScreenState extends ConsumerState<WriteWordScreen> {
  final Random _random = Random();
  final TextEditingController _controller = TextEditingController();

  List<Item> _items = [];
  int _index = 0;
  WriteMode _mode = WriteMode.copia;

  String _feedback = 'ESCRIBE LA PALABRA';
  bool _isLoading = true;
  int _triesForCurrent = 0;

  int _correct = 0;
  int _incorrect = 0;
  int _streak = 0;
  int _bestStreak = 0;

  DateTime _startedAt = DateTime.now();

  Item? get _currentItem => _index < _items.length ? _items[_index] : null;

  @override
  void initState() {
    super.initState();
    _prepareActivity();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _prepareActivity() async {
    final dataset = ref.read(datasetRepositoryProvider);
    final progressMap = ref.read(itemProgressMapProvider);
    final limit = widget.difficulty == Difficulty.primaria ? 5 : 7;

    final items = dataset.getPrioritizedItems(
      category: widget.category,
      level: AppLevel.uno,
      activityType: ActivityType.imagenPalabra,
      difficulty: widget.difficulty,
      progressMap: progressMap,
      limit: limit,
    );

    final selectedItems = items.isNotEmpty
        ? items
        : dataset.getItems(
            category: widget.category,
            level: AppLevel.uno,
            activityType: ActivityType.imagenPalabra,
          );

    selectedItems.shuffle(_random);

    if (!mounted) {
      return;
    }

    setState(() {
      _items = selectedItems;
      _index = 0;
      _mode = WriteMode.copia;
      _feedback = 'ESCRIBE LA PALABRA';
      _triesForCurrent = 0;
      _correct = 0;
      _incorrect = 0;
      _streak = 0;
      _bestStreak = 0;
      _startedAt = DateTime.now();
      _controller.clear();
      _isLoading = false;
    });
  }

  Future<void> _validate() async {
    final item = _currentItem;
    if (item == null) {
      return;
    }

    final settings = ref.read(settingsViewModelProvider);
    final expected = item.word ?? '';

    final normalizedInput = normalizeForComparison(
      _controller.text,
      ignoreAccents: settings.accentTolerance,
    );
    final normalizedExpected = normalizeForComparison(
      expected,
      ignoreAccents: settings.accentTolerance,
    );

    final isCorrect = normalizedInput == normalizedExpected;

    await ref
        .read(progressViewModelProvider.notifier)
        .registerAttempt(itemId: item.id, correct: isCorrect);

    if (!mounted) {
      return;
    }

    if (isCorrect) {
      setState(() {
        _correct++;
        _streak++;
        _bestStreak = max(_bestStreak, _streak);
        _feedback = 'CORRECTO';
        _triesForCurrent = 0;
      });

      if (_index == _items.length - 1) {
        await _finishActivity();
        return;
      }

      await Future<void>.delayed(const Duration(milliseconds: 500));
      if (!mounted) {
        return;
      }
      setState(() {
        _index++;
        _controller.clear();
        _feedback = 'SIGUIENTE PALABRA';
      });
      return;
    }

    setState(() {
      _incorrect++;
      _streak = 0;
      _triesForCurrent++;
      _feedback = 'INTÉNTALO DE NUEVO';
    });
  }

  Future<void> _playAudio(String text) async {
    if (!ref.read(settingsViewModelProvider).audioEnabled) {
      return;
    }
    await ref.read(ttsServiceProvider).speak(text);
  }

  Future<void> _finishActivity() async {
    final result = ActivityResult(
      id: 'RES-${DateTime.now().millisecondsSinceEpoch}',
      category: widget.category,
      level: AppLevel.uno,
      activityType: ActivityType.escribirPalabra,
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
    final settings = ref.watch(settingsViewModelProvider);
    final current = _currentItem;
    final width = MediaQuery.sizeOf(context).width;
    final isDesktop = width >= 1000;
    final contentWidth = isDesktop ? 900.0 : 760.0;
    final imageHeight = isDesktop ? 150.0 : 210.0;

    return Scaffold(
      appBar: AppBar(
        title: const UpperText('IMAGEN CON PALABRA PARA ESCRIBIR'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : current == null
          ? const Center(child: UpperText('NO HAY CONTENIDO DISPONIBLE'))
          : Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: contentWidth),
                child: ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      children: [
                        const Icon(Icons.edit_note),
                        const SizedBox(width: 10),
                        Expanded(
                          child: UpperText(
                            'PALABRA ${_index + 1} DE ${_items.length}',
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                SegmentedButton<WriteMode>(
                  segments: const [
                    ButtonSegment(
                      value: WriteMode.copia,
                      label: UpperText('COPIA'),
                    ),
                    ButtonSegment(
                      value: WriteMode.semicopia,
                      label: UpperText('SEMICOPIA'),
                    ),
                    ButtonSegment(
                      value: WriteMode.dictado,
                      label: UpperText('DICTADO'),
                    ),
                  ],
                  selected: {_mode},
                  onSelectionChanged: (value) {
                    setState(() {
                      _mode = value.first;
                      _controller.clear();
                      _feedback = 'ESCRIBE LA PALABRA';
                      _triesForCurrent = 0;
                    });
                  },
                ),
                const SizedBox(height: 10),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        SizedBox(
                          height: imageHeight,
                          child: ActivityAssetImage(
                            assetPath: current.imageAsset,
                            semanticsLabel: current.word,
                          ),
                        ),
                        const SizedBox(height: 10),
                        if (_mode == WriteMode.copia)
                          UpperText(
                            current.word ?? '',
                            style: Theme.of(context).textTheme.headlineSmall,
                          ),
                        if (_mode == WriteMode.semicopia)
                          UpperText(
                            buildSemiCopyHint(current.word ?? ''),
                            style: Theme.of(context).textTheme.headlineSmall,
                          ),
                        if (_mode == WriteMode.dictado)
                          Column(
                            children: [
                              const UpperText('ESCUCHA Y ESCRIBE'),
                              const SizedBox(height: 8),
                              FilledButton.icon(
                                onPressed: settings.audioEnabled
                                    ? () => _playAudio(current.word ?? '')
                                    : null,
                                icon: const Icon(Icons.volume_up),
                                label: const UpperText('REPRODUCIR AUDIO'),
                              ),
                            ],
                          ),
                        if (settings.showHints && _triesForCurrent >= 2)
                          Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: UpperText(
                              'PISTA: ${buildSemiCopyHint(current.word ?? '')}',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: _controller,
                  textCapitalization: TextCapitalization.characters,
                  style: Theme.of(context).textTheme.headlineSmall,
                  onChanged: (value) {
                    final upper = value.toUpperCase();
                    if (upper != value) {
                      _controller.value = _controller.value.copyWith(
                        text: upper,
                        selection: TextSelection.collapsed(
                          offset: upper.length,
                        ),
                      );
                    }
                  },
                  decoration: InputDecoration(
                    hintText: 'ESCRIBE AQUÍ',
                    border: const OutlineInputBorder(),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                ),
                const SizedBox(height: 10),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: UpperText(_feedback),
                  ),
                ),
                const SizedBox(height: 10),
                FilledButton(
                  onPressed: _validate,
                  child: const UpperText('VALIDAR'),
                ),
                  ],
                ),
              ),
            ),
    );
  }
}
