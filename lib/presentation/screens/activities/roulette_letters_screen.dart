import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../application/providers/app_providers.dart';
import '../../../core/utils/text_utils.dart';
import '../../../domain/models/activity_type.dart';
import '../../../domain/models/category.dart';
import '../../../domain/models/difficulty.dart';
import '../../../domain/models/item.dart';
import '../../widgets/activity_asset_image.dart';
import '../../widgets/game_style.dart';
import '../../widgets/upper_text.dart';

enum _RouletteMode { vocal, nivel }

class RouletteLettersScreen extends ConsumerStatefulWidget {
  const RouletteLettersScreen({
    super.key,
    required this.category,
    required this.difficulty,
  });

  final AppCategory category;
  final Difficulty difficulty;

  @override
  ConsumerState<RouletteLettersScreen> createState() =>
      _RouletteLettersScreenState();
}

class _RouletteLettersScreenState extends ConsumerState<RouletteLettersScreen> {
  final Random _random = Random();

  static const _vowels = ['A', 'E', 'I', 'O', 'U'];

  _RouletteMode _mode = _RouletteMode.vocal;
  int _selectedLevel = 1;
  String _selectedVowel = 'A';
  bool _randomVowel = false;

  bool _isSpinning = false;
  double _turns = 0;
  List<Item> _wheelItems = [];
  List<Item> _batchInitialItems = [];
  List<String> _wordOptions = [];

  String _activeVowel = '?';
  Item? _selectedItem;
  bool _awaitingWordChoice = false;
  String _feedback =
      'ELIGE VOCAL O NIVEL Y GIRA PARA VER OBJETOS CON ESA VOCAL';

  List<Item> _initialPool = [];
  List<Item> _pool = [];

  @override
  void initState() {
    super.initState();
    _loadItems();
  }

  void _loadItems() {
    final dataset = ref.read(datasetRepositoryProvider);
    final items = dataset.getAllItems().where((item) {
      final word = (item.word ?? '').trim();
      return word.isNotEmpty && item.activityType == ActivityType.imagenPalabra;
    }).toList();

    setState(() {
      _initialPool = items;
      _pool = items;
      _wheelItems = [];
      _batchInitialItems = [];
      _wordOptions = [];
      _selectedItem = null;
      _awaitingWordChoice = false;
      _activeVowel = '?';
      _feedback = items.isEmpty
          ? 'NO HAY OBJETOS DISPONIBLES PARA LA RULETA'
          : 'ELIGE VOCAL O NIVEL Y GIRA PARA VER OBJETOS CON ESA VOCAL';
    });
    if (items.isNotEmpty) {
      _refreshWheelPreview();
    }
  }

  bool _matchesLevel(String word, int level) {
    switch (level) {
      case 1:
        return _vowels.any((v) => startsWithLetter(word, v));
      case 2:
        return _vowels.any((v) => containsLetterInMiddle(word, v));
      default:
        return _vowels.any((v) => endsWithLetter(word, v));
    }
  }

  List<Item> _baseByCategoryFrom(List<Item> source) {
    if (widget.category == AppCategory.mixta) {
      return source;
    }
    return source.where((item) => item.category == widget.category).toList();
  }

  List<Item> _baseByCategory() {
    return _baseByCategoryFrom(_pool);
  }

  List<Item> _eligibleItemsFor(String vowel) {
    final source = _baseByCategory();
    if (_mode == _RouletteMode.vocal) {
      return source
          .where((item) => containsLetter(item.word ?? '', vowel))
          .toList();
    }

    return source.where((item) {
      final word = item.word ?? '';
      final inLevel = _matchesLevel(word, _selectedLevel);
      return inLevel && containsLetter(word, vowel);
    }).toList();
  }

  String _pickVowelForLevel(List<Item> source) {
    final shuffled = [..._vowels]..shuffle(_random);
    for (final vowel in shuffled) {
      final filtered = source.where((item) {
        final word = item.word ?? '';
        return _matchesLevel(word, _selectedLevel) &&
            containsLetter(word, vowel);
      });
      if (filtered.isNotEmpty) {
        return vowel;
      }
    }
    return shuffled.first;
  }

