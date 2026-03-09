import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/providers/app_providers.dart';
import '../../core/utils/text_utils.dart';
import '../../domain/models/activity_result.dart';
import '../../domain/models/activity_type.dart';
import '../../domain/models/category.dart';
import '../../domain/models/item.dart';
import '../../domain/models/item_progress.dart';
import '../viewmodels/progress_view_model.dart';
import '../widgets/upper_text.dart';

class ProgressDashboardScreen extends ConsumerWidget {
  const ProgressDashboardScreen({super.key, required this.category});

  final AppCategory category;

  static const _trackedGames = [
    ActivityType.imagenPalabra,
    ActivityType.escribirPalabra,
    ActivityType.palabraPalabra,
    ActivityType.imagenFrase,
    ActivityType.letraObjetivo,
    ActivityType.cambioExacto,
    ActivityType.ruletaLetras,
    ActivityType.discriminacion,
    ActivityType.discriminacionInversa,
  ];

  static const _bg = Color(0xFFF1F3F8);
  static const _border = Color(0xFFD6DEEC);

  static const _accents = [
    Color(0xFF2B8CEE),
    Color(0xFFE852A0),
    Color(0xFFFF8C2B),
    Color(0xFF26B670),
    Color(0xFF7A6BFF),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(progressViewModelProvider);

    final results = ref
        .read(progressViewModelProvider.notifier)
        .getAllResults();
    final gameItemProgress = ref.watch(gameItemProgressMapProvider);
    final dataset = ref.read(datasetRepositoryProvider);
    final allItems = dataset.getAllItems();

    final filteredResults = category == AppCategory.mixta
        ? results
        : results.where((result) => result.category == category).toList();

    final gameStats = _trackedGames.map((game) {
      final gameResults =
          filteredResults
              .where((result) => result.activityType == game)
              .toList()
            ..sort((a, b) => a.createdAt.compareTo(b.createdAt));

      final letters = _computeProblemLetters(
        game: game,
        allItems: allItems,
        gameItemProgressMap: gameItemProgress,
        category: category,
      );

      final totalCorrect = gameResults.fold<int>(
        0,
        (sum, result) => sum + result.correct,
      );
      final totalIncorrect = gameResults.fold<int>(
        0,
        (sum, result) => sum + result.incorrect,
      );
      final totalTime = gameResults.fold<int>(
        0,
        (sum, result) => sum + result.durationInSeconds,
      );
      final attempts = totalCorrect + totalIncorrect;
      final accuracy = attempts == 0 ? 0.0 : totalCorrect / attempts;

      final evolution = gameResults
          .map((result) => result.accuracy.clamp(0.0, 1.0))
          .toList();

      return _GameStats(
        game: game,
        totalCorrect: totalCorrect,
        totalIncorrect: totalIncorrect,
        totalTime: totalTime,
        accuracy: accuracy,
        sessionsWithData: gameResults.length,
        problemLetters: letters,
        evolution: evolution,
        recentResults: gameResults.reversed.take(12).toList(),
      );
    }).toList();

    final totalCorrectGlobal = gameStats.fold<int>(
      0,
      (sum, stat) => sum + stat.totalCorrect,
    );
    final daysActive = filteredResults
        .map(
          (r) => DateTime(r.createdAt.year, r.createdAt.month, r.createdAt.day),
        )
        .toSet()
        .length;

    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: _bg,
        surfaceTintColor: Colors.transparent,
        title: const UpperText('PANEL DE PROGRESO'),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1280),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
            children: [
              const UpperText(
                '¡TU GRAN PROGRESO!',
                style: TextStyle(
                  fontSize: 50,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF111A39),
                ),
              ),
              const SizedBox(height: 4),
              const UpperText(
                'MIRA TODO LO QUE HAS APRENDIDO Y LOGRADO HOY',
                style: TextStyle(
                  fontSize: 18,
                  color: Color(0xFF6A7894),
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 18),
              LayoutBuilder(
                builder: (context, constraints) {
                  final compact = constraints.maxWidth < 640;
                  final cards = [
                    _SummaryCard(
                      icon: Icons.school_rounded,
                      title: 'SESIONES TOTALES',
                      value: '${filteredResults.length}',
                      bubbleColor: const Color(0xFFDCEBFF),
                      iconColor: const Color(0xFF2B8CEE),
                    ),
                    _SummaryCard(
                      icon: Icons.star_rounded,
                      title: 'ACIERTOS TOTALES',
                      value: '$totalCorrectGlobal',
                      bubbleColor: const Color(0xFFFFF2C9),
                      iconColor: const Color(0xFFE3A904),
                    ),
                    _SummaryCard(
                      icon: Icons.calendar_month_rounded,
                      title: 'DÍAS ACTIVO',
                      value: '$daysActive',
                      bubbleColor: const Color(0xFFDDF7E8),
                      iconColor: const Color(0xFF1CAA64),
                    ),
                  ];

                  if (compact) {
                    return Column(
                      children: [
                        for (final card in cards) ...[
                          card,
                          const SizedBox(height: 10),
                        ],
                      ],
                    );
                  }

                  return Row(
                    children: [
                      for (var i = 0; i < cards.length; i++) ...[
                        Expanded(child: cards[i]),
                        if (i != cards.length - 1) const SizedBox(width: 12),
                      ],
                    ],
                  );
                },
              ),
              const SizedBox(height: 24),
              const UpperText(
                'DETALLE DE ACTIVIDADES',
                style: TextStyle(
                  fontSize: 30,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF1A2340),
                ),
              ),
              const SizedBox(height: 12),
              for (var i = 0; i < gameStats.length; i++) ...[
                _ActivityProgressCard(
                  stats: gameStats[i],
                  accent: _accents[i % _accents.length],
                  onDetails: () =>
                      _showGameDetails(context: context, stats: gameStats[i]),
                ),
                const SizedBox(height: 12),
              ],
            ],
          ),
        ),
      ),
    );
  }

  List<String> _computeProblemLetters({
    required ActivityType game,
    required List<Item> allItems,
    required Map<String, ItemProgress> gameItemProgressMap,
    required AppCategory category,
  }) {
    final byId = <String, Item>{for (final item in allItems) item.id: item};
    final scoreByLetter = <String, int>{};

    for (final entry in gameItemProgressMap.entries) {
      final key = entry.key;
      final separatorIndex = key.indexOf('|');
      if (separatorIndex <= 0) {
        continue;
      }

      final gameKey = key.substring(0, separatorIndex);
      if (gameKey != game.key) {
        continue;
      }

      final itemId = key.substring(separatorIndex + 1);
      final item = byId[itemId];
      if (item == null) {
        continue;
      }

      if (category != AppCategory.mixta && item.category != category) {
        continue;
      }

      final diff = entry.value.incorrectAttempts - entry.value.correctAttempts;
      if (diff <= 0) {
        continue;
      }

      final word = item.word ?? (item.words.isNotEmpty ? item.words.first : '');
      if (word.isEmpty) {
        continue;
      }

      final letters = normalizeWordForLetters(
        word,
      ).split('').where((char) => RegExp(r'[A-ZÑ]').hasMatch(char)).toSet();

      for (final letter in letters) {
        scoreByLetter[letter] = (scoreByLetter[letter] ?? 0) + diff;
      }
    }

    final sorted = scoreByLetter.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return sorted.take(5).map((entry) => entry.key).toList();
  }
}

