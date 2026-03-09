import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/providers/app_providers.dart';
import '../../domain/models/app_settings.dart';
import '../../domain/models/activity_type.dart';
import '../../domain/models/ai_resource.dart';
import '../../domain/models/category.dart';
import '../utils/category_visuals.dart';
import '../viewmodels/ai_resource_studio_view_model.dart';
import '../viewmodels/home_selection_view_model.dart';
import '../viewmodels/progress_view_model.dart';
import '../viewmodels/settings_view_model.dart';
import 'activity_selection_screen.dart';
import 'ai_play_screen.dart';
import 'ai_resource_studio_screen.dart';
import 'generated_session_game_screen.dart';
import 'progress_dashboard_screen.dart';
import 'settings_screen.dart';
import 'therapist_panel_screen.dart';

String _categoryDisplayLabel(AppCategory category) {
  if (category == AppCategory.mixta) {
    return 'MIX DE COSAS';
  }
  return category.label;
}

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

int _dayOfYear(DateTime date) {
  final start = DateTime(date.year, 1, 1);
  return date.difference(start).inDays + 1;
}

_QuickTrack _dailyChallengeTrack({
  required List<_QuickTrack> tracks,
  required DateTime now,
}) {
  if (tracks.isEmpty) {
    throw StateError('No hay juegos disponibles para reto diario.');
  }
  if (tracks.length == 1) {
    return tracks.first;
  }

  final todaySeed = now.year * 1000 + _dayOfYear(now);
  final yesterday = now.subtract(const Duration(days: 1));
  final yesterdaySeed = yesterday.year * 1000 + _dayOfYear(yesterday);

  final todayIndex = Random(todaySeed).nextInt(tracks.length);
  final yesterdayIndex = Random(yesterdaySeed).nextInt(tracks.length);
  final adjustedToday = todayIndex == yesterdayIndex
      ? (todayIndex + 1) % tracks.length
      : todayIndex;

  return tracks[adjustedToday];
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

  static final _categoryChoices = <AppCategory>[
    AppCategory.mixta,
    ...AppCategoryLists.reales,
  ];

  Future<void> _openCategoryPicker({
    required HomeSelectionViewModel selectionVm,
    required AppCategory selected,
  }) async {
    final picked = await Navigator.of(context).push<AppCategory>(
      MaterialPageRoute<AppCategory>(
        builder: (_) => _CategoryPickerScreen(
          selected: selected,
          choices: _categoryChoices,
        ),
      ),
    );

    if (picked == null) {
      return;
    }
    selectionVm.setCategory(picked, optionId: picked.id);
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
  }) {
    selectionVm.setGame(type);
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => ActivitySelectionScreen(
          category: selection.category,
          activityType: type,
          difficulty: selection.difficulty,
        ),
      ),
    );
  }

  void _openGeneratedGame(AiResource resource) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => GeneratedSessionGameScreen(
          resourceId: resource.id,
          sessionTitle: resource.title,
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
    final aiState = ref.watch(aiResourceStudioViewModelProvider);
    final savedResources =
        aiState.resources.where((resource) => resource.isFavorite).toList()
          ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

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
            2 => _ProgressTab(
              key: const ValueKey('progress-tab'),
              selection: selection,
              progressVm: progressVm,
              onOpenDashboard: () {
                Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) =>
                        ProgressDashboardScreen(category: selection.category),
                  ),
                );
              },
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
              category: selection.category,
              progressVm: progressVm,
              savedResources: savedResources,
              onMenuTap: () => _openAllGamesSheet(
                selection: selection,
                selectionVm: selectionVm,
              ),
              onProfileTap: () => setState(() => _currentTab = 1),
              onPickCategory: () => _openCategoryPicker(
                selectionVm: selectionVm,
                selected: selection.category,
              ),
              onTrackTap: (track) => _startActivity(
                selection: selection,
                selectionVm: selectionVm,
                type: track.gameType,
              ),
              onOpenAi: () => setState(() => _currentTab = 1),
              onOpenProgress: () => setState(() => _currentTab = 2),
              onOpenSavedResource: _openGeneratedGame,
              onToggleSavedResource: (resource) {
                ref
                    .read(aiResourceStudioViewModelProvider.notifier)
                    .toggleFavorite(resource.id);
              },
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
    required this.category,
    required this.progressVm,
    required this.savedResources,
    required this.onMenuTap,
    required this.onProfileTap,
    required this.onPickCategory,
    required this.onTrackTap,
    required this.onOpenAi,
    required this.onOpenProgress,
    required this.onOpenSavedResource,
    required this.onToggleSavedResource,
  });

  final String profileName;
  final AppCategory category;
  final ProgressViewModel progressVm;
  final List<AiResource> savedResources;
  final VoidCallback onMenuTap;
  final VoidCallback onProfileTap;
  final VoidCallback onPickCategory;
  final VoidCallback onOpenAi;
  final VoidCallback onOpenProgress;
  final ValueChanged<_QuickTrack> onTrackTap;
  final ValueChanged<AiResource> onOpenSavedResource;
  final ValueChanged<AiResource> onToggleSavedResource;

  @override
  Widget build(BuildContext context) {
    final rewards = progressVm.rewardsSummary();
    final width = MediaQuery.sizeOf(context).width;
    final isTablet = width >= 900;
    final horizontalPadding = isTablet ? 28.0 : 20.0;
    final contentWidth = isTablet ? 1080.0 : 760.0;
    final nextMilestone = rewards.currentStreak >= 5
        ? '¡Racha excelente!'
        : 'Estás a ${(5 - rewards.currentStreak).clamp(1, 5)} juegos de una racha de 5';
    final playerName = profileName.split(' ').first;
    final dailyTrack = _dailyChallengeTrack(
      tracks: _HomeScreenState._quickTracks,
      now: DateTime.now(),
    );

    final learningTracks = Column(
      children: _HomeScreenState._quickTracks.map((track) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 14),
          child: _LearningCard(track: track, onTap: () => onTrackTap(track)),
        );
      }).toList(),
    );

    final savedResourcesPanel = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Guardados IA',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: Color(0xFF203257),
          ),
        ),
        const SizedBox(height: 8),
        if (savedResources.isEmpty)
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFD8E0EE)),
            ),
            child: const Text(
              'Todavía no tienes recursos guardados. En la pantalla IA pulsa "Guardar en inicio" para añadirlos aquí.',
              style: TextStyle(
                color: Color(0xFF5E7094),
                fontWeight: FontWeight.w600,
              ),
            ),
          )
        else
          ...savedResources.take(isTablet ? 6 : 5).map((resource) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _SavedResourceCard(
                resource: resource,
                onPlay: resource.playableQuestions.isEmpty
                    ? null
                    : () => onOpenSavedResource(resource),
                onToggleSaved: () => onToggleSavedResource(resource),
              ),
            );
          }),
      ],
    );

    return ListView(
      padding: EdgeInsets.fromLTRB(
        horizontalPadding,
        14,
        horizontalPadding,
        24,
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
                    gradient: const LinearGradient(
                      colors: [Color(0xFF4C98F5), Color(0xFF4387EE)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(isTablet ? 36 : 30),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF2B72D8).withValues(alpha: 0.34),
                        blurRadius: 28,
                        offset: const Offset(0, 14),
                      ),
                    ],
                  ),
                  padding: EdgeInsets.fromLTRB(
                    isTablet ? 28 : 20,
                    isTablet ? 24 : 18,
                    isTablet ? 24 : 18,
                    isTablet ? 28 : 20,
                  ),
                  child: Row(
                    children: [
                      InkWell(
                        borderRadius: BorderRadius.circular(999),
                        onTap: onMenuTap,
                        child: Container(
                          width: isTablet ? 92 : 74,
                          height: isTablet ? 92 : 74,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: const Color(0xFFCFE0FB),
                              width: 3,
                            ),
                          ),
                          child: Icon(
                            Icons.pets_rounded,
                            color: const Color(0xFF4C98F5),
                            size: isTablet ? 48 : 40,
                          ),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'EduMundo',
                              style: TextStyle(
                                fontSize: isTablet ? 54 : 36,
                                fontWeight: FontWeight.w900,
                                color: Colors.white,
                                height: 0.95,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              '¡Hola, $playerName! Explora colores, letras y retos.',
                              style: TextStyle(
                                fontSize: isTablet ? 25 : 20,
                                fontWeight: FontWeight.w700,
                                color: Colors.white.withValues(alpha: 0.96),
                                height: 1.12,
                              ),
                            ),
                          ],
                        ),
                      ),
                      InkWell(
                        borderRadius: BorderRadius.circular(999),
                        onTap: onProfileTap,
                        child: Container(
                          width: isTablet ? 92 : 72,
                          height: isTablet ? 92 : 72,
                          decoration: const BoxDecoration(
                            color: Color(0xFFFFD830),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.star_rounded,
                            color: const Color(0xFF1E2334),
                            size: isTablet ? 50 : 40,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    _HomeQuickCircle(
                      title: 'Reto de hoy',
                      subtitle: dailyTrack.title,
                      icon: Icons.bolt_rounded,
                      ringColor: const Color(0xFF57C46E),
                      fillColor: const Color(0xFFE2F7E7),
                      iconColor: const Color(0xFF57C46E),
                      onTap: () => onTrackTap(dailyTrack),
                    ),
                    _HomeQuickCircle(
                      title: 'Meta hoy',
                      icon: Icons.emoji_events_rounded,
                      ringColor: const Color(0xFFF1C321),
                      fillColor: const Color(0xFFFFF6D7),
                      iconColor: const Color(0xFFF1C321),
                      onTap: onOpenProgress,
                    ),
                    _HomeQuickCircle(
                      title: 'Stickers',
                      icon: Icons.auto_awesome_rounded,
                      ringColor: const Color(0xFF8E71FF),
                      fillColor: const Color(0xFFF0EBFF),
                      iconColor: const Color(0xFF8E71FF),
                      onTap: onOpenAi,
                    ),
                    InkWell(
                      borderRadius: BorderRadius.circular(18),
                      onTap: onPickCategory,
                      child: Container(
                        width: isTablet ? 250 : 220,
                        height: isTablet ? 120 : 108,
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(color: const Color(0xFFD6DFEC)),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(
                                0xFF1A2847,
                              ).withValues(alpha: 0.05),
                              blurRadius: 14,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: isTablet ? 54 : 48,
                              height: isTablet ? 54 : 48,
                              decoration: BoxDecoration(
                                color: category.color.withValues(alpha: 0.18),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(category.icon, color: category.color),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Text(
                                    'Categoría',
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: Color(0xFF7A87A5),
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  Text(
                                    _categoryDisplayLabel(category),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontSize: isTablet ? 20 : 17,
                                      color: const Color(0xFF111D3A),
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                const Text(
                  '¡A aprender!',
                  style: TextStyle(
                    fontSize: 36,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF0F1936),
                  ),
                ),
                const SizedBox(height: 12),
                if (isTablet)
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(flex: 3, child: learningTracks),
                      const SizedBox(width: 16),
                      Expanded(
                        flex: 2,
                        child: Column(
                          children: [
                            _AiEntryCard(onTap: onOpenAi),
                            const SizedBox(height: 14),
                            _ProgressCard(
                              streak: rewards.currentStreak,
                              message: nextMilestone,
                              onTap: onOpenProgress,
                            ),
                            const SizedBox(height: 14),
                            savedResourcesPanel,
                          ],
                        ),
                      ),
                    ],
                  )
                else ...[
                  learningTracks,
                  _AiEntryCard(onTap: onOpenAi),
                  const SizedBox(height: 14),
                  _ProgressCard(
                    streak: rewards.currentStreak,
                    message: nextMilestone,
                    onTap: onOpenProgress,
                  ),
                  const SizedBox(height: 14),
                  savedResourcesPanel,
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _HomeQuickCircle extends StatelessWidget {
  const _HomeQuickCircle({
    required this.title,
    this.subtitle,
    required this.icon,
    required this.ringColor,
    required this.fillColor,
    required this.iconColor,
    required this.onTap,
  });

  final String title;
  final String? subtitle;
  final IconData icon;
  final Color ringColor;
  final Color fillColor;
  final Color iconColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isTablet = MediaQuery.sizeOf(context).width >= 900;
    final size = isTablet ? 150.0 : 130.0;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(999),
        onTap: onTap,
        child: SizedBox(
          width: size,
          child: Column(
            children: [
              Container(
                width: size,
                height: size,
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  border: Border.all(color: ringColor, width: 5),
                ),
                child: Center(
                  child: Container(
                    width: size * 0.56,
                    height: size * 0.56,
                    decoration: BoxDecoration(
                      color: fillColor,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(icon, color: iconColor, size: size * 0.28),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                title.toUpperCase(),
                style: TextStyle(
                  fontSize: isTablet ? 24 : 18,
                  color: const Color(0xFF1E2E4D),
                  fontWeight: FontWeight.w900,
                ),
              ),
              if (subtitle != null) ...[
                const SizedBox(height: 2),
                Text(
                  subtitle!.toUpperCase(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: isTablet ? 15 : 13,
                    color: const Color(0xFF5D6D90),
                    fontWeight: FontWeight.w700,
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

class _CategoryPickerScreen extends StatelessWidget {
  const _CategoryPickerScreen({required this.selected, required this.choices});

  final AppCategory selected;
  final List<AppCategory> choices;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final cardRatio = width >= 1000 ? 1.18 : 0.92;

    return Scaffold(
      backgroundColor: const Color(0xFFEDEFF3),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.arrow_back_rounded),
                    tooltip: 'Volver',
                  ),
                  const Expanded(
                    child: Text(
                      'Categorías',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF111D3A),
                      ),
                    ),
                  ),
                  const SizedBox(width: 48),
                ],
              ),
            ),
            const Divider(height: 1, color: Color(0xFFD6DFEE)),
            Expanded(
              child: CustomScrollView(
                slivers: [
                  const SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.fromLTRB(22, 20, 22, 12),
                      child: Text(
                        '¿Qué quieres aprender hoy?',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF506080),
                        ),
                      ),
                    ),
                  ),
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                    sliver: SliverGrid(
                      delegate: SliverChildBuilderDelegate((context, index) {
                        final category = choices[index];
                        final isSelected = category == selected;
                        return _CategoryGridCard(
                          category: category,
                          isSelected: isSelected,
                          onTap: () => Navigator.of(context).pop(category),
                        );
                      }, childCount: choices.length),
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        crossAxisSpacing: 14,
                        mainAxisSpacing: 14,
                        childAspectRatio: cardRatio,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CategoryGridCard extends StatelessWidget {
  const _CategoryGridCard({
    required this.category,
    required this.isSelected,
    required this.onTap,
  });

  final AppCategory category;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = category.color;
    final fillColor = color.withValues(alpha: isSelected ? 0.22 : 0.14);
    final borderColor = color.withValues(alpha: isSelected ? 0.74 : 0.34);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(36),
        onTap: onTap,
        child: Ink(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: fillColor,
            borderRadius: BorderRadius.circular(36),
            border: Border.all(color: borderColor, width: isSelected ? 3 : 2),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: color.withValues(alpha: 0.22),
                      blurRadius: 18,
                      offset: const Offset(0, 8),
                    ),
                  ]
                : null,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 102,
                height: 102,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
                child: Icon(category.icon, size: 52, color: color),
              ),
              const SizedBox(height: 18),
              Text(
                _categoryPickerLabel(category),
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 23,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF111D3A),
                  height: 1.1,
                ),
              ),
              if (isSelected) ...[
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.9),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: const Text(
                    'Seleccionada',
                    style: TextStyle(
                      color: Color(0xFF2C7BEA),
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
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

class _ProgressTab extends StatelessWidget {
  const _ProgressTab({
    super.key,
    required this.selection,
    required this.progressVm,
    required this.onOpenDashboard,
  });

  final HomeSelectionState selection;
  final ProgressViewModel progressVm;
  final VoidCallback onOpenDashboard;

  @override
  Widget build(BuildContext context) {
    final results = progressVm.getAllResults();
    final rewards = progressVm.rewardsSummary();
    final recommendation = progressVm.adaptivePlanRecommendation();
    final totalCorrect = results.fold<int>(
      0,
      (sum, item) => sum + item.correct,
    );
    final totalIncorrect = results.fold<int>(
      0,
      (sum, item) => sum + item.incorrect,
    );
    final totalAttempts = totalCorrect + totalIncorrect;
    final accuracy = totalAttempts == 0
        ? 0
        : ((totalCorrect / totalAttempts) * 100).round();

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 22, 20, 24),
      children: [
        const Text(
          'Tu Progreso',
          style: TextStyle(
            fontSize: 38,
            fontWeight: FontWeight.w900,
            color: Color(0xFF111D3A),
          ),
        ),
        const SizedBox(height: 4),
        const Text(
          'Resumen rápido de tu avance diario.',
          style: TextStyle(
            fontSize: 22,
            color: Color(0xFF6A7898),
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            gradient: const LinearGradient(
              colors: [Color(0xFF2C7BEA), Color(0xFF1F5DCB)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF2C7BEA).withValues(alpha: 0.30),
                blurRadius: 22,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Objetivo de hoy',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                rewards.activeToday
                    ? '¡Ya entrenaste hoy! Racha activa: ${rewards.currentStreak}'
                    : 'Completa una actividad para mantener la racha.',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  height: 1.2,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        Row(
          children: [
            Expanded(
              child: _MetricCard(
                title: 'Sesiones',
                value: '${results.length}',
                icon: Icons.sports_esports_rounded,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _MetricCard(
                title: 'Precisión',
                value: '$accuracy%',
                icon: Icons.verified_rounded,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _MetricCard(
                title: 'Racha',
                value: '${rewards.currentStreak} días',
                icon: Icons.local_fire_department_rounded,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _MetricCard(
                title: 'Insignias',
                value: '${rewards.unlockedBadges}',
                icon: Icons.workspace_premium_rounded,
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFFD6DFEE)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Siguiente recomendación',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF6780A8),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                recommendation.activityType.label,
                style: const TextStyle(
                  fontSize: 21,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF111D3A),
                  height: 1.2,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                recommendation.reason,
                style: const TextStyle(fontSize: 18, color: Color(0xFF506080)),
              ),
              const SizedBox(height: 10),
              Text(
                'Categoría actual del panel: ${selection.category.label}',
                style: const TextStyle(
                  fontSize: 14,
                  color: Color(0xFF7A87A5),
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        FilledButton.icon(
          onPressed: onOpenDashboard,
          icon: const Icon(Icons.insights_rounded),
          label: const Text('Abrir panel completo'),
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

class _LearningCard extends StatelessWidget {
  const _LearningCard({required this.track, required this.onTap});

  final _QuickTrack track;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isTablet = MediaQuery.sizeOf(context).width >= 900;
    final iconBox = isTablet ? 116.0 : 98.0;
    final titleSize = isTablet ? 46.0 : 38.0;
    final subtitleSize = isTablet ? 17.0 : 15.0;
    final (mainColor, darkColor) = switch (track.gameType) {
      ActivityType.letraObjetivo => (
        const Color(0xFFFA5B0A),
        const Color(0xFFD84B06),
      ),
      ActivityType.palabraPalabra => (
        const Color(0xFF67C975),
        const Color(0xFF44A855),
      ),
      ActivityType.imagenPalabra => (
        const Color(0xFF4B92EA),
        const Color(0xFF2B73D5),
      ),
      ActivityType.escribirPalabra => (
        const Color(0xFFF1A42A),
        const Color(0xFFCF8413),
      ),
      ActivityType.imagenFrase => (
        const Color(0xFF27B5C0),
        const Color(0xFF1896A0),
      ),
      ActivityType.ruletaLetras => (
        const Color(0xFF8B6BE8),
        const Color(0xFF6D50C8),
      ),
      ActivityType.discriminacion => (
        const Color(0xFF2FB374),
        const Color(0xFF21905B),
      ),
      ActivityType.discriminacionInversa => (
        const Color(0xFFF08C33),
        const Color(0xFFCF6D19),
      ),
      ActivityType.cambioExacto => (
        const Color(0xFFD756A4),
        const Color(0xFFB73F87),
      ),
    };

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(44),
        onTap: onTap,
        child: Ink(
          padding: EdgeInsets.symmetric(
            horizontal: isTablet ? 22 : 18,
            vertical: isTablet ? 18 : 14,
          ),
          decoration: BoxDecoration(
            color: mainColor,
            borderRadius: BorderRadius.circular(44),
            boxShadow: [
              BoxShadow(
                color: darkColor.withValues(alpha: 0.95),
                blurRadius: 0,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: iconBox,
                height: iconBox,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.20),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  track.icon,
                  color: Colors.white,
                  size: isTablet ? 52 : 46,
                ),
              ),
              const SizedBox(width: 18),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      track.title.toUpperCase(),
                      style: TextStyle(
                        fontSize: titleSize,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                        height: 1.0,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      track.subtitle,
                      style: TextStyle(
                        fontSize: subtitleSize,
                        color: Colors.white.withValues(alpha: 0.88),
                        height: 1.2,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Icon(
                Icons.chevron_right_rounded,
                color: Colors.white.withValues(alpha: 0.88),
                size: 38,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AiEntryCard extends StatelessWidget {
  const _AiEntryCard({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: onTap,
        child: Ink(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            gradient: const LinearGradient(
              colors: [Color(0xFFE8EEFF), Color(0xFFE2F6FF)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            border: Border.all(color: const Color(0xFFBFD0F4)),
          ),
          child: Row(
            children: [
              Container(
                width: 58,
                height: 58,
                decoration: const BoxDecoration(
                  color: Color(0xFF2C7BEA),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.auto_awesome_rounded,
                  color: Colors.white,
                  size: 30,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Pantalla IA',
                      style: TextStyle(
                        fontSize: 17,
                        color: Color(0xFF2C7BEA),
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Crea actividades personalizadas con IA.',
                      style: TextStyle(
                        fontSize: 20,
                        color: Color(0xFF1A2A48),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.chevron_right_rounded,
                size: 34,
                color: Color(0xFF8FA3C8),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProgressCard extends StatelessWidget {
  const _ProgressCard({
    required this.streak,
    required this.message,
    required this.onTap,
  });

  final int streak;
  final String message;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: onTap,
        child: Ink(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            color: const Color(0xFFDDE9F9),
            border: Border.all(color: const Color(0xFFB3CCF4)),
          ),
          child: Row(
            children: [
              Container(
                width: 58,
                height: 58,
                decoration: const BoxDecoration(
                  color: Color(0xFF2C7BEA),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.emoji_events_rounded,
                  color: Colors.white,
                  size: 28,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'TU PROGRESO · RACHA: $streak',
                      style: const TextStyle(
                        fontSize: 14,
                        color: Color(0xFF2C7BEA),
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      message,
                      style: const TextStyle(
                        fontSize: 22,
                        color: Color(0xFF1A2A48),
                        fontWeight: FontWeight.w700,
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
}

class _SavedResourceCard extends StatelessWidget {
  const _SavedResourceCard({
    required this.resource,
    required this.onToggleSaved,
    required this.onPlay,
  });

  final AiResource resource;
  final VoidCallback onToggleSaved;
  final VoidCallback? onPlay;

  String _gameLabel(ActivityType type) {
    return switch (type) {
      ActivityType.imagenPalabra => 'Imagen y palabra',
      ActivityType.escribirPalabra => 'Escribir palabra',
      ActivityType.palabraPalabra => 'Palabra con palabra',
      ActivityType.imagenFrase => 'Imagen y frase',
      ActivityType.letraObjetivo => 'Letras y vocales',
      ActivityType.cambioExacto => 'Tienda de chuches',
      ActivityType.ruletaLetras => 'Ruleta de letras',
      ActivityType.discriminacion => 'Discriminación',
      ActivityType.discriminacionInversa => 'Discriminación inversa',
    };
  }

  @override
  Widget build(BuildContext context) {
    final type = ActivityTypeX.fromKey(resource.requestedActivityTypeKey);
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFD8E0EE)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            resource.title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontWeight: FontWeight.w900,
              color: Color(0xFF102041),
              fontSize: 18,
            ),
          ),
          const SizedBox(height: 4),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _MiniBadge(
                label: _gameLabel(type),
                icon: Icons.sports_esports_rounded,
              ),
              _MiniBadge(
                label: resource.categoryLabel,
                icon: Icons.category_rounded,
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: FilledButton.icon(
                  onPressed: onPlay,
                  icon: const Icon(Icons.play_arrow_rounded),
                  label: const Text('Jugar'),
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF2C7BEA),
                    foregroundColor: Colors.white,
                    minimumSize: const Size.fromHeight(40),
                    textStyle: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 14,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              OutlinedButton.icon(
                onPressed: onToggleSaved,
                icon: const Icon(Icons.bookmark_remove_rounded, size: 18),
                label: const Text('Quitar'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF2C7BEA),
                  side: const BorderSide(color: Color(0xFF2C7BEA)),
                  minimumSize: const Size(94, 40),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
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

class _MiniBadge extends StatelessWidget {
  const _MiniBadge({required this.label, required this.icon});

  final String label;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5FC),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: const Color(0xFF406196)),
          const SizedBox(width: 4),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: Color(0xFF406196),
            ),
          ),
        ],
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.title,
    required this.value,
    required this.icon,
  });

  final String title;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFD6DFEE)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: const Color(0xFF2C7BEA)),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w900,
              color: Color(0xFF101A39),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            title,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: Color(0xFF6A7898),
            ),
          ),
        ],
      ),
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