  String _levelDescription(int level) {
    return switch (level) {
      1 => 'NIVEL 1: PALABRAS QUE INICIAN CON VOCAL',
      2 => 'NIVEL 2: VOCAL EN MEDIO DE LA PALABRA',
      _ => 'NIVEL 3: PALABRAS QUE TERMINAN EN VOCAL',
    };
  }

  int _totalWordsForCurrentCategory() {
    if (_batchInitialItems.isNotEmpty) {
      return _batchInitialItems.length;
    }
    return 8;
  }

  void _markCurrentAsSolved() {
    final selected = _selectedItem;
    if (selected == null || _isSpinning || !_awaitingWordChoice) {
      return;
    }
    final nextWheel = _wheelItems
        .where((item) => item.id != selected.id)
        .toList();
    final remaining = nextWheel.length;
    final solvedWord = (selected.word ?? '').trim().toUpperCase();

    setState(() {
      _wheelItems = nextWheel;
      _selectedItem = null;
      _wordOptions = [];
      _awaitingWordChoice = false;
      if (remaining == 0) {
        _activeVowel = '-';
        _feedback = solvedWord.isEmpty
            ? '¡COMPLETASTE LA RULETA! YA NO QUEDAN PALABRAS.'
            : '¡CORRECTO! $solvedWord ELIMINADA. YA NO QUEDAN PALABRAS.';
      } else {
        _feedback = solvedWord.isEmpty
            ? '¡CORRECTO! PALABRA ELIMINADA. QUEDAN $remaining.'
            : '¡CORRECTO! $solvedWord ELIMINADA. QUEDAN $remaining.';
      }
    });
  }

  void _restartGame() {
    if (_initialPool.isEmpty) {
      _loadItems();
      return;
    }
    setState(() {
      _mode = _RouletteMode.vocal;
      _selectedLevel = 1;
      _selectedVowel = 'A';
      _randomVowel = false;
      _pool = [..._initialPool];
      _wheelItems = [];
      _batchInitialItems = [];
      _wordOptions = [];
      _selectedItem = null;
      _activeVowel = '?';
      _awaitingWordChoice = false;
      _isSpinning = false;
      _turns = 0;
      _feedback = 'ELIGE VOCAL O NIVEL Y GIRA PARA VER OBJETOS CON ESA VOCAL';
    });
    _refreshWheelPreview();
  }

  List<Item> _pickWheelItems(List<Item> eligible, {bool randomize = true}) {
    final unique = <String, Item>{};
    for (final item in eligible) {
      unique.putIfAbsent(item.id, () => item);
    }
    final output = unique.values.toList();
    if (output.isEmpty) {
      return const [];
    }
    if (randomize) {
      output.shuffle(_random);
    }
    return output.take(min(8, output.length)).toList();
  }

  int _selectedIndexFromTurns({
    required double turns,
    required int segmentCount,
  }) {
    if (segmentCount <= 0) {
      return 0;
    }
    final step = (2 * pi) / segmentCount;
    final pointerAngle = -pi / 2;
    final rotation = 2 * pi * turns;
    var bestIndex = 0;
    var minDistance = double.infinity;
    for (var i = 0; i < segmentCount; i++) {
      final centerAngle = -pi / 2 + (step * i) + rotation;
      final diff = (pointerAngle - centerAngle).abs() % (2 * pi);
      final circularDistance = diff > pi ? (2 * pi - diff) : diff;
      if (circularDistance < minDistance) {
        minDistance = circularDistance;
        bestIndex = i;
      }
    }
    return bestIndex;
  }

