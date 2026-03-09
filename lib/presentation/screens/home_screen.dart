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

  _QuickTrack _trackFor(ActivityType type) {
    for (final track in _HomeScreenState._quickTracks) {
      if (track.gameType == type) {
        return track;
      }
    }
    return _HomeScreenState._quickTracks.first;
  }

  @override
  Widget build(BuildContext context) {
    final rewards = progressVm.rewardsSummary();
    final width = MediaQuery.sizeOf(context).width;
    final isTablet = width >= 900;
    final horizontalPadding = isTablet ? 26.0 : 16.0;
    final contentWidth = isTablet ? 1300.0 : 840.0;
    final playerName = profileName.split(' ').first;
    final playerLabel = playerName.trim().isEmpty
        ? 'Aventurero'
        : _titleCase(playerName);
    final results = progressVm.getAllResults();
    final totalCorrect = results.fold<int>(
      0,
      (sum, item) => sum + item.correct,
    );
    final totalIncorrect = results.fold<int>(
      0,
      (sum, item) => sum + item.incorrect,
    );
    final totalAttempts = totalCorrect + totalIncorrect;
    final progressRatio = totalAttempts == 0
        ? 0.0
        : (totalCorrect / totalAttempts).clamp(0.0, 1.0);
    final progressPercent = (progressRatio * 100).round();
    final progressFilledFlex = ((progressRatio * 1000).round())
        .clamp(1, 1000)
        .toInt();
    final progressEmptyFlex = (1000 - progressFilledFlex)
        .clamp(1, 1000)
        .toInt();

    final letterTrack = _trackFor(ActivityType.letraObjetivo);
    final syllableTrack = _trackFor(ActivityType.palabraPalabra);
    final wordTrack = _trackFor(ActivityType.imagenPalabra);
    final writingTrack = _trackFor(ActivityType.escribirPalabra);
    final phraseTrack = _trackFor(ActivityType.imagenFrase);

    return ListView(
      padding: EdgeInsets.fromLTRB(
        horizontalPadding,
        isTablet ? 18 : 12,
        horizontalPadding,
        isTablet ? 18 : 12,
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
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: const Color(0xFFE9E4DE)),
                  ),
                  padding: EdgeInsets.fromLTRB(
                    isTablet ? 28 : 16,
                    16,
                    isTablet ? 20 : 16,
                    16,
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: isTablet ? 70 : 58,
                        height: isTablet ? 70 : 58,
                        decoration: BoxDecoration(
                          color: const Color(0xFFEF5B10),
                          borderRadius: BorderRadius.circular(18),
                        ),
                        child: Icon(
                          Icons.school_rounded,
                          color: Colors.white,
                          size: isTablet ? 36 : 30,
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
                                fontSize: isTablet ? 24 : 22,
                                fontWeight: FontWeight.w900,
                                color: Color(0xFF101A35),
                                height: 0.95,
                              ),
                            ),
                            SizedBox(height: 2),
                            Text(
                              'ISLAS DE APRENDIZAJE',
                              style: TextStyle(
                                fontSize: isTablet ? 10 : 9,
                                letterSpacing: 2.2,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFFEF5B10),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        width: isTablet ? 56 : 48,
                        height: isTablet ? 56 : 48,
                        decoration: const BoxDecoration(
                          color: Color(0xFFF5E7DF),
                          shape: BoxShape.circle,
                        ),
                        child: IconButton(
                          onPressed: onMenuTap,
                          icon: Icon(
                            Icons.settings_rounded,
                            color: const Color(0xFFEF5B10),
                            size: isTablet ? 30 : 26,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      InkWell(
                        borderRadius: BorderRadius.circular(999),
                        onTap: onProfileTap,
                        child: Container(
                          width: isTablet ? 56 : 48,
                          height: isTablet ? 56 : 48,
                          decoration: BoxDecoration(
                            color: const Color(0xFFEF5B10),
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: const Color(
                                  0xFFEF5B10,
                                ).withValues(alpha: 0.28),
                                blurRadius: 16,
                                offset: const Offset(0, 7),
                              ),
                            ],
                          ),
                          child: Icon(
                            Icons.person_rounded,
                            color: Colors.white,
                            size: isTablet ? 30 : 26,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Container(
                        width: isTablet ? 56 : 48,
                        height: isTablet ? 56 : 48,
                        decoration: BoxDecoration(
                          color: const Color(0xFF8CCCB3),
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 3),
                        ),
                        alignment: Alignment.center,
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
                    ],
                  ),
                ),
                const SizedBox(height: 28),
                Center(
                  child: Column(
                    children: [
                      Text(
                        '¡Hola, $playerLabel!',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: isTablet ? 24 : 28,
                          fontWeight: FontWeight.w900,
                          color: const Color(0xFF101A35),
                          height: 1.0,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Elige una isla para empezar a jugar hoy',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: isTablet ? 12 : 16,
                          color: const Color(0xFF344B70),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 30),
                GridView.count(
                  crossAxisCount: isTablet ? 3 : 2,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  childAspectRatio: isTablet ? 1.0 : 0.82,
                  mainAxisSpacing: isTablet ? 14 : 10,
                  crossAxisSpacing: isTablet ? 22 : 12,
                  children: [
                    _HomeIslandTile(
                      title: letterTrack.title,
                      symbol: 'Aa',
                      onTap: () => onTrackTap(letterTrack),
                      fillColor: const Color(0xFFFFE8CC),
                      borderColor: const Color(0xFFF6F1EB),
                      labelBorderColor: const Color(0xFFFFD4A1),
                      accentColor: const Color(0xFFFF7A00),
                    ),
                    _HomeIslandTile(
                      title: syllableTrack.title,
                      icon: Icons.music_note_rounded,
                      onTap: () => onTrackTap(syllableTrack),
                      fillColor: const Color(0xFFDDEBFF),
                      borderColor: const Color(0xFFF3F6FA),
                      labelBorderColor: const Color(0xFFAECFF9),
                      accentColor: const Color(0xFF3B82F6),
                    ),
                    _HomeIslandTile(
                      title: wordTrack.title,
                      icon: Icons.auto_stories_rounded,
                      onTap: () => onTrackTap(wordTrack),
                      fillColor: const Color(0xFFD7F4E3),
                      borderColor: const Color(0xFFF2F8F5),
                      labelBorderColor: const Color(0xFF9DE4BF),
                      accentColor: const Color(0xFF1DBE5B),
                    ),
                    _HomeIslandTile(
                      title: writingTrack.title,
                      icon: Icons.draw_rounded,
                      onTap: () => onTrackTap(writingTrack),
                      fillColor: const Color(0xFFEEDFFE),
                      borderColor: const Color(0xFFF7F3FB),
                      labelBorderColor: const Color(0xFFD2B8F7),
                      accentColor: const Color(0xFF9B5DE5),
                    ),
                    _HomeIslandTile(
                      title: phraseTrack.title,
                      icon: Icons.chat_bubble_rounded,
                      onTap: () => onTrackTap(phraseTrack),
                      fillColor: const Color(0xFFF8DCEE),
                      borderColor: const Color(0xFFFCF4FA),
                      labelBorderColor: const Color(0xFFF0BADB),
                      accentColor: const Color(0xFFE64A9B),
                    ),
                    _HomeIslandTile(
                      title: 'IA Automático',
                      icon: Icons.psychology_alt_rounded,
                      onTap: onOpenAi,
                      fillColor: const Color(0xFFFFE2D2),
                      borderColor: const Color(0xFFEF5B10),
                      labelBorderColor: const Color(0xFFEF5B10),
                      accentColor: const Color(0xFFEF5B10),
                      highlighted: true,
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFFFCFCFD),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: const Color(0xFFE9E4DE)),
                  ),
                  padding: const EdgeInsets.fromLTRB(18, 16, 18, 14),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          const Icon(
                            Icons.star_rounded,
                            color: Color(0xFFEF5B10),
                            size: 28,
                          ),
                          const SizedBox(width: 8),
                          const Expanded(
                            child: Text(
                              'TU PROGRESO DE HOY',
                              style: TextStyle(
                                color: Color(0xFFEF5B10),
                                fontSize: 18,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 0.4,
                              ),
                            ),
                          ),
                          Text(
                            '$progressPercent% Completado',
                            style: const TextStyle(
                              color: Color(0xFF131B34),
                              fontSize: 14,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Container(
                        height: 30,
                        padding: const EdgeInsets.all(3),
                        decoration: BoxDecoration(
                          color: const Color(0xFFCED5E2),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              flex: progressFilledFlex,
                              child: Container(
                                decoration: BoxDecoration(
                                  color: const Color(0xFFEF5B10),
                                  borderRadius: BorderRadius.circular(999),
                                ),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                ),
                                alignment: Alignment.centerRight,
                                child: Text(
                                  rewards.activeToday ? '¡CASI LLEGAS!' : '',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w900,
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                            ),
                            Expanded(
                              flex: progressEmptyFlex,
                              child: const SizedBox.shrink(),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          const Expanded(
                            child: Text(
                              'INICIO',
                              style: TextStyle(
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF5E7094),
                                letterSpacing: 2.0,
                              ),
                            ),
                          ),
                          Expanded(
                            child: Text(
                              rewards.currentStreak >= 5
                                  ? 'RACHA EXCELENTE'
                                  : 'SIGUIENTE NIVEL: EXPLORADOR GALÁCTICO',
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF5E7094),
                                letterSpacing: 1.8,
                              ),
                            ),
                          ),
                          GestureDetector(
                            onTap: onOpenProgress,
                            child: const Text(
                              'META DIARIA',
                              style: TextStyle(
                                fontWeight: FontWeight.w900,
                                color: Color(0xFF5E7094),
                                letterSpacing: 2.0,
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

class _HomeIslandTile extends StatelessWidget {
  const _HomeIslandTile({
    required this.title,
    required this.onTap,
    required this.fillColor,
    required this.borderColor,
    required this.labelBorderColor,
    required this.accentColor,
    this.icon,
    this.symbol,
    this.highlighted = false,
  });

  final String title;
  final VoidCallback onTap;
  final Color fillColor;
  final Color borderColor;
  final Color labelBorderColor;
  final Color accentColor;
  final IconData? icon;
  final String? symbol;
  final bool highlighted;

  @override
  Widget build(BuildContext context) {
    final isTablet = MediaQuery.sizeOf(context).width >= 900;
    final circleSize = isTablet ? 116.0 : 140.0;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(30),
        onTap: onTap,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: circleSize,
              height: circleSize,
              decoration: BoxDecoration(
                color: fillColor,
                shape: BoxShape.circle,
                border: Border.all(
                  color: highlighted ? borderColor : const Color(0xFFF0F0F0),
                  width: highlighted ? 8 : 7,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.09),
                    blurRadius: 16,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Center(
                child: symbol != null
                    ? Text(
                        symbol!,
                        style: TextStyle(
                          fontSize: isTablet ? 48 : 50,
                          fontWeight: FontWeight.w900,
                          color: accentColor,
                        ),
                      )
                    : Icon(icon, color: accentColor, size: isTablet ? 44 : 46),
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: EdgeInsets.symmetric(
                horizontal: isTablet ? 18 : 16,
                vertical: isTablet ? 8 : 8,
              ),
              decoration: BoxDecoration(
                color: highlighted ? accentColor : Colors.white,
                borderRadius: BorderRadius.circular(999),
                border: Border.all(
                  color: highlighted ? accentColor : labelBorderColor,
                  width: 3,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.08),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Text(
                title,
                style: TextStyle(
                  fontSize: isTablet ? 18 : 22,
                  fontWeight: FontWeight.w900,
                  color: highlighted ? Colors.white : const Color(0xFF141C34),
                ),
              ),
            ),
          ],
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
