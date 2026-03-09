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
  const ProgressDashboardScreen({
    super.key,
    required this.category,
    this.embedded = false,
  });

  final AppCategory category;
  final bool embedded;

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
    final rewards = ref
        .read(progressViewModelProvider.notifier)
        .rewardsSummary();
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
    final totalIncorrectGlobal = gameStats.fold<int>(
      0,
      (sum, stat) => sum + stat.totalIncorrect,
    );
    final daysActive = filteredResults
        .map(
          (r) => DateTime(r.createdAt.year, r.createdAt.month, r.createdAt.day),
        )
        .toSet()
        .length;
    final totalAttemptsGlobal = totalCorrectGlobal + totalIncorrectGlobal;
    final progressRatio = totalAttemptsGlobal == 0
        ? 0.0
        : (totalCorrectGlobal / totalAttemptsGlobal).clamp(0.0, 1.0);
    final progressPercent = (progressRatio * 100).round();
    final sessionCount = filteredResults.length;
    final xpGoal = (sessionCount + 1) * 100;
    final currentXp = (progressRatio * xpGoal).round();
    final badgeGoal = 20;
    final levelLabel = rewards.currentStreak >= 7
        ? 'Explorador Pro'
        : rewards.currentStreak >= 3
        ? 'Explorador Activo'
        : 'Explorador';

    int sessionsFor(List<ActivityType> types) {
      return gameStats
          .where((stat) => types.contains(stat.game))
          .fold<int>(0, (sum, stat) => sum + stat.sessionsWithData);
    }

    double accuracyFor(List<ActivityType> types) {
      final selected = gameStats.where((stat) => types.contains(stat.game));
      var attempts = 0;
      var correct = 0;
      for (final stat in selected) {
        attempts += stat.totalCorrect + stat.totalIncorrect;
        correct += stat.totalCorrect;
      }
      return attempts == 0 ? 0.0 : correct / attempts;
    }

    final adventureNodes = [
      _AdventureNode(
        title: 'Isla Numérica',
        subtitle: 'Completado',
        icon: Icons.tag_rounded,
        color: const Color(0xFF26B670),
        state: sessionsFor([ActivityType.cambioExacto]) > 0
            ? _NodeState.completed
            : _NodeState.locked,
      ),
      _AdventureNode(
        title: 'Río de Letras',
        subtitle: 'En progreso',
        icon: Icons.menu_book_rounded,
        color: const Color(0xFFEF5B10),
        badge: '$progressPercent%',
        state:
            sessionsFor([
                  ActivityType.letraObjetivo,
                  ActivityType.palabraPalabra,
                ]) >
                0
            ? _NodeState.inProgress
            : _NodeState.locked,
      ),
      _AdventureNode(
        title: 'Valle Artístico',
        subtitle: 'Bloqueado',
        icon: Icons.palette_rounded,
        color: const Color(0xFF5A6C8F),
        state:
            sessionsFor([
                  ActivityType.imagenPalabra,
                  ActivityType.imagenFrase,
                  ActivityType.escribirPalabra,
                ]) >
                0
            ? (accuracyFor([
                        ActivityType.imagenPalabra,
                        ActivityType.imagenFrase,
                        ActivityType.escribirPalabra,
                      ]) >
                      0.85
                  ? _NodeState.completed
                  : _NodeState.inProgress)
            : _NodeState.locked,
      ),
      _AdventureNode(
        title: 'Bosque Científico',
        subtitle: 'Bloqueado',
        icon: Icons.science_rounded,
        color: const Color(0xFF5A6C8F),
        state:
            sessionsFor([
                  ActivityType.discriminacion,
                  ActivityType.discriminacionInversa,
                  ActivityType.ruletaLetras,
                ]) >
                0
            ? _NodeState.inProgress
            : _NodeState.locked,
      ),
    ];

    final trophies = [
      _TrophyData(
        title: 'ESTRELLA FUGAZ',
        icon: Icons.star_rounded,
        color: const Color(0xFFF0C400),
        unlocked: progressRatio >= 0.75,
      ),
      _TrophyData(
        title: 'LECTOR VELOZ',
        icon: Icons.speed_rounded,
        color: const Color(0xFF59A0FF),
        unlocked: sessionCount >= 4,
      ),
      _TrophyData(
        title: 'BÚHO SABIO',
        icon: Icons.psychology_rounded,
        color: const Color(0xFFB077FF),
        unlocked: rewards.unlockedBadges >= 1,
      ),
      _TrophyData(
        title: '7 DÍAS ON FIRE',
        icon: Icons.local_fire_department_rounded,
        color: const Color(0xFFEF5B10),
        unlocked: rewards.currentStreak >= 7,
      ),
      const _TrophyData(
        title: '???',
        icon: Icons.help_rounded,
        color: Color(0xFFB4BECE),
        unlocked: false,
      ),
      const _TrophyData(
        title: '???',
        icon: Icons.help_rounded,
        color: Color(0xFFB4BECE),
        unlocked: false,
      ),
    ];

    final bodyContent = Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1280),
        child: ListView(
          padding: EdgeInsets.fromLTRB(24, embedded ? 20 : 12, 24, 24),
          children: [
            LayoutBuilder(
              builder: (context, constraints) {
                final compact = constraints.maxWidth < 980;

                final missionCard = Container(
                  padding: const EdgeInsets.fromLTRB(24, 20, 24, 20),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(26),
                    gradient: const LinearGradient(
                      colors: [Color(0xFFEF5B10), Color(0xFFF26A1B)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFEF5B10).withValues(alpha: 0.22),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.20),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: const UpperText(
                          'MISIÓN ACTUAL',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w900,
                            fontSize: 14,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      const UpperText(
                        '¡CASI LLEGAS AL TESORO!',
                        style: TextStyle(
                          fontSize: 46,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 6),
                      UpperText(
                        sessionCount == 0
                            ? 'Completa tu primera lección para empezar tu aventura.'
                            : 'Estás a ${((100 - progressPercent) / 10).clamp(1, 10).round()} lecciones de completar tu misión diaria. Días activos: $daysActive.',
                        style: const TextStyle(
                          fontSize: 16,
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 16),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(999),
                        child: LinearProgressIndicator(
                          value: progressRatio,
                          minHeight: 14,
                          backgroundColor: Colors.black.withValues(alpha: 0.14),
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          UpperText(
                            '$progressPercent% COMPLETADO',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          const Spacer(),
                          UpperText(
                            '$currentXp / $xpGoal XP',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                );

                final sideCards = Column(
                  children: [
                    _ProgressSideInfoCard(
                      icon: Icons.emoji_events_rounded,
                      title: 'Insignias',
                      value: '${rewards.unlockedBadges} / $badgeGoal',
                      bubbleColor: const Color(0xFFFFF1E2),
                      iconColor: const Color(0xFFEF5B10),
                    ),
                    const SizedBox(height: 12),
                    _ProgressSideInfoCard(
                      icon: Icons.school_rounded,
                      title: 'Nivel',
                      value: levelLabel,
                      bubbleColor: const Color(0xFFE2ECFF),
                      iconColor: const Color(0xFF2F7DED),
                    ),
                  ],
                );

                if (compact) {
                  return Column(
                    children: [
                      missionCard,
                      const SizedBox(height: 12),
                      sideCards,
                    ],
                  );
                }

                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(flex: 5, child: missionCard),
                    const SizedBox(width: 14),
                    Expanded(flex: 2, child: sideCards),
                  ],
                );
              },
            ),
            const SizedBox(height: 24),
            const Row(
              children: [
                Icon(Icons.map_rounded, color: Color(0xFFEF5B10), size: 24),
                SizedBox(width: 8),
                UpperText(
                  'TU MAPA DE AVENTURAS',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF131C37),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 18),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(28),
                border: Border.all(color: const Color(0xFFE1E8F3)),
              ),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    for (var i = 0; i < adventureNodes.length; i++) ...[
                      _AdventureNodeTile(node: adventureNodes[i]),
                      if (i != adventureNodes.length - 1)
                        Container(
                          width: 44,
                          height: 6,
                          margin: const EdgeInsets.only(bottom: 38),
                          decoration: BoxDecoration(
                            color:
                                adventureNodes[i].state == _NodeState.completed
                                ? const Color(0xFF28B36D)
                                : const Color(0xFFE0E6F0),
                            borderRadius: BorderRadius.circular(999),
                          ),
                        ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                const Icon(
                  Icons.military_tech_rounded,
                  color: Color(0xFFEF5B10),
                  size: 24,
                ),
                const SizedBox(width: 8),
                const UpperText(
                  'TUS TROFEOS DE COLECCIÓN',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF131C37),
                  ),
                ),
                const Spacer(),
                TextButton(
                  onPressed: () {},
                  child: const UpperText(
                    'VER TODOS',
                    style: TextStyle(
                      color: Color(0xFFEF5B10),
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            SizedBox(
              height: 164,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemBuilder: (context, index) {
                  final trophy = trophies[index];
                  return _TrophyCard(data: trophy);
                },
                separatorBuilder: (_, __) => const SizedBox(width: 10),
                itemCount: trophies.length,
              ),
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
    );

    if (embedded) {
      return ColoredBox(color: _bg, child: bodyContent);
    }

    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: _bg,
        surfaceTintColor: Colors.transparent,
        title: const UpperText('PANEL DE PROGRESO'),
      ),
      body: bodyContent,
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

class _ProgressSideInfoCard extends StatelessWidget {
  const _ProgressSideInfoCard({
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
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: ProgressDashboardScreen._border),
      ),
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      child: Row(
        children: [
          CircleAvatar(
            radius: 24,
            backgroundColor: bubbleColor,
            child: Icon(icon, color: iconColor, size: 26),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                UpperText(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    color: Color(0xFF6B7892),
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                UpperText(
                  value,
                  style: const TextStyle(
                    fontSize: 22,
                    color: Color(0xFF111A39),
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

enum _NodeState { completed, inProgress, locked }

class _AdventureNode {
  const _AdventureNode({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.state,
    this.badge,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final _NodeState state;
  final String? badge;
}

class _AdventureNodeTile extends StatelessWidget {
  const _AdventureNodeTile({required this.node});

  final _AdventureNode node;

  @override
  Widget build(BuildContext context) {
    final locked = node.state == _NodeState.locked;
    final accent = locked ? const Color(0xFFBCC6D7) : node.color;
    final fill = locked
        ? const Color(0xFFF1F4F8)
        : node.state == _NodeState.completed
        ? const Color(0xFFDDF5E8)
        : const Color(0xFFFFEEE4);

    return SizedBox(
      width: 180,
      child: Column(
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                width: 110,
                height: 110,
                decoration: BoxDecoration(
                  color: fill,
                  shape: BoxShape.circle,
                  border: Border.all(color: accent, width: 4),
                ),
                child: Icon(node.icon, color: accent, size: 48),
              ),
              if (node.state == _NodeState.completed)
                const Positioned(
                  right: -2,
                  top: -2,
                  child: CircleAvatar(
                    radius: 12,
                    backgroundColor: Color(0xFF28B36D),
                    child: Icon(Icons.check, color: Colors.white, size: 16),
                  ),
                ),
              if (node.badge != null)
                Positioned(
                  top: -8,
                  right: -10,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 9,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEF5B10),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: UpperText(
                      node.badge!,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),
          UpperText(
            node.title,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w900,
              color: locked ? const Color(0xFFB4BECE) : const Color(0xFF16203C),
            ),
          ),
          const SizedBox(height: 2),
          UpperText(
            node.subtitle,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              color: locked ? const Color(0xFFB4BECE) : accent,
            ),
          ),
        ],
      ),
    );
  }
}

class _TrophyData {
  const _TrophyData({
    required this.title,
    required this.icon,
    required this.color,
    required this.unlocked,
  });

  final String title;
  final IconData icon;
  final Color color;
  final bool unlocked;
}

class _TrophyCard extends StatelessWidget {
  const _TrophyCard({required this.data});

  final _TrophyData data;

  @override
  Widget build(BuildContext context) {
    final muted = !data.unlocked;
    return Container(
      width: 178,
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: muted
              ? const Color(0xFFE1E8F3)
              : data.color.withValues(alpha: 0.4),
          style: muted ? BorderStyle.solid : BorderStyle.solid,
        ),
      ),
      child: Column(
        children: [
          CircleAvatar(
            radius: 28,
            backgroundColor: muted
                ? const Color(0xFFE8EDF5)
                : data.color.withValues(alpha: 0.18),
            child: Icon(
              data.icon,
              size: 28,
              color: muted ? const Color(0xFF9DA8BC) : data.color,
            ),
          ),
          const Spacer(),
          UpperText(
            data.title,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w900,
              color: muted ? const Color(0xFF9DA8BC) : const Color(0xFF141D38),
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