  Future<void> _spin() async {
    if (_isSpinning) {
      return;
    }
    if (_awaitingWordChoice) {
      setState(() {
        _feedback = 'PRIMERO ELIGE LA PALABRA CORRECTA DEL OBJETO';
      });
      return;
    }

    final vowel = _mode == _RouletteMode.vocal
        ? (_randomVowel
              ? _vowels[_random.nextInt(_vowels.length)]
              : _selectedVowel)
        : _pickVowelForLevel(_baseByCategoryFrom(_initialPool));

    final wheelItems = _wheelItems.isNotEmpty
        ? _wheelItems
        : _buildFixedBatch(vowel);
    if (wheelItems.isEmpty) {
      setState(() {
        _feedback = 'NO ENCONTRÉ OBJETOS PARA CONSTRUIR UNA RULETA FIJA';
        _activeVowel = vowel;
      });
      return;
    }

    final spinTurns = 4 + _random.nextDouble() * 2;
    final finalTurns = _turns + spinTurns;
    final selectedIndex = _selectedIndexFromTurns(
      turns: finalTurns,
      segmentCount: wheelItems.length,
    );
    final selected = wheelItems[selectedIndex];

    setState(() {
      _isSpinning = true;
      _turns += spinTurns;
      _wheelItems = wheelItems;
      _selectedItem = null;
      _wordOptions = [];
      _awaitingWordChoice = false;
      _activeVowel = vowel;
      _feedback = 'GIRANDO...';
    });

    await Future<void>.delayed(const Duration(milliseconds: 1500));
    if (!mounted) {
      return;
    }

    setState(() {
      _isSpinning = false;
      _selectedItem = selected;
      _wordOptions = _buildWordOptions(selected, wheelItems);
      _awaitingWordChoice = true;
      _feedback = 'ELIGE LA PALABRA CORRECTA DEL OBJETO';
    });
  }

  List<Item> _buildFixedBatch(String vowel) {
    final eligible = _eligibleItemsFor(vowel);
    final batch = _pickWheelItems(eligible, randomize: true);
    _batchInitialItems = [...batch];
    return batch;
  }

  List<Item> _eligibleItemsForVowelFrom(List<Item> source, String vowel) {
    if (_mode == _RouletteMode.vocal) {
      return source
          .where((item) => containsLetter(item.word ?? '', vowel))
          .toList();
    }
    return source.where((item) {
      final word = item.word ?? '';
      return _matchesLevel(word, _selectedLevel) && containsLetter(word, vowel);
    }).toList();
  }

  void _refreshWheelPreview() {
    final source = _baseByCategory();
    if (source.isEmpty) {
      setState(() {
        _wheelItems = [];
        _batchInitialItems = [];
        _wordOptions = [];
        _selectedItem = null;
        _awaitingWordChoice = false;
        _activeVowel = '?';
        _feedback = 'NO HAY OBJETOS DISPONIBLES PARA ESTA CATEGORÍA';
      });
      return;
    }

    String chosenVowel = _selectedVowel;
    if (_mode == _RouletteMode.vocal) {
      if (_randomVowel) {
        final shuffled = [..._vowels]..shuffle(_random);
        chosenVowel = shuffled.firstWhere(
          (v) => _eligibleItemsForVowelFrom(source, v).isNotEmpty,
          orElse: () => _selectedVowel,
        );
      } else {
        final selectedHasItems = _eligibleItemsForVowelFrom(
          source,
          _selectedVowel,
        ).isNotEmpty;
        if (!selectedHasItems) {
          chosenVowel = _vowels.firstWhere(
            (v) => _eligibleItemsForVowelFrom(source, v).isNotEmpty,
            orElse: () => _selectedVowel,
          );
        }
      }
    } else {
      chosenVowel = _pickVowelForLevel(source);
    }

    var eligible = _eligibleItemsForVowelFrom(source, chosenVowel);
    if (eligible.isEmpty) {
      for (final v in _vowels) {
        final fallback = _eligibleItemsForVowelFrom(source, v);
        if (fallback.isNotEmpty) {
          chosenVowel = v;
          eligible = fallback;
          break;
        }
      }
    }

    final previewBatch = _pickWheelItems(eligible, randomize: true);
    setState(() {
      _selectedVowel = chosenVowel;
      _wheelItems = previewBatch;
      _batchInitialItems = [...previewBatch];
      _wordOptions = [];
      _selectedItem = null;
      _awaitingWordChoice = false;
      _turns = 0;
      _activeVowel = previewBatch.isEmpty ? '?' : chosenVowel;
      if (previewBatch.isEmpty) {
        _feedback = 'NO HAY PALABRAS VÁLIDAS PARA LOS FILTROS ACTUALES';
      } else if (!_feedback.startsWith('¡CORRECTO!')) {
        _feedback = 'GIRA Y LUEGO ELIGE LA PALABRA CORRECTA';
      }
    });
  }