void _showGameDetails({
  required BuildContext context,
  required _GameStats stats,
}) {
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (context) {
      final media = MediaQuery.sizeOf(context);
      return SafeArea(
        child: SizedBox(
          height: media.height * 0.72,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(18, 6, 18, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                UpperText(
                  'DETALLES: ${stats.game.label}',
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF1A2340),
                  ),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 10,
                  runSpacing: 8,
                  children: [
                    _detailBadge(
                      'PRECISIÓN ${((stats.accuracy) * 100).round()}%',
                      const Color(0xFF2B8CEE),
                    ),
                    _detailBadge(
                      'ACIERTOS ${stats.totalCorrect}',
                      const Color(0xFF5F6D89),
                    ),
                    _detailBadge(
                      'FALLOS ${stats.totalIncorrect}',
                      const Color(0xFF5F6D89),
                    ),
                    _detailBadge(
                      'TIEMPO ${stats.totalTime} S',
                      const Color(0xFF5F6D89),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                UpperText(
                  stats.problemLetters.isEmpty
                      ? 'LETRAS A REFORZAR: SIN DATOS'
                      : 'LETRAS A REFORZAR: ${stats.problemLetters.join(', ')}',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF5F6D89),
                  ),
                ),
                const SizedBox(height: 14),
                const UpperText(
                  'ÚLTIMAS SESIONES',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: stats.recentResults.isEmpty
                      ? const Center(
                          child: UpperText(
                            'TODAVÍA NO HAY SESIONES EN ESTE JUEGO',
                            style: TextStyle(
                              color: Color(0xFF7A869E),
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        )
                      : ListView.separated(
                          itemCount: stats.recentResults.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 8),
                          itemBuilder: (context, index) {
                            final result = stats.recentResults[index];
                            final date = result.createdAt;
                            final dateLabel =
                                '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year} '
                                '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
                            final attempts = result.correct + result.incorrect;
                            final acc = attempts == 0
                                ? 0
                                : ((result.correct / attempts) * 100).round();

                            return Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 10,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF6F8FD),
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                  color: const Color(0xFFDCE4F2),
                                ),
                              ),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: UpperText(
                                      dateLabel,
                                      style: const TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w700,
                                        color: Color(0xFF5E6C87),
                                      ),
                                    ),
                                  ),
                                  UpperText(
                                    'A:${result.correct} F:${result.incorrect} $acc%',
                                    style: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w900,
                                      color: Color(0xFF1A2340),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
          ),
        ),
      );
    },
  );
}

