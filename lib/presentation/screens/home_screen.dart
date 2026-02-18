import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/providers/app_providers.dart';
import '../../domain/models/category.dart';
import '../../domain/models/difficulty.dart';
import '../../domain/models/level.dart';
import '../viewmodels/home_selection_view_model.dart';
import '../viewmodels/progress_view_model.dart';
import '../viewmodels/settings_view_model.dart';
import '../widgets/upper_text.dart';
import 'activity_selection_screen.dart';
import 'settings_screen.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  bool _didSyncSettings = false;

  @override
  Widget build(BuildContext context) {
    final selection = ref.watch(homeSelectionViewModelProvider);
    final selectionVm = ref.read(homeSelectionViewModelProvider.notifier);
    final settings = ref.watch(settingsViewModelProvider);
    final profile = ref.watch(localProfileProvider);
    final colorScheme = Theme.of(context).colorScheme;
    ref.watch(progressViewModelProvider);

    if (!_didSyncSettings) {
      _didSyncSettings = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        selectionVm.setDifficulty(settings.defaultDifficulty);
      });
    }

    final allResults = ref.read(progressViewModelProvider.notifier).getAllResults();
    final categoryResults = allResults
        .where((result) => result.category == selection.category && result.accuracy >= 0.7)
        .toList();

    int masteredFor(AppLevel level) {
      return categoryResults
          .where((result) => result.level == level)
          .map((result) => result.activityType)
          .toSet()
          .length;
    }

    final canLevel2 = masteredFor(AppLevel.uno) >= 2;
    final canLevel3 = masteredFor(AppLevel.dos) >= 1;
    final canLevel4 = masteredFor(AppLevel.tres) >= 1;
    final canLevel5 = masteredFor(AppLevel.cuatro) >= 1;

    final isCurrentUnlocked = switch (selection.level) {
      AppLevel.uno => true,
      AppLevel.dos => canLevel2,
      AppLevel.tres => canLevel3,
      AppLevel.cuatro => canLevel4,
      AppLevel.cinco => canLevel5,
    };

    return Scaffold(
      appBar: AppBar(
        title: const UpperText('APP DE LECTOESCRITURA'),
        actions: [
          IconButton(
            tooltip: 'AJUSTES',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute<void>(builder: (_) => const SettingsScreen()),
              );
            },
            icon: const Icon(Icons.tune),
          ),
        ],
      ),
      body: Stack(
        children: [
          Positioned(
            top: -60,
            right: -40,
            child: _ColorBubble(
              color: const Color(0xFF9FE6D9).withValues(alpha: 0.45),
              size: 180,
            ),
          ),
          Positioned(
            left: -70,
            top: 150,
            child: _ColorBubble(
              color: const Color(0xFFFFD48D).withValues(alpha: 0.40),
              size: 210,
            ),
          ),
          ListView(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
            children: [
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(24),
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFF1F9D8B), Color(0xFF1A7D95)],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.12),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.auto_stories_rounded, color: Colors.white, size: 34),
                        SizedBox(width: 10),
                        Expanded(
                          child: UpperText(
                            'APRENDE JUGANDO',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w900,
                              fontSize: 26,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    UpperText(
                      'HOLA ${profile.displayName}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 18,
                      ),
                    ),
                    const SizedBox(height: 6),
                    const UpperText(
                      'ELIGE CATEGORÍA, NIVEL Y COMIENZA TU RETO',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
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
                        'DIFICULTAD',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 10),
                      SegmentedButton<Difficulty>(
                        segments: const [
                          ButtonSegment(
                            value: Difficulty.primaria,
                            icon: Icon(Icons.child_care_rounded),
                            label: UpperText('PRIMARIA'),
                          ),
                          ButtonSegment(
                            value: Difficulty.secundaria,
                            icon: Icon(Icons.school_rounded),
                            label: UpperText('SECUNDARIA'),
                          ),
                        ],
                        selected: {selection.difficulty},
                        onSelectionChanged: (value) {
                          selectionVm.setDifficulty(value.first);
                        },
                      ),
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
                        'CATEGORÍA',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 10),
                      LayoutBuilder(
                        builder: (context, constraints) {
                          final cardWidth = (constraints.maxWidth - 10) / 2;
                          return Wrap(
                            spacing: 10,
                            runSpacing: 10,
                            children: AppCategory.values.map((category) {
                              return SizedBox(
                                width: cardWidth,
                                child: _CategoryCard(
                                  category: category,
                                  selected: selection.category == category,
                                  onTap: () => selectionVm.setCategory(category),
                                ),
                              );
                            }).toList(),
                          );
                        },
                      ),
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
                        'NIVEL',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 10),
                      _LevelCard(
                        title: 'NIVEL 1',
                        subtitle: 'IMAGEN Y PALABRA',
                        icon: Icons.looks_one_rounded,
                        selected: selection.level == AppLevel.uno,
                        locked: false,
                        color: const Color(0xFF2F9E8A),
                        onTap: () => selectionVm.setLevel(AppLevel.uno),
                      ),
                      const SizedBox(height: 8),
                      _LevelCard(
                        title: 'NIVEL 2',
                        subtitle: 'PALABRA CON PALABRA',
                        icon: Icons.looks_two_rounded,
                        selected: selection.level == AppLevel.dos,
                        locked: !canLevel2,
                        color: const Color(0xFFF29F05),
                        onTap: canLevel2
                            ? () => selectionVm.setLevel(AppLevel.dos)
                            : null,
                      ),
                      const SizedBox(height: 8),
                      _LevelCard(
                        title: 'NIVEL 3',
                        subtitle: 'IMAGEN CON FRASES',
                        icon: Icons.looks_3_rounded,
                        selected: selection.level == AppLevel.tres,
                        locked: !canLevel3,
                        color: const Color(0xFF6E77E5),
                        onTap: canLevel3
                            ? () => selectionVm.setLevel(AppLevel.tres)
                            : null,
                      ),
                      const SizedBox(height: 8),
                      _LevelCard(
                        title: 'NIVEL 4',
                        subtitle: 'LETRAS Y VOCALES (2 SÍLABAS)',
                        icon: Icons.looks_4_rounded,
                        selected: selection.level == AppLevel.cuatro,
                        locked: !canLevel4,
                        color: const Color(0xFF00A5B5),
                        onTap: canLevel4
                            ? () => selectionVm.setLevel(AppLevel.cuatro)
                            : null,
                      ),
                      const SizedBox(height: 8),
                      _LevelCard(
                        title: 'NIVEL 5',
                        subtitle: 'LETRAS Y VOCALES (3+ SÍLABAS)',
                        icon: Icons.looks_5_rounded,
                        selected: selection.level == AppLevel.cinco,
                        locked: !canLevel5,
                        color: const Color(0xFFDA5E2A),
                        onTap: canLevel5
                            ? () => selectionVm.setLevel(AppLevel.cinco)
                            : null,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: isCurrentUnlocked
                    ? () {
                        Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) => ActivitySelectionScreen(
                              category: selection.category,
                              level: selection.level,
                              difficulty: selection.difficulty,
                            ),
                          ),
                        );
                      }
                    : null,
                icon: const Icon(Icons.play_arrow_rounded, size: 30),
                label: const UpperText('EMPEZAR ACTIVIDAD'),
              ),
              const SizedBox(height: 10),
              if (!isCurrentUnlocked)
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: UpperText(
                    'PARA DESBLOQUEAR, COMPLETA EL NIVEL ANTERIOR CON BUEN RESULTADO',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: colorScheme.primary,
                          fontWeight: FontWeight.w700,
                        ),
                    textAlign: TextAlign.center,
                  ),
                ),
              Center(
                child: UpperText(
                  'TODO EL CONTENIDO FUNCIONA OFFLINE',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurface.withValues(alpha: 0.70),
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ColorBubble extends StatelessWidget {
  const _ColorBubble({required this.color, required this.size});

  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
        ),
      ),
    );
  }
}