  List<String> _buildWordOptions(Item selected, List<Item> wheel) {
    final selectedWord = (selected.word ?? '').trim();
    final distractors =
        wheel
            .where((item) => item.id != selected.id)
            .map((item) => (item.word ?? '').trim())
            .where((word) => word.isNotEmpty)
            .toList()
          ..shuffle(_random);
    final options = <String>[
      selectedWord,
      ...distractors.take(3),
    ].where((word) => word.isNotEmpty).toSet().toList()..shuffle(_random);
    return options;
  }

  void _selectWordOption(String word) {
    final selected = _selectedItem;
    if (selected == null || !_awaitingWordChoice || _isSpinning) {
      return;
    }
    final expected = (selected.word ?? '').trim();
    final isCorrect =
        normalizeForComparison(word, ignoreAccents: true) ==
        normalizeForComparison(expected, ignoreAccents: true);
    if (!isCorrect) {
      setState(() {
        _feedback = 'INTENTA OTRA VEZ: OBSERVA EL OBJETO Y ELIGE SU PALABRA';
      });
      return;
    }
    _markCurrentAsSolved();
  }

  Widget _buildTabletLandscapeBody({
    required int totalWords,
    required int solvedWords,
    required int remainingWords,
    required bool completed,
    required List<Item> wheelItems,
  }) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1180),
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Column(
            children: [
              GameProgressHeader(
                label: 'TU PROGRESO',
                current: solvedWords,
                total: totalWords,
              ),
              const SizedBox(height: 8),
              Expanded(
                child: Row(
                  children: [
                    Expanded(
                      flex: 44,
                      child: Column(
                        children: [
                          Expanded(
                            child: GamePanel(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  UpperText(
                                    'CONFIGURACIÓN',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w900,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  SegmentedButton<_RouletteMode>(
                                    segments: const [
                                      ButtonSegment(
                                        value: _RouletteMode.vocal,
                                        label: UpperText('VOCAL'),
                                      ),
                                      ButtonSegment(
                                        value: _RouletteMode.nivel,
                                        label: UpperText('NIVEL'),
                                      ),
                                    ],
                                    selected: {_mode},
                                    onSelectionChanged: (value) {
                                      setState(() {
                                        _mode = value.first;
                                      });
                                      _refreshWheelPreview();
                                    },
                                  ),
                                  const SizedBox(height: 8),
                                  if (_mode == _RouletteMode.vocal)
                                    Wrap(
                                      spacing: 6,
                                      runSpacing: 6,
                                      children: [
                                        ..._vowels.map((v) {
                                          return ChoiceChip(
                                            selected:
                                                !_randomVowel &&
                                                _selectedVowel == v,
                                            label: UpperText(v),
                                            onSelected: (_) {
                                              setState(() {
                                                _selectedVowel = v;
                                                _randomVowel = false;
                                              });
                                              _refreshWheelPreview();
                                            },
                                          );
                                        }),
                                        ChoiceChip(
                                          selected: _randomVowel,
                                          label: const UpperText('ALEATORIA'),
                                          onSelected: (_) {
                                            setState(() {
                                              _randomVowel = true;
                                            });
                                            _refreshWheelPreview();
                                          },
                                        ),
                                      ],
                                    )
                                  else
                                    Wrap(
                                      spacing: 6,
                                      runSpacing: 6,
                                      children: [1, 2, 3].map((level) {
                                        return ChoiceChip(
                                          selected: _selectedLevel == level,
                                          label: UpperText('NIVEL $level'),
                                          onSelected: (_) {
                                            setState(() {
                                              _selectedLevel = level;
                                            });
                                            _refreshWheelPreview();
                                          },
                                        );
                                      }).toList(),
                                    ),
                                  const Spacer(),
                                  const UpperText(
                                    'PALABRAS RELACIONADAS',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w900,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  if (_selectedItem == null)
                                    const UpperText(
                                      'GIRA Y LUEGO ELIGE LA PALABRA CORRECTA',
                                    )
                                  else
                                    Wrap(
                                      spacing: 6,
                                      runSpacing: 6,
                                      children: _wordOptions.map((word) {
                                        return FilledButton.tonal(
                                          onPressed: _isSpinning
                                              ? null
                                              : () => _selectWordOption(word),
                                          child: UpperText(word),
                                        );
                                      }).toList(),
                                    ),
                                  const SizedBox(height: 8),
                                  UpperText(_feedback, maxLines: 4),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          GamePanel(
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                UpperText('TOTAL: $totalWords'),
                                UpperText('ACERTADAS: $solvedWords'),
                                UpperText('PENDIENTES: $remainingWords'),
                              ],
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Expanded(
                                child: FilledButton.icon(
                                  onPressed: _isSpinning || completed
                                      ? null
                                      : _spin,
                                  icon: const Icon(Icons.casino_rounded),
                                  label: UpperText(
                                    _isSpinning
                                        ? 'GIRANDO'
                                        : completed
                                        ? 'COMPLETADA'
                                        : 'GIRAR',
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: OutlinedButton.icon(
                                  onPressed: _isSpinning ? null : _restartGame,
                                  icon: const Icon(Icons.restart_alt_rounded),
                                  label: const UpperText('REINICIAR'),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      flex: 56,
                      child: GamePanel(
                        child: Column(
                          children: [
                            Expanded(
                              child: Center(
                                child: Stack(
                                  alignment: Alignment.center,
                                  children: [
                                    AnimatedRotation(
                                      turns: _turns,
                                      duration: const Duration(
                                        milliseconds: 1500,
                                      ),
                                      curve: Curves.easeOutCubic,
                                      child: _RouletteWheelVisual(
                                        items: wheelItems,
                                        size: 420,
                                      ),
                                    ),
                                    const Positioned(
                                      top: 4,
                                      child: Icon(
                                        Icons.arrow_drop_down_rounded,
                                        size: 76,
                                        color: Color(0xFF00695C),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 18,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(14),
                                color: Colors.teal.shade50,
                                border: Border.all(color: Colors.teal.shade300),
                              ),
                              child: UpperText(
                                'VOCAL: $_activeVowel',
                                style: const TextStyle(
                                  fontSize: 30,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ),
                            if (_selectedItem != null) ...[
                              const SizedBox(height: 8),
                              UpperText(
                                'OBJETO: ${_selectedItem!.word ?? ''}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final isTabletLandscape = isPrimaryTabletLandscape(context);
    final isTablet = width >= 720;

    final totalWords = _totalWordsForCurrentCategory();
    final remainingWords = _wheelItems.isNotEmpty
        ? _wheelItems.length
        : totalWords;
    final solvedWords = max(0, totalWords - remainingWords);
    final completed = _batchInitialItems.isNotEmpty && _wheelItems.isEmpty;
    final wheelItems = _wheelItems;

    if (isTabletLandscape) {
      return GameScaffold(
        title: 'RULETA DE OBJETOS Y VOCALES',
        instructionText: _mode == _RouletteMode.vocal
            ? 'GIRA LA RULETA Y PRACTICA OBJETOS POR VOCAL'
            : 'GIRA LA RULETA Y PRACTICA OBJETOS POR NIVEL',
        progressCurrent: solvedWords,
        progressTotal: totalWords,
        body: _buildTabletLandscapeBody(
          totalWords: totalWords,
          solvedWords: solvedWords,
          remainingWords: remainingWords,
          completed: completed,
          wheelItems: wheelItems,
        ),
      );
    }

    return GameScaffold(
      title: 'RULETA DE OBJETOS Y VOCALES',
      instructionText: _mode == _RouletteMode.vocal
          ? 'GIRA LA RULETA Y PRACTICA OBJETOS POR VOCAL'
          : 'GIRA LA RULETA Y PRACTICA OBJETOS POR NIVEL',
      progressCurrent: solvedWords,
      progressTotal: totalWords,
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1080),
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              GameProgressHeader(
                label: 'TU PROGRESO',
                current: solvedWords,
                total: totalWords,
              ),
              const SizedBox(height: 10),
              GamePanel(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    UpperText(
                      'CONFIGURACIÓN DE RULETA',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 10),
                    SegmentedButton<_RouletteMode>(
                      segments: const [
                        ButtonSegment(
                          value: _RouletteMode.vocal,
                          icon: Icon(Icons.record_voice_over_rounded),
                          label: UpperText('POR VOCAL'),
                        ),
                        ButtonSegment(
                          value: _RouletteMode.nivel,
                          icon: Icon(Icons.layers_rounded),
                          label: UpperText('POR NIVEL'),
                        ),
                      ],
                      selected: {_mode},
                      onSelectionChanged: (value) {
                        setState(() {
                          _mode = value.first;
                        });
                        _refreshWheelPreview();
                      },
                    ),
                    const SizedBox(height: 10),
                    if (_mode == _RouletteMode.vocal)
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          ..._vowels.map((v) {
                            return ChoiceChip(
                              selected: !_randomVowel && _selectedVowel == v,
                              label: UpperText('VOCAL $v'),
                              onSelected: (_) {
                                setState(() {
                                  _selectedVowel = v;
                                  _randomVowel = false;
                                });
                                _refreshWheelPreview();
                              },
                            );
                          }),
                          ChoiceChip(
                            selected: _randomVowel,
                            label: const UpperText('ALEATORIA'),
                            onSelected: (_) {
                              setState(() {
                                _randomVowel = true;
                              });
                              _refreshWheelPreview();
                            },
                          ),
                        ],
                      )
                    else
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [1, 2, 3].map((level) {
                              return ChoiceChip(
                                selected: _selectedLevel == level,
                                label: UpperText('NIVEL $level'),
                                onSelected: (_) {
                                  setState(() {
                                    _selectedLevel = level;
                                  });
                                  _refreshWheelPreview();
                                },
                              );
                            }).toList(),
                          ),
                          const SizedBox(height: 8),
                          UpperText(_levelDescription(_selectedLevel)),
                        ],
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              GamePanel(child: UpperText(_feedback)),
              const SizedBox(height: 10),
              GamePanel(
                child: Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    UpperText('TOTAL: $totalWords'),
                    UpperText('ACERTADAS: $solvedWords'),
                    UpperText('PENDIENTES: $remainingWords'),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              Center(
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    AnimatedRotation(
                      turns: _turns,
                      duration: const Duration(milliseconds: 1500),
                      curve: Curves.easeOutCubic,
                      child: _RouletteWheelVisual(
                        items: wheelItems,
                        size: isTablet ? 540 : 380,
                      ),
                    ),
                    Positioned(
                      top: 8,
                      child: Icon(
                        Icons.arrow_drop_down_rounded,
                        size: isTablet ? 84 : 68,
                        color: const Color(0xFF00695C),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    color: Colors.teal.shade50,
                    border: Border.all(color: Colors.teal.shade300),
                  ),
                  child: UpperText(
                    'VOCAL: $_activeVowel',
                    style: const TextStyle(
                      fontSize: 34,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              FilledButton.icon(
                onPressed: _isSpinning || completed ? null : _spin,
                icon: const Icon(Icons.casino_rounded),
                label: UpperText(
                  _isSpinning
                      ? 'GIRANDO...'
                      : completed
                      ? 'RULETA COMPLETADA'
                      : 'GIRAR RULETA',
                ),
              ),
              const SizedBox(height: 8),
              OutlinedButton.icon(
                onPressed: _isSpinning ? null : _restartGame,
                icon: const Icon(Icons.restart_alt_rounded),
                label: const UpperText('REINICIAR TODO'),
              ),
              if (_selectedItem != null) ...[
                const SizedBox(height: 14),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        SizedBox(
                          height: isTablet ? 240 : 200,
                          child: ActivityAssetImage(
                            assetPath: _selectedItem!.imageAsset,
                            semanticsLabel: _selectedItem!.word,
                          ),
                        ),
                        const SizedBox(height: 6),
                        const UpperText('OBJETO ELEGIDO'),
                        const SizedBox(height: 8),
                        const UpperText('SE ELIMINA AUTOMÁTICAMENTE...'),
                      ],
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _RouletteWheelVisual extends StatelessWidget {
  const _RouletteWheelVisual({required this.items, required this.size});

  final List<Item> items;
  final double size;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return Container(
        width: size,
        height: size,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: Theme.of(context).colorScheme.primary,
            width: 4,
          ),
          color: const Color(0xFFEAF9F4),
        ),
        child: const UpperText('SIN ÍCONOS'),
      );
    }

    final step = (2 * pi) / items.length;
    final iconSize = size * 0.17;

    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        fit: StackFit.expand,
        children: [
          CustomPaint(
            painter: _WheelSegmentsPainter(segmentCount: items.length),
          ),
          for (var i = 0; i < items.length; i++)
            Builder(
              builder: (context) {
                final angle = -pi / 2 + (step * i);
                final dx = cos(angle) * 0.60;
                final dy = sin(angle) * 0.60;
                return Align(
                  alignment: Alignment(dx, dy),
                  child: SizedBox(
                    width: iconSize,
                    height: iconSize,
                    child: Padding(
                      padding: const EdgeInsets.all(4),
                      child: ActivityAssetImage(
                        assetPath: items[i].imageAsset,
                        semanticsLabel: items[i].word,
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                );
              },
            ),
          Center(
            child: Container(
              width: size * 0.14,
              height: size * 0.14,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const RadialGradient(
                  colors: [Color(0xFFFFE8A6), Color(0xFFD39B19)],
                ),
                border: Border.all(color: const Color(0xFF946800), width: 2),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _WheelSegmentsPainter extends CustomPainter {
  const _WheelSegmentsPainter({required this.segmentCount});

  final int segmentCount;

  static const _palette = [
    Color(0xFFE5F1FF),
    Color(0xFFE6FFE8),
    Color(0xFFFFF2D9),
    Color(0xFFF6E9FF),
    Color(0xFFE9FFF8),
    Color(0xFFFFEFEF),
    Color(0xFFF1F5FF),
    Color(0xFFEFFFEA),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    final rect = Rect.fromCircle(center: center, radius: radius);
    final step = (2 * pi) / segmentCount;

    for (var i = 0; i < segmentCount; i++) {
      final start = -pi / 2 - (step / 2) + step * i;
      final path = Path()
        ..moveTo(center.dx, center.dy)
        ..arcTo(rect, start, step, false)
        ..close();

      final fill = Paint()
        ..style = PaintingStyle.fill
        ..color = _palette[i % _palette.length];
      canvas.drawPath(path, fill);

      final border = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..color = Colors.white;
      canvas.drawPath(path, border);
    }

    final outer = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6
      ..color = const Color(0xFF1A6FB2);
    canvas.drawCircle(center, radius - 3, outer);
  }

  @override
  bool shouldRepaint(covariant _WheelSegmentsPainter oldDelegate) {
    return oldDelegate.segmentCount != segmentCount;
  }
}
