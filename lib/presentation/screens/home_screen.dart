import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/providers/app_providers.dart';
import '../../domain/models/app_settings.dart';
import '../../domain/models/activity_type.dart';
import '../../domain/models/category.dart';
import '../utils/category_visuals.dart';
import '../viewmodels/home_selection_view_model.dart';
import '../viewmodels/progress_view_model.dart';
import '../viewmodels/settings_view_model.dart';
import 'activity_selection_screen.dart';
import 'ai_play_screen.dart';
import 'ai_resource_studio_screen.dart';
import 'progress_dashboard_screen.dart';
import 'settings_screen.dart';
import 'therapist_panel_screen.dart';

String _titleCase(String value) {
  final words = value
      .trim()
      .toLowerCase()
      .split(RegExp(r'\s+'))
      .where((word) => word.isNotEmpty);
  return words
      .map((word) => '${word[0].toUpperCase()}${word.substring(1)}')
      .join(' ');
}

String _categoryPickerLabel(AppCategory category) {
  if (category == AppCategory.mixta) {
    return 'Mix de cosas';
  }
  return _titleCase(category.label);
}

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  bool _didSyncSettings = false;
  int _currentTab = 0;

  static const _quickTracks = <_QuickTrack>[
    _QuickTrack(
      title: 'Letras',
      subtitle: 'Conoce el abecedario',
      icon: Icons.text_fields_rounded,
      iconColor: Color(0xFFFF7A00),
      backgroundColor: Color(0xFFFFF0DC),
      gameType: ActivityType.letraObjetivo,
    ),
    _QuickTrack(
      title: 'Sílabas',
      subtitle: 'Une sonidos mágicos',
      icon: Icons.menu_book_rounded,
      iconColor: Color(0xFF1DBE5B),
      backgroundColor: Color(0xFFDEF8E7),
      gameType: ActivityType.palabraPalabra,
    ),
    _QuickTrack(
      title: 'Palabras',
      subtitle: 'Forma tus propias historias',
      icon: Icons.star_rounded,
      iconColor: Color(0xFFE4AE00),
      backgroundColor: Color(0xFFFFF6C8),
      gameType: ActivityType.imagenPalabra,
    ),
    _QuickTrack(
      title: 'Escritura',
      subtitle: 'Copia, semícopia y dictado',
      icon: Icons.edit_rounded,
      iconColor: Color(0xFFEA8A00),
      backgroundColor: Color(0xFFFFEED9),
      gameType: ActivityType.escribirPalabra,
    ),
    _QuickTrack(
      title: 'Frases',
      subtitle: 'Relaciona imagen y comprensión',
      icon: Icons.text_snippet_rounded,
      iconColor: Color(0xFF0D9BB3),
      backgroundColor: Color(0xFFDDF6FA),
      gameType: ActivityType.imagenFrase,
    ),
    _QuickTrack(
      title: 'Sonidos',
      subtitle: 'Escucha y toca la imagen',
      icon: Icons.volume_up_rounded,
      iconColor: Color(0xFF0E9667),
      backgroundColor: Color(0xFFDDF8EF),
      gameType: ActivityType.sonidos,
    ),
    _QuickTrack(
      title: 'Ruleta',
      subtitle: 'Retos por inicio, medio y final',
      icon: Icons.rotate_right_rounded,
      iconColor: Color(0xFF7F56D9),
      backgroundColor: Color(0xFFECE3FF),
      gameType: ActivityType.ruletaLetras,
    ),
    _QuickTrack(
      title: 'Discriminación',
      subtitle: 'Encuentra la opción correcta',
      icon: Icons.center_focus_strong_rounded,
      iconColor: Color(0xFF0E9667),
      backgroundColor: Color(0xFFDDF8EF),
      gameType: ActivityType.discriminacion,
    ),
    _QuickTrack(
      title: 'Inversa',
      subtitle: 'Detecta la opción intrusa',
      icon: Icons.search_rounded,
      iconColor: Color(0xFFB86115),
      backgroundColor: Color(0xFFFFECDC),
      gameType: ActivityType.discriminacionInversa,
    ),
    _QuickTrack(
      title: 'Tienda',
      subtitle: 'Practica monedas y cambio',
      icon: Icons.shopping_bag_rounded,
      iconColor: Color(0xFFC33D8A),
      backgroundColor: Color(0xFFFFE2F1),
      gameType: ActivityType.cambioExacto,
    ),
  ];

  static const _allGameShortcuts = <_GameShortcut>[
    _GameShortcut(
      title: 'Imagen y Palabra',
      type: ActivityType.imagenPalabra,
      icon: Icons.link_rounded,
    ),
    _GameShortcut(
      title: 'Escribir Palabra',
      type: ActivityType.escribirPalabra,
      icon: Icons.keyboard_alt_rounded,
    ),
    _GameShortcut(
      title: 'Palabra con Palabra',
      type: ActivityType.palabraPalabra,
      icon: Icons.compare_arrows_rounded,
    ),
    _GameShortcut(
      title: 'Imagen y Frase',
      type: ActivityType.imagenFrase,
      icon: Icons.text_snippet_rounded,
    ),
    _GameShortcut(
      title: 'Juego de Sonidos',
      type: ActivityType.sonidos,
      icon: Icons.volume_up_rounded,
    ),
    _GameShortcut(
      title: 'Letras y Vocales',
      type: ActivityType.letraObjetivo,
      icon: Icons.spellcheck_rounded,
    ),
    _GameShortcut(
      title: 'Tienda de Chuches',
      type: ActivityType.cambioExacto,
      icon: Icons.shopping_bag_rounded,
    ),
    _GameShortcut(
      title: 'Ruleta de Letras',
      type: ActivityType.ruletaLetras,
      icon: Icons.rotate_right_rounded,
    ),
    _GameShortcut(
      title: 'Discriminación',
      type: ActivityType.discriminacion,
      icon: Icons.filter_center_focus_rounded,
    ),
    _GameShortcut(
      title: 'Discriminación Inversa',
      type: ActivityType.discriminacionInversa,
      icon: Icons.find_replace_rounded,
    ),
  ];

  static const _mainIslands = <_MainIslandDefinition>[
    _MainIslandDefinition(
      id: 'letras',
      title: 'Letras',
      subtitle: 'Isla de Sonidos',
      symbol: 'Aa',
      accentColor: Color(0xFFFF7A00),
      fillColor: Color(0xFFFFA24D),
      badgeIcon: Icons.music_note_rounded,
      games: [ActivityType.letraObjetivo, ActivityType.ruletaLetras],
    ),
    _MainIslandDefinition(
      id: 'silabas',
      title: 'Sílabas',
      subtitle: 'Isla de Uniones',
      symbol: 'Ma-pa',
      accentColor: Color(0xFF2F7DED),
      fillColor: Color(0xFF4A8EF0),
      badgeIcon: Icons.link_rounded,
      games: [
        ActivityType.palabraPalabra,
        ActivityType.discriminacion,
        ActivityType.discriminacionInversa,
      ],
    ),
    _MainIslandDefinition(
      id: 'palabras',
      title: 'Palabras',
      subtitle: 'Isla de Historias',
      icon: Icons.auto_stories_rounded,
      accentColor: Color(0xFF16B982),
      fillColor: Color(0xFF1AB586),
      badgeIcon: Icons.menu_book_rounded,
      games: [
        ActivityType.imagenPalabra,
        ActivityType.imagenFrase,
        ActivityType.sonidos,
      ],
    ),
    _MainIslandDefinition(
      id: 'escritura',
      title: 'Escritura',
      subtitle: 'Isla de Trazos',
      icon: Icons.edit_rounded,
      accentColor: Color(0xFFA65AF0),
      fillColor: Color(0xFF9B55E2),
      badgeIcon: Icons.draw_rounded,
      games: [ActivityType.escribirPalabra, ActivityType.cambioExacto],
    ),
  ];

  static final _categoryChoices = <AppCategory>[
    AppCategory.mixta,
    ...AppCategoryLists.reales,
  ];

  _QuickTrack _quickTrackForType(ActivityType type) {
    for (final track in _quickTracks) {
      if (track.gameType == type) {
        return track;
      }
    }
    return _quickTracks.first;
  }

  void _openAllGamesSheet({
    required HomeSelectionState selection,
    required HomeSelectionViewModel selectionVm,
  }) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Menú rápido',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF111D3A),
                    ),
                  ),
                  const SizedBox(height: 12),
                  _QuickActionTile(
                    icon: Icons.auto_awesome_rounded,
                    title: 'Pantalla IA nueva',
                    subtitle: 'Genera recursos y juega preguntas IA',
                    onTap: () {
                      Navigator.of(context).pop();
                      setState(() => _currentTab = 1);
                    },
                  ),
                  _QuickActionTile(
                    icon: Icons.auto_fix_high_rounded,
                    title: 'Studio IA clásico',
                    subtitle: 'Editor completo de recursos IA',
                    onTap: () {
                      Navigator.of(context).pop();
                      Navigator.of(this.context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => const AiResourceStudioScreen(),
                        ),
                      );
                    },
                  ),
                  _QuickActionTile(
                    icon: Icons.analytics_outlined,
                    title: 'Panel terapeuta',
                    subtitle: 'Métricas y recomendaciones adaptativas',
                    onTap: () {
                      Navigator.of(context).pop();
                      Navigator.of(this.context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => const TherapistPanelScreen(),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Todos los juegos',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF111D3A),
                    ),
                  ),
                  const SizedBox(height: 8),
                  ..._allGameShortcuts.map((shortcut) {
                    return _QuickActionTile(
                      icon: shortcut.icon,
                      title: shortcut.title,
                      subtitle: 'Abrir selector del juego',
                      onTap: () {
                        Navigator.of(context).pop();
                        _startActivity(
                          selection: selection,
                          selectionVm: selectionVm,
                          type: shortcut.type,
                        );
                      },
                    );
                  }),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _startActivity({
    required HomeSelectionState selection,
    required HomeSelectionViewModel selectionVm,
    required ActivityType type,
    AppCategory? categoryOverride,
  }) {
    final category = categoryOverride ?? selection.category;
    selectionVm.setCategory(category, optionId: category.id);
    selectionVm.setGame(type);
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => ActivitySelectionScreen(
          category: category,
          activityType: type,
          difficulty: selection.difficulty,
        ),
      ),
    );
  }

  void _openIslandHub({
    required _MainIslandDefinition island,
    required HomeSelectionState selection,
    required HomeSelectionViewModel selectionVm,
  }) {
    final games = island.games.map((type) {
      final track = _quickTrackForType(type);
      return _IslandSubGame(
        type: type,
        title: track.title,
        subtitle: track.subtitle,
        icon: track.icon,
        accentColor: track.iconColor,
      );
    }).toList();

    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => _IslandHubScreen(
          island: island,
          categories: _categoryChoices,
          initialCategory: selection.category,
          games: games,
          onStartGame: (pickedCategory, type) {
            _startActivity(
              selection: selection,
              selectionVm: selectionVm,
              type: type,
              categoryOverride: pickedCategory,
            );
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(progressViewModelProvider);
    final selection = ref.watch(homeSelectionViewModelProvider);
    final selectionVm = ref.read(homeSelectionViewModelProvider.notifier);
    final progressVm = ref.read(progressViewModelProvider.notifier);
    final settings = ref.watch(settingsViewModelProvider);
    final settingsVm = ref.read(settingsViewModelProvider.notifier);
    final profile = ref.watch(localProfileProvider);

    if (!_didSyncSettings) {
      _didSyncSettings = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        selectionVm.setDifficulty(settings.defaultDifficulty);
      });
    }

    return Scaffold(
      backgroundColor: const Color(0xFFEDEFF3),
      body: SafeArea(
        bottom: false,
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 220),
          child: switch (_currentTab) {
            1 => AiPlayScreen(
              key: const ValueKey('ai-tab'),
              embedded: true,
              onOpenSettings: () => setState(() => _currentTab = 3),
            ),
            2 => ProgressDashboardScreen(
              key: const ValueKey('progress-tab'),
              category: selection.category,
              embedded: true,
            ),
            3 => _SettingsTab(
              key: const ValueKey('settings-tab'),
              settings: settings,
              settingsVm: settingsVm,
              onOpenSettings: () {
                Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => const SettingsScreen(),
                  ),
                );
              },
            ),
            _ => _HomeTab(
              key: const ValueKey('home-tab'),
              profileName: profile.displayName,
              progressVm: progressVm,
              islands: _mainIslands,
              onMenuTap: () => _openAllGamesSheet(
                selection: selection,
                selectionVm: selectionVm,
              ),
              onProfileTap: () => setState(() => _currentTab = 1),
              onOpenIsland: (island) => _openIslandHub(
                island: island,
                selection: selection,
                selectionVm: selectionVm,
              ),
              onOpenAi: () => setState(() => _currentTab = 1),
              onOpenProgress: () => setState(() => _currentTab = 2),
            ),
          },
        ),
      ),
      bottomNavigationBar: _BottomNavBar(
        index: _currentTab,
        onChanged: (index) {
          setState(() => _currentTab = index);
        },
      ),
    );
  }
}

