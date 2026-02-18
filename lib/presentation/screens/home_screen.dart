import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/providers/app_providers.dart';
import '../../domain/models/activity_type.dart';
import '../../domain/models/category.dart';
import '../../domain/models/difficulty.dart';
import '../viewmodels/home_selection_view_model.dart';
import '../viewmodels/settings_view_model.dart';
import '../widgets/upper_text.dart';
import 'activity_selection_screen.dart';
import 'progress_dashboard_screen.dart';
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
    final games = <_GameOption>[
      _GameOption(
        type: ActivityType.imagenPalabra,
        title: 'IMAGEN Y PALABRA',
        subtitle: 'UNE PALABRA CON SU IMAGEN',
        icon: Icons.link_rounded,
        color: const Color(0xFF2F9E8A),
        levelHint: 'NIVEL 1',
      ),
      _GameOption(
        type: ActivityType.escribirPalabra,
        title: 'ESCRIBIR PALABRA',
        subtitle: 'COPIA, SEMICOPIA O DICTADO',
        icon: Icons.keyboard_alt_rounded,
        color: const Color(0xFFF29F05),
        levelHint: 'NIVEL 1',
      ),
      _GameOption(
        type: ActivityType.palabraPalabra,
        title: 'PALABRA CON PALABRA',
        subtitle: 'UNE PALABRAS IGUALES O RELACIONADAS',
        icon: Icons.compare_arrows_rounded,
        color: const Color(0xFF6E77E5),
        levelHint: 'NIVEL 1',
      ),
      _GameOption(
        type: ActivityType.imagenFrase,
        title: 'IMAGEN Y FRASE',
        subtitle: 'UNE CADA FRASE CON SU IMAGEN',
        icon: Icons.text_snippet_rounded,
        color: const Color(0xFF00A5B5),
        levelHint: 'NIVEL 1',
      ),
      _GameOption(
        type: ActivityType.letraObjetivo,
        title: 'LETRAS Y VOCALES',
        subtitle: 'BUSCA LA LETRA DENTRO DE PALABRAS',
        icon: Icons.spellcheck_rounded,
        color: const Color(0xFFDA5E2A),
        levelHint: 'NIVELES 1, 2 Y 3',
      ),
      _GameOption(
        type: ActivityType.discriminacion,
        title: 'DISCRIMINACIÓN',
        subtitle: 'ELIGE LA OPCIÓN CORRECTA',
        icon: Icons.filter_center_focus_rounded,
        color: const Color(0xFF00996B),
        levelHint: 'NIVELES 1, 2 Y 3',
      ),
      _GameOption(
        type: ActivityType.discriminacionInversa,
        title: 'DISCRIMINACIÓN INVERSA',
        subtitle: 'ENCUENTRA LA OPCIÓN INTRUSA',
        icon: Icons.find_replace_rounded,
        color: const Color(0xFFB66A15),
        levelHint: 'NIVELES 1, 2 Y 3',
      ),
    ];

    if (!_didSyncSettings) {
      _didSyncSettings = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        selectionVm.setDifficulty(settings.defaultDifficulty);
      });
    }

    return Scaffold(
      appBar: AppBar(
        title: const UpperText('LECTOESCRITURA'),
        actions: [
          IconButton(
            tooltip: 'PROGRESO',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => ProgressDashboardScreen(
                    category: selection.category,
                  ),
                ),
              );
            },
            icon: const Icon(Icons.insights_rounded),
          ),
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
                      'ELIGE CATEGORÍA Y JUEGO',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 15,
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
                        'JUEGO',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 10),
                      LayoutBuilder(
                        builder: (context, constraints) {
                          final maxWidth = constraints.maxWidth;
                          final compact = maxWidth < 620;
                          final crossAxisCount = compact
                              ? 1
                              : maxWidth >= 1120
                              ? 4
                              : maxWidth >= 760
                              ? 3
                              : 2;

                          return GridView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: games.length,
                            gridDelegate:
                                SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: crossAxisCount,
                              crossAxisSpacing: 10,
                              mainAxisSpacing: 10,
                              childAspectRatio: compact ? 2.8 : 1,
                            ),
                            itemBuilder: (context, index) {
                              final game = games[index];
                              return _GameCard(
                                title: game.title,
                                subtitle: game.subtitle,
                                levelHint: game.levelHint,
                                icon: game.icon,
                                selected: selection.game == game.type,
                                color: game.color,
                                compact: compact,
                                onTap: () => selectionVm.setGame(game.type),
                              );
                            },
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => ActivitySelectionScreen(
                        category: selection.category,
                        activityType: selection.game,
                        difficulty: selection.difficulty,
                      ),
                    ),
                  );
                },
                icon: const Icon(Icons.play_arrow_rounded, size: 30),
                label: const UpperText('EMPEZAR ACTIVIDAD'),
              ),
              const SizedBox(height: 10),
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
    AppCategory.mixta: Icons.shuffle_rounded,
    AppCategory.cosasDeCasa: Icons.chair_alt_rounded,
    AppCategory.comida: Icons.restaurant_rounded,
    AppCategory.dinero: Icons.paid_rounded,
    AppCategory.bano: Icons.shower_rounded,
    AppCategory.profesiones: Icons.work_rounded,
    AppCategory.salud: Icons.favorite_rounded,
    AppCategory.emociones: Icons.mood_rounded,
  };

  static const _colors = <AppCategory, Color>{
    AppCategory.mixta: Color(0xFF1A7D95),
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

class _GameCard extends StatelessWidget {
  const _GameCard({
    required this.title,
    required this.subtitle,
    required this.levelHint,
    required this.icon,
    required this.selected,
    required this.color,
    required this.compact,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final String levelHint;
  final IconData icon;
  final bool selected;
  final Color color;
  final bool compact;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Ink(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected ? color : color.withValues(alpha: 0.30),
            width: selected ? 3 : 1.3,
          ),
          color: selected ? color.withValues(alpha: 0.16) : Colors.white,
        ),
        child: compact
            ? Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(icon, color: color, size: 24),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        UpperText(
                          title,
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 3),
                        UpperText(
                          levelHint,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w900,
                            color: color,
                          ),
                          maxLines: 1,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Icon(
                    selected
                        ? Icons.check_circle_rounded
                        : Icons.radio_button_unchecked_rounded,
                    color: color,
                    size: selected ? 24 : 20,
                  ),
                ],
              )
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: UpperText(
                          title,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w900,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Icon(
                        selected
                            ? Icons.check_circle_rounded
                            : Icons.radio_button_unchecked_rounded,
                        color: color,
                        size: selected ? 24 : 20,
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  UpperText(
                    subtitle,
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const Spacer(),
                  Center(
                    child: Icon(
                      icon,
                      size: 84,
                      color: color.withValues(alpha: 0.82),
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: UpperText(
                      levelHint,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w900,
                        color: color,
                      ),
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

class _GameOption {
  const _GameOption({
    required this.type,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.levelHint,
  });

  final ActivityType type;
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final String levelHint;
}