class _CategoryCard extends StatelessWidget {
  const _CategoryCard({
    required this.category,
    required this.selected,
    required this.onTap,
  });

  final AppCategory category;
  final bool selected;
  final VoidCallback onTap;

  static const _icons = <AppCategory, IconData>{
    AppCategory.cosasDeCasa: Icons.chair_alt_rounded,
    AppCategory.comida: Icons.restaurant_rounded,
    AppCategory.dinero: Icons.paid_rounded,
    AppCategory.bano: Icons.shower_rounded,
    AppCategory.profesiones: Icons.work_rounded,
    AppCategory.salud: Icons.favorite_rounded,
    AppCategory.emociones: Icons.mood_rounded,
  };

  static const _colors = <AppCategory, Color>{
    AppCategory.cosasDeCasa: Color(0xFF2F9E8A),
    AppCategory.comida: Color(0xFFE8871E),
    AppCategory.dinero: Color(0xFF3AA356),
    AppCategory.bano: Color(0xFF3A8CE0),
    AppCategory.profesiones: Color(0xFF8D62DA),
    AppCategory.salud: Color(0xFFE75B74),
    AppCategory.emociones: Color(0xFFF2B705),
  };

  @override
  Widget build(BuildContext context) {
    final color = _colors[category]!;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Ink(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected ? color : color.withValues(alpha: 0.30),
            width: selected ? 3 : 1.4,
          ),
          color: selected ? color.withValues(alpha: 0.16) : Colors.white,
        ),
        child: Row(
          children: [
            Icon(_icons[category], color: color, size: 28),
            const SizedBox(width: 8),
            Expanded(
              child: UpperText(
                category.label,
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LevelCard extends StatelessWidget {
  const _LevelCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.selected,
    required this.locked,
    required this.color,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final bool selected;
  final bool locked;
  final Color color;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Ink(
        padding: const EdgeInsets.all(13),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected ? color : color.withValues(alpha: 0.30),
            width: selected ? 3 : 1.3,
          ),
          color: locked
              ? Colors.grey.shade100
              : selected
              ? color.withValues(alpha: 0.16)
              : Colors.white,
        ),
        child: Row(
          children: [
            Icon(icon, color: locked ? Colors.grey.shade500 : color, size: 34),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  UpperText(
                    title,
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
                  ),
                  const SizedBox(height: 2),
                  UpperText(
                    subtitle,
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
                  ),
                ],
              ),
            ),
            Icon(
              locked
                  ? Icons.lock_rounded
                  : selected
                  ? Icons.check_circle_rounded
                  : Icons.arrow_forward_ios_rounded,
              color: locked ? Colors.grey.shade600 : color,
              size: selected ? 24 : 18,
            ),
          ],
        ),
      ),
    );
  }
}
