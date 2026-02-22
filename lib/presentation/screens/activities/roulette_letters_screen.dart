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

  String _activeVowel = '?';
  Item? _selectedItem;
  String _feedback =
      'ELIGE VOCAL O NIVEL Y GIRA PARA VER OBJETOS CON ESA VOCAL';

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
      _pool = items;
    });
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

  List<Item> _baseByCategory() {
    if (widget.category == AppCategory.mixta) {
      return _pool;
    }
    return _pool.where((item) => item.category == widget.category).toList();
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
    if (_isSpinning || _pool.isEmpty) {
      return;
    }

    final source = _baseByCategory();
    if (source.isEmpty) {
      setState(() {
        _feedback = 'NO HAY OBJETOS DISPONIBLES EN ESTA CATEGORÍA';
      });
      return;
    }

    final vowel = _mode == _RouletteMode.vocal
        ? (_randomVowel
              ? _vowels[_random.nextInt(_vowels.length)]
              : _selectedVowel)
        : _pickVowelForLevel(source);

    final eligible = _eligibleItemsFor(vowel);
    if (eligible.isEmpty) {
      setState(() {
        _feedback =
            'NO ENCONTRÉ OBJETOS CON LA VOCAL $vowel EN ESTA CONFIGURACIÓN';
        _activeVowel = vowel;
      });
      return;
    }

    final wheelItems = _pickWheelItems(eligible, randomize: true);
    if (wheelItems.isEmpty) {
      setState(() {
        _feedback = 'NO HAY SUFICIENTES OBJETOS PARA GIRAR LA RULETA';
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
      _feedback = 'OBJETO SELECCIONADO CON VOCAL $_activeVowel.';
    });
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final isTablet = width >= 720;

    final source = _baseByCategory();
    final previewVowel = _mode == _RouletteMode.vocal
        ? (_randomVowel ? _selectedVowel : _selectedVowel)
        : _pickVowelForLevel(source.isEmpty ? _pool : source);
    final previewEligible = _eligibleItemsFor(previewVowel);
    final wheelItems = _wheelItems.isNotEmpty
        ? _wheelItems
        : _pickWheelItems(previewEligible, randomize: false);

    return Scaffold(
      appBar: AppBar(title: const UpperText('RULETA DE OBJETOS Y VOCALES')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1080),
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
                            _selectedItem = null;
                            _wheelItems = [];
                          });
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
                                    _selectedItem = null;
                                    _wheelItems = [];
                                  });
                                },
                              );
                            }),
                            ChoiceChip(
                              selected: _randomVowel,
                              label: const UpperText('ALEATORIA'),
                              onSelected: (_) {
                                setState(() {
                                  _randomVowel = true;
                                  _selectedItem = null;
                                  _wheelItems = [];
                                });
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
                                      _selectedItem = null;
                                      _wheelItems = [];
                                    });
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
              ),
              const SizedBox(height: 10),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: UpperText(_feedback),
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
                onPressed: _isSpinning ? null : _spin,
                icon: const Icon(Icons.casino_rounded),
                label: UpperText(_isSpinning ? 'GIRANDO...' : 'GIRAR RULETA'),
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