Widget _detailBadge(String text, Color color) {
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(999),
      color: color.withValues(alpha: 0.12),
    ),
    child: UpperText(
      text,
      style: TextStyle(color: color, fontSize: 13, fontWeight: FontWeight.w800),
    ),
  );
}

class _GameStats {
  const _GameStats({
    required this.game,
    required this.totalCorrect,
    required this.totalIncorrect,
    required this.totalTime,
    required this.accuracy,
    required this.sessionsWithData,
    required this.problemLetters,
    required this.evolution,
    required this.recentResults,
  });

  final ActivityType game;
  final int totalCorrect;
  final int totalIncorrect;
  final int totalTime;
  final double accuracy;
  final int sessionsWithData;
  final List<String> problemLetters;
  final List<double> evolution;
  final List<ActivityResult> recentResults;
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.icon,
    required this.title,
    required this.value,
    required this.bubbleColor,
    required this.iconColor,
  });

  final IconData icon;
  final String title;
  final String value;
  final Color bubbleColor;
  final Color iconColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: ProgressDashboardScreen._border),
      ),
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 14),
      child: Column(
        children: [
          CircleAvatar(
            radius: 25,
            backgroundColor: bubbleColor,
            child: Icon(icon, color: iconColor, size: 28),
          ),
          const SizedBox(height: 10),
          UpperText(
            title,
            style: const TextStyle(
              fontSize: 16,
              color: Color(0xFF6B7892),
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          UpperText(
            value,
            style: const TextStyle(
              fontSize: 46,
              color: Color(0xFF111A39),
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _ActivityProgressCard extends StatelessWidget {
  const _ActivityProgressCard({
    required this.stats,
    required this.accent,
    required this.onDetails,
  });

  final _GameStats stats;
  final Color accent;
  final VoidCallback onDetails;

  @override
  Widget build(BuildContext context) {
    final letters = stats.problemLetters.isEmpty
        ? 'SIN DATOS'
        : stats.problemLetters.join(', ');

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: ProgressDashboardScreen._border),
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(30),
          border: Border(left: BorderSide(color: accent, width: 6)),
        ),
        padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final compact = constraints.maxWidth < 940;
            final info = _ActivityInfo(
              stats: stats,
              accent: accent,
              letters: letters,
            );
            final trend = _ActivityTrend(stats: stats, accent: accent);
            final action = Align(
              alignment: Alignment.centerRight,
              child: FilledButton(
                onPressed: onDetails,
                style: FilledButton.styleFrom(
                  backgroundColor: accent,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(999),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 14,
                  ),
                ),
                child: const UpperText('VER DETALLES'),
              ),
            );

            if (compact) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  info,
                  const SizedBox(height: 12),
                  trend,
                  const SizedBox(height: 10),
                  action,
                ],
              );
            }

            return Row(
              children: [
                Expanded(flex: 6, child: info),
                const SizedBox(width: 12),
                Expanded(flex: 3, child: trend),
                const SizedBox(width: 12),
                Expanded(flex: 2, child: action),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _ActivityInfo extends StatelessWidget {
  const _ActivityInfo({
    required this.stats,
    required this.accent,
    required this.letters,
  });

  final _GameStats stats;
  final Color accent;
  final String letters;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CircleAvatar(
          radius: 30,
          backgroundColor: accent.withValues(alpha: 0.15),
          child: Icon(_iconForGame(stats.game), color: accent, size: 32),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              UpperText(
                stats.game.label,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF1A2340),
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 10,
                runSpacing: 6,
                children: [
                  _badge(
                    'PRECISIÓN ${((stats.accuracy) * 100).round()}%',
                    accent,
                  ),
                  _badge(
                    'ACIERTOS ${stats.totalCorrect}',
                    const Color(0xFF6C7A95),
                  ),
                  _badge(
                    'FALLOS ${stats.totalIncorrect}',
                    const Color(0xFF6C7A95),
                  ),
                  _badge(
                    'TIEMPO ${stats.totalTime} S',
                    const Color(0xFF6C7A95),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              UpperText(
                stats.sessionsWithData == 0
                    ? 'AÚN NO HAY SESIONES PARA MOSTRAR EVOLUCIÓN'
                    : 'SESIONES CON DATOS: ${stats.sessionsWithData}',
                style: const TextStyle(
                  fontSize: 14,
                  color: Color(0xFF5F6D89),
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              UpperText(
                'LETRAS A REFORZAR: $letters',
                style: const TextStyle(
                  fontSize: 14,
                  color: Color(0xFF5F6D89),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _badge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        color: color.withValues(alpha: 0.12),
      ),
      child: UpperText(
        text,
        style: TextStyle(
          color: color,
          fontSize: 13,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _ActivityTrend extends StatelessWidget {
  const _ActivityTrend({required this.stats, required this.accent});

  final _GameStats stats;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final values = stats.evolution.length > 8
        ? stats.evolution.sublist(stats.evolution.length - 8)
        : stats.evolution;

    if (values.isEmpty) {
      return const SizedBox(
        height: 72,
        child: Center(
          child: UpperText(
            'SIN EVOLUCIÓN',
            style: TextStyle(
              fontSize: 12,
              color: Color(0xFF8A96AE),
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      );
    }

    return SizedBox(
      height: 72,
      child: CustomPaint(
        painter: _LinePainter(values: values, color: accent),
      ),
    );
  }
}

class _LinePainter extends CustomPainter {
  _LinePainter({required this.values, required this.color});

  final List<double> values;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    if (values.length < 2) {
      return;
    }

    final path = Path();
    final dxStep = size.width / (values.length - 1);
    for (var i = 0; i < values.length; i++) {
      final x = i * dxStep;
      final y = size.height - (values[i].clamp(0.0, 1.0) * size.height);
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }

    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _LinePainter oldDelegate) {
    return oldDelegate.values != values || oldDelegate.color != color;
  }
}

IconData _iconForGame(ActivityType game) {
  return switch (game) {
    ActivityType.imagenPalabra => Icons.image_outlined,
    ActivityType.escribirPalabra => Icons.edit_note_rounded,
    ActivityType.palabraPalabra => Icons.compare_arrows_rounded,
    ActivityType.imagenFrase => Icons.article_outlined,
    ActivityType.letraObjetivo => Icons.abc_rounded,
    ActivityType.cambioExacto => Icons.shopping_basket_rounded,
    ActivityType.ruletaLetras => Icons.casino_outlined,
    ActivityType.discriminacion => Icons.filter_alt_outlined,
    ActivityType.discriminacionInversa => Icons.swap_horiz_rounded,
  };
}