class _HomeTab extends StatelessWidget {
  const _HomeTab({
    super.key,
    required this.profileName,
    required this.progressVm,
    required this.islands,
    required this.onMenuTap,
    required this.onProfileTap,
    required this.onOpenIsland,
    required this.onOpenAi,
    required this.onOpenProgress,
  });

  final String profileName;
  final ProgressViewModel progressVm;
  final List<_MainIslandDefinition> islands;
  final VoidCallback onMenuTap;
  final VoidCallback onProfileTap;
  final ValueChanged<_MainIslandDefinition> onOpenIsland;
  final VoidCallback onOpenAi;
  final VoidCallback onOpenProgress;

  @override
  Widget build(BuildContext context) {
    final rewards = progressVm.rewardsSummary();
    final results = progressVm.getAllResults();
    final totalCorrect = results.fold<int>(
      0,
      (sum, item) => sum + item.correct,
    );
    final totalAttempts = results.fold<int>(
      0,
      (sum, item) => sum + item.correct + item.incorrect,
    );
    final accuracy = totalAttempts == 0
        ? 0
        : ((totalCorrect / totalAttempts) * 100).round();
    final xp = (totalCorrect * 10) + (rewards.currentStreak * 25);
    final streakDays = rewards.currentStreak;
    final streakLabel = streakDays == 1 ? '1 día' : '$streakDays días';
    final progressRatio = accuracy.clamp(0, 100) / 100.0;
    final attemptsSummary = totalAttempts == 0
        ? 'Aún sin intentos hoy. Empieza una actividad.'
        : '$totalCorrect aciertos de $totalAttempts intentos hoy';

    final width = MediaQuery.sizeOf(context).width;
    final isTablet = width >= 900;
    final horizontalPadding = isTablet ? 28.0 : 14.0;
    final contentWidth = isTablet ? 1320.0 : 860.0;
    final playerName = profileName.split(' ').first;
    final playerLabel = playerName.trim().isEmpty
        ? 'Explorador'
        : _titleCase(playerName);

    return ListView(
      padding: EdgeInsets.fromLTRB(
        horizontalPadding,
        isTablet ? 16 : 10,
        horizontalPadding,
        isTablet ? 16 : 10,
      ),
      children: [
        Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: contentWidth),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFE9E4DE)),
                  ),
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                  child: Row(
                    children: [
                      Container(
                        width: isTablet ? 50 : 44,
                        height: isTablet ? 50 : 44,
                        decoration: BoxDecoration(
                          color: const Color(0xFFEF5B10),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Icon(
                          Icons.menu_book_rounded,
                          color: Colors.white,
                          size: isTablet ? 26 : 22,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'EduMundo',
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.w900,
                                color: Color(0xFF101A35),
                                height: 1.0,
                              ),
                            ),
                            const SizedBox(height: 1),
                            const Text(
                              'ISLAS DE APRENDIZAJE',
                              style: TextStyle(
                                fontSize: 10,
                                letterSpacing: 2.4,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFFEF5B10),
                              ),
                            ),
                          ],
                        ),
                      ),
                      InkWell(
                        borderRadius: BorderRadius.circular(999),
                        onTap: onOpenProgress,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(999),
                            color: const Color(0xFFFFF4EC),
                            border: Border.all(color: const Color(0xFFFFC9A2)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.star_rounded,
                                color: Color(0xFFEF5B10),
                                size: 18,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                '$xp',
                                style: const TextStyle(
                                  color: Color(0xFF111B35),
                                  fontWeight: FontWeight.w900,
                                  fontSize: 18,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      IconButton(
                        onPressed: onMenuTap,
                        icon: const Icon(Icons.notifications_rounded),
                        color: const Color(0xFF5C6B89),
                        tooltip: 'Menú',
                      ),
                      InkWell(
                        borderRadius: BorderRadius.circular(999),
                        onTap: onProfileTap,
                        child: Container(
                          width: 48,
                          height: 48,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: const Color(0xFF8CCCB3),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: const Color(0xFFEF5B10),
                              width: 2,
                            ),
                          ),
                          child: Text(
                            playerName.isEmpty
                                ? 'E'
                                : playerName[0].toUpperCase(),
                            style: const TextStyle(
                              color: Color(0xFF123A2C),
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 34),
                Center(
                  child: Column(
                    children: [
                      Text(
                        '¡Hola $playerLabel!',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: isTablet ? 54 : 36,
                          fontWeight: FontWeight.w900,
                          color: const Color(0xFF101A35),
                          height: 1.02,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '¿Qué isla visitaremos hoy?',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: isTablet ? 24 : 19,
                          color: const Color(0xFFEF5B10),
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 26),
                GridView.count(
                  crossAxisCount: isTablet ? 4 : 2,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  childAspectRatio: isTablet ? 0.88 : 0.78,
                  mainAxisSpacing: isTablet ? 20 : 12,
                  crossAxisSpacing: isTablet ? 20 : 12,
                  children: islands.map((island) {
                    return _HomeMainIslandTile(
                      island: island,
                      onTap: () => onOpenIsland(island),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 14),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Color(0xFFFFF6EF), Color(0xFFFFFDF8)],
                    ),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: const Color(0xFFFFCCA8)),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x1FEF5B10),
                        blurRadius: 18,
                        offset: Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 34,
                            height: 34,
                            decoration: const BoxDecoration(
                              color: Color(0xFFFFE4D1),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.star_rounded,
                              color: Color(0xFFEF5B10),
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 10),
                          const Expanded(
                            child: Text(
                              'PROGRESO DE HOY',
                              style: TextStyle(
                                color: Color(0xFF9D4A16),
                                fontWeight: FontWeight.w900,
                                letterSpacing: 0.6,
                                fontSize: 14,
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFEF5B10),
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.local_fire_department_rounded,
                                  size: 16,
                                  color: Colors.white,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  'Racha $streakLabel',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w900,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: _HomeProgressMetricCard(
                              icon: Icons.track_changes_rounded,
                              label: 'Precisión',
                              value: '$accuracy%',
                              valueColor: const Color(0xFFEF5B10),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _HomeProgressMetricCard(
                              icon: Icons.bolt_rounded,
                              label: 'Puntos',
                              value: '$xp XP',
                              valueColor: const Color(0xFFB94A0D),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(999),
                        child: LinearProgressIndicator(
                          minHeight: 12,
                          value: progressRatio,
                          backgroundColor: const Color(0xFFFFE3CE),
                          valueColor: const AlwaysStoppedAnimation<Color>(
                            Color(0xFFEF5B10),
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              attemptsSummary,
                              style: const TextStyle(
                                color: Color(0xFF7E5B45),
                                fontWeight: FontWeight.w700,
                                fontSize: 13,
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          FilledButton.icon(
                            onPressed: onOpenAi,
                            style: FilledButton.styleFrom(
                              backgroundColor: const Color(0xFFEF5B10),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 10,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(999),
                              ),
                            ),
                            icon: const Icon(
                              Icons.auto_awesome_rounded,
                              size: 18,
                            ),
                            label: const Text(
                              'IA',
                              style: TextStyle(
                                fontWeight: FontWeight.w900,
                                letterSpacing: 0.3,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _HomeMainIslandTile extends StatelessWidget {
  const _HomeMainIslandTile({required this.island, required this.onTap});

  final _MainIslandDefinition island;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isTablet = MediaQuery.sizeOf(context).width >= 900;
    final circleSize = isTablet ? 172.0 : 132.0;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: onTap,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            Stack(
              clipBehavior: Clip.none,
              alignment: Alignment.center,
              children: [
                Container(
                  width: circleSize,
                  height: circleSize,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: [
                        island.fillColor.withValues(alpha: 0.95),
                        island.accentColor,
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    border: Border.all(
                      color: island.accentColor.withValues(alpha: 0.55),
                      width: 4,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: island.accentColor.withValues(alpha: 0.25),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Center(
                    child: island.symbol != null
                        ? Text(
                            island.symbol!,
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w900,
                              fontSize: isTablet ? 58 : 48,
                              height: 1.0,
                            ),
                            textAlign: TextAlign.center,
                          )
                        : Icon(
                            island.icon,
                            color: Colors.white,
                            size: isTablet ? 72 : 58,
                          ),
                  ),
                ),
                Positioned(
                  right: 0,
                  bottom: 0,
                  child: Container(
                    width: isTablet ? 44 : 36,
                    height: isTablet ? 44 : 36,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      border: Border.all(color: const Color(0xFFE2E7EF)),
                    ),
                    child: Icon(
                      island.badgeIcon,
                      color: island.accentColor,
                      size: isTablet ? 22 : 18,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              island.title,
              style: TextStyle(
                fontSize: isTablet ? 40 : 28,
                fontWeight: FontWeight.w900,
                color: const Color(0xFF161F3C),
                height: 1.0,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              island.subtitle,
              style: TextStyle(
                fontSize: isTablet ? 24 : 16,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF60708F),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _IslandHubScreen extends StatefulWidget {
  const _IslandHubScreen({
    required this.island,
    required this.categories,
    required this.initialCategory,
    required this.games,
    required this.onStartGame,
  });

  final _MainIslandDefinition island;
  final List<AppCategory> categories;
  final AppCategory initialCategory;
  final List<_IslandSubGame> games;
  final void Function(AppCategory category, ActivityType type) onStartGame;

  @override
  State<_IslandHubScreen> createState() => _IslandHubScreenState();
}

class _IslandHubScreenState extends State<_IslandHubScreen> {
  late AppCategory _selectedCategory = widget.initialCategory;

  Future<void> _openCategorySelector() async {
    final picked = await showModalBottomSheet<AppCategory>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Modificar categoría',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF131C37),
                  ),
                ),
                const SizedBox(height: 10),
                Flexible(
                  child: ListView.separated(
                    shrinkWrap: true,
                    itemCount: widget.categories.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final category = widget.categories[index];
                      final selected = category == _selectedCategory;
                      return Material(
                        color: selected
                            ? widget.island.accentColor.withValues(alpha: 0.14)
                            : const Color(0xFFF5F8FD),
                        borderRadius: BorderRadius.circular(14),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(14),
                          onTap: () => Navigator.of(context).pop(category),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 12,
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  category.icon,
                                  color: selected
                                      ? widget.island.accentColor
                                      : const Color(0xFF5D6F94),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    _categoryPickerLabel(
                                      category,
                                    ).toUpperCase(),
                                    style: TextStyle(
                                      fontWeight: FontWeight.w800,
                                      color: selected
                                          ? widget.island.accentColor
                                          : const Color(0xFF1A2745),
                                    ),
                                  ),
                                ),
                                if (selected)
                                  Icon(
                                    Icons.check_circle_rounded,
                                    color: widget.island.accentColor,
                                  ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
    if (picked != null) {
      setState(() => _selectedCategory = picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isTablet = MediaQuery.sizeOf(context).width >= 900;
    return Scaffold(
      backgroundColor: const Color(0xFFF1F3F8),
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        title: Text(
          widget.island.title,
          style: const TextStyle(
            fontWeight: FontWeight.w900,
            color: Color(0xFF101A35),
          ),
        ),
      ),
      body: SafeArea(
        top: false,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1240),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(18, 18, 18, 20),
              children: [
                Text(
                  'Subcategorías de ${widget.island.title}',
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF101A35),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Elige la categoría activa y luego el tipo de juego.',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.blueGrey.shade600,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFDCE5F2)),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Categoría activa: ${_categoryPickerLabel(_selectedCategory).toUpperCase()}',
                          style: const TextStyle(
                            color: Color(0xFF3B4F77),
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      OutlinedButton.icon(
                        onPressed: _openCategorySelector,
                        icon: const Icon(Icons.tune_rounded, size: 18),
                        label: const Text(
                          'MODIFICAR CATEGORÍA',
                          style: TextStyle(fontWeight: FontWeight.w900),
                        ),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: widget.island.accentColor,
                          side: BorderSide(color: widget.island.accentColor),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(999),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),
                Row(
                  children: [
                    const Icon(
                      Icons.extension_rounded,
                      color: Color(0xFFEF5B10),
                      size: 20,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Tipos de juego (${widget.games.length})',
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF1A2745),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                GridView.builder(
                  itemCount: widget.games.length,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: isTablet ? 2 : 1,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: isTablet ? 1.65 : 1.35,
                  ),
                  itemBuilder: (context, index) {
                    final game = widget.games[index];
                    return Material(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(22),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(22),
                        onTap: () {
                          widget.onStartGame(_selectedCategory, game.type);
                        },
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(22),
                            border: Border.all(color: const Color(0xFFDDE5F2)),
                          ),
                          padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  CircleAvatar(
                                    radius: 24,
                                    backgroundColor: game.accentColor
                                        .withValues(alpha: 0.16),
                                    child: Icon(
                                      game.icon,
                                      color: game.accentColor,
                                      size: 26,
                                    ),
                                  ),
                                  const Spacer(),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: game.accentColor.withValues(
                                        alpha: 0.14,
                                      ),
                                      borderRadius: BorderRadius.circular(999),
                                    ),
                                    child: Text(
                                      _categoryPickerLabel(
                                        _selectedCategory,
                                      ).toUpperCase(),
                                      style: TextStyle(
                                        color: game.accentColor,
                                        fontSize: 11,
                                        fontWeight: FontWeight.w900,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Text(
                                game.title.toUpperCase(),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w900,
                                  color: Color(0xFF111D3A),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                game.subtitle,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: Color(0xFF61739A),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const Spacer(),
                              Align(
                                alignment: Alignment.centerRight,
                                child: FilledButton(
                                  onPressed: () {
                                    widget.onStartGame(
                                      _selectedCategory,
                                      game.type,
                                    );
                                  },
                                  style: FilledButton.styleFrom(
                                    backgroundColor: game.accentColor,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(999),
                                    ),
                                  ),
                                  child: const Text(
                                    'JUGAR',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w900,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SettingsTab extends StatelessWidget {
  const _SettingsTab({
    super.key,
    required this.settings,
    required this.settingsVm,
    required this.onOpenSettings,
  });

  final AppSettings settings;
  final SettingsViewModel settingsVm;
  final VoidCallback onOpenSettings;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 22, 20, 24),
      children: [
        const Text(
          'Ajustes',
          style: TextStyle(
            fontSize: 38,
            fontWeight: FontWeight.w900,
            color: Color(0xFF111D3A),
          ),
        ),
        const SizedBox(height: 4),
        const Text(
          'Configura accesibilidad y experiencia de juego.',
          style: TextStyle(
            fontSize: 21,
            color: Color(0xFF6A7898),
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 16),
        _SwitchCard(
          title: 'Audio (TTS local)',
          subtitle: 'Lee palabras y consignas en voz alta.',
          value: settings.audioEnabled,
          onChanged: settingsVm.setAudioEnabled,
        ),
        _SwitchCard(
          title: 'Alto contraste',
          subtitle: 'Mejora visibilidad en interfaces claras.',
          value: settings.highContrast,
          onChanged: settingsVm.setHighContrast,
        ),
        _SwitchCard(
          title: 'Modo dislexia',
          subtitle: 'Aumenta espaciado para lectura cómoda.',
          value: settings.dyslexiaMode,
          onChanged: settingsVm.setDyslexiaMode,
        ),
        const SizedBox(height: 10),
        FilledButton.icon(
          onPressed: onOpenSettings,
          icon: const Icon(Icons.tune_rounded),
          label: const Text('Abrir ajustes completos'),
          style: FilledButton.styleFrom(
            backgroundColor: const Color(0xFF2C7BEA),
            foregroundColor: Colors.white,
            minimumSize: const Size.fromHeight(58),
            textStyle: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
            ),
          ),
        ),
      ],
    );
  }
}

class _SwitchCard extends StatelessWidget {
  const _SwitchCard({
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFD6DFEE)),
      ),
      child: SwitchListTile(
        value: value,
        onChanged: onChanged,
        title: Text(
          title,
          style: const TextStyle(
            color: Color(0xFF111D3A),
            fontWeight: FontWeight.w800,
            fontSize: 18,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: const TextStyle(color: Color(0xFF64789C), fontSize: 15),
        ),
        activeThumbColor: const Color(0xFF2C7BEA),
      ),
    );
  }
}

class _BottomNavBar extends StatelessWidget {
  const _BottomNavBar({required this.index, required this.onChanged});

  final int index;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Color(0xFFDCE4F1))),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 8, 14, 8),
          child: Row(
            children: [
              Expanded(
                child: _BottomNavItem(
                  selected: index == 0,
                  icon: Icons.home_rounded,
                  label: 'Inicio',
                  onTap: () => onChanged(0),
                ),
              ),
              Expanded(
                child: _BottomNavItem(
                  selected: index == 1,
                  icon: Icons.auto_awesome_rounded,
                  label: 'IA',
                  onTap: () => onChanged(1),
                ),
              ),
              Expanded(
                child: _BottomNavItem(
                  selected: index == 2,
                  icon: Icons.bar_chart_rounded,
                  label: 'Progreso',
                  onTap: () => onChanged(2),
                ),
              ),
              Expanded(
                child: _BottomNavItem(
                  selected: index == 3,
                  icon: Icons.settings_rounded,
                  label: 'Ajustes',
                  onTap: () => onChanged(3),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BottomNavItem extends StatelessWidget {
  const _BottomNavItem({
    required this.selected,
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final bool selected;
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final fg = selected ? const Color(0xFF2C7BEA) : const Color(0xFF95A3BE);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: fg, size: 30),
              const SizedBox(height: 3),
              Text(
                label,
                style: TextStyle(
                  color: fg,
                  fontSize: 16,
                  fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HomeProgressMetricCard extends StatelessWidget {
  const _HomeProgressMetricCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.valueColor,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color valueColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(10, 9, 10, 9),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFFFD7BC)),
      ),
      child: Row(
        children: [
          Icon(icon, color: const Color(0xFFEF5B10), size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFFA87555),
                  ),
                ),
                const SizedBox(height: 1),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    color: valueColor,
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

class _QuickActionTile extends StatelessWidget {
  const _QuickActionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: const Color(0xFFF5F8FD),
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Icon(icon, color: const Color(0xFF2C7BEA)),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF1A2745),
                        ),
                      ),
                      Text(
                        subtitle,
                        style: const TextStyle(
                          color: Color(0xFF63789D),
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.chevron_right_rounded,
                  color: Color(0xFF9EB0CF),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _MainIslandDefinition {
  const _MainIslandDefinition({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.accentColor,
    required this.fillColor,
    required this.badgeIcon,
    required this.games,
    this.icon,
    this.symbol,
  });

  final String id;
  final String title;
  final String subtitle;
  final IconData? icon;
  final String? symbol;
  final Color accentColor;
  final Color fillColor;
  final IconData badgeIcon;
  final List<ActivityType> games;
}

class _IslandSubGame {
  const _IslandSubGame({
    required this.type,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.accentColor,
  });

  final ActivityType type;
  final String title;
  final String subtitle;
  final IconData icon;
  final Color accentColor;
}

class _QuickTrack {
  const _QuickTrack({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.iconColor,
    required this.backgroundColor,
    required this.gameType,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final Color iconColor;
  final Color backgroundColor;
  final ActivityType gameType;
}

class _GameShortcut {
  const _GameShortcut({
    required this.title,
    required this.type,
    required this.icon,
  });

  final String title;
  final ActivityType type;
  final IconData icon;
}
