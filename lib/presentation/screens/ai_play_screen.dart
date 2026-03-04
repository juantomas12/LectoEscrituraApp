import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/providers/app_providers.dart';
import '../../domain/models/activity_type.dart';
import '../../domain/models/ai_resource.dart';
import '../../domain/models/category.dart';
import '../../domain/models/difficulty.dart';
import '../utils/category_visuals.dart';
import '../viewmodels/ai_resource_studio_view_model.dart';
import '../viewmodels/settings_view_model.dart';
import 'ai_resource_studio_screen.dart';
import 'generated_session_game_screen.dart';
import 'settings_screen.dart';

class AiPlayScreen extends ConsumerStatefulWidget {
  const AiPlayScreen({super.key});

  @override
  ConsumerState<AiPlayScreen> createState() => _AiPlayScreenState();
}

class _AiPlayScreenState extends ConsumerState<AiPlayScreen> {
  final TextEditingController _promptController = TextEditingController();

  ActivityType _selectedGame = ActivityType.imagenPalabra;
  AppCategory _selectedCategory = AppCategory.cosasDeCasa;
  String _ageRange = 'INFANTIL (7-12)';
  String _duration = '10-15 MIN';
  String _mode = 'MINI-JUEGO GUIADO';
  bool _onlyFavorites = false;

  static const _ageRanges = <String>['INFANTIL (7-12)', 'ADOLESCENTE (13-16)'];
  static const _durations = <String>['10-15 MIN', '15-20 MIN', '20-30 MIN'];
  static const _modes = <String>[
    'SITUACIÓN DE APRENDIZAJE',
    'ACTIVIDAD DE PREGUNTAS',
    'MINI-JUEGO GUIADO',
  ];

  @override
  void dispose() {
    _promptController.dispose();
    super.dispose();
  }

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

  List<String> _allowedWords() {
    final allItems = ref.read(datasetRepositoryProvider).getAllItems();
    final words = <String>{};
    for (final item in allItems) {
      final mainWord = (item.word ?? '').trim();
      if (mainWord.isNotEmpty) {
        words.add(mainWord.toUpperCase());
      }
      for (final word in item.words) {
        final clean = word.trim();
        if (clean.isNotEmpty) {
          words.add(clean.toUpperCase());
        }
      }
    }
    final list = words.toList()..sort();
    return list;
  }

  Future<void> _generateResource() async {
    final prompt = _promptController.text.trim();
    if (prompt.isEmpty) {
      final messenger = ScaffoldMessenger.of(context);
      messenger.hideCurrentSnackBar();
      messenger.showSnackBar(
        const SnackBar(
          content: Text('Escribe una instrucción para generar la sesión IA.'),
        ),
      );
      return;
    }

    final settings = ref.read(settingsViewModelProvider);
    final vm = ref.read(aiResourceStudioViewModelProvider.notifier);

    final generated = await vm.generateAndSave(
      instruction: prompt,
      ageRange: _ageRange,
      duration: _duration,
      mode: _mode,
      categoryLabel: _selectedCategory.label,
      difficultyLabel: settings.defaultDifficulty.label,
      requestedGameType: _selectedGame,
      apiKey: settings.openAiApiKey.trim().isEmpty
          ? null
          : settings.openAiApiKey,
      model: settings.openAiModel,
      allowedWords: _allowedWords(),
    );

    if (!mounted) {
      return;
    }

    final messenger = ScaffoldMessenger.of(context);
    messenger.hideCurrentSnackBar();

    if (generated != null) {
      messenger.showSnackBar(
        SnackBar(content: Text('Recurso IA generado: ${generated.title}')),
      );
      return;
    }

    final state = ref.read(aiResourceStudioViewModelProvider);
    if (state.errorMessage != null && state.errorMessage!.isNotEmpty) {
      messenger.showSnackBar(SnackBar(content: Text(state.errorMessage!)));
    }
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

  void _openClassicStudio() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => const AiResourceStudioScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(aiResourceStudioViewModelProvider);

    final resources = state.resources.toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    final visibleResources = _onlyFavorites
        ? resources.where((resource) => resource.isFavorite).toList()
        : resources;

    final progressValue = state.isGenerating
        ? 0.75
        : _promptController.text.trim().isEmpty
        ? 0.20
        : visibleResources.isNotEmpty
        ? 1.0
        : 0.48;

    return Scaffold(
      backgroundColor: const Color(0xFFEDEFF3),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 14, 18, 10),
              child: Row(
                children: [
                  _RoundIcon(
                    icon: Icons.arrow_back_rounded,
                    onTap: () => Navigator.of(context).maybePop(),
                  ),
                  const Expanded(
                    child: Text(
                      'Pantalla IA',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 30,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF111D3A),
                      ),
                    ),
                  ),
                  _RoundIcon(
                    icon: Icons.settings_rounded,
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => const SettingsScreen(),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                children: [
                  Row(
                    children: [
                      Text(
                        'Generación IA personalizada',
                        style: TextStyle(
                          fontSize: 18,
                          color: const Color(
                            0xFF2C7BEA,
                          ).withValues(alpha: 0.92),
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        '${visibleResources.length} recursos',
                        style: const TextStyle(
                          fontSize: 14,
                          color: Color(0xFF7C8AA9),
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(999),
                    child: LinearProgressIndicator(
                      value: progressValue,
                      minHeight: 10,
                      backgroundColor: const Color(0xFFD5DDEC),
                      valueColor: const AlwaysStoppedAnimation(
                        Color(0xFF2C7BEA),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: const Color(0xFFD6DFEE)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 54,
                              height: 54,
                              decoration: BoxDecoration(
                                color: const Color(0xFFDDEBFF),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: const Icon(
                                Icons.auto_awesome_rounded,
                                size: 30,
                                color: Color(0xFF2C7BEA),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Diseña una sesión con IA',
                                    style: TextStyle(
                                      fontSize: 24,
                                      fontWeight: FontWeight.w900,
                                      color: Color(0xFF111D3A),
                                    ),
                                  ),
                                  Text(
                                    '${_gameLabel(_selectedGame)} · ${_selectedCategory.label}',
                                    style: const TextStyle(
                                      fontSize: 16,
                                      color: Color(0xFF657A9D),
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'Escribe el caso real o el objetivo de hoy',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF53658A),
                          ),
                        ),
                        const SizedBox(height: 6),
                        TextField(
                          controller: _promptController,
                          minLines: 3,
                          maxLines: 5,
                          onChanged: (_) {
                            setState(() {});
                          },
                          style: const TextStyle(
                            fontSize: 16,
                            color: Color(0xFF111D3A),
                          ),
                          decoration: InputDecoration(
                            hintText:
                                'Ejemplo: quiero trabajar la /R/ con vocabulario de casa y preguntas cortas.',
                            hintStyle: const TextStyle(
                              color: Color(0xFF95A3BD),
                              fontSize: 14,
                            ),
                            filled: true,
                            fillColor: const Color(0xFFF6F8FC),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: const BorderSide(
                                color: Color(0xFFD5DDEE),
                              ),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: const BorderSide(
                                color: Color(0xFFD5DDEE),
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: const BorderSide(
                                color: Color(0xFF2C7BEA),
                                width: 1.4,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            _SelectChip<ActivityType>(
                              label: _gameLabel(_selectedGame),
                              icon: Icons.sports_esports_rounded,
                              items: ActivityType.values,
                              selected: _selectedGame,
                              itemLabel: _gameLabel,
                              onSelected: (value) {
                                setState(() => _selectedGame = value);
                              },
                            ),
                            _SelectChip<AppCategory>(
                              label: _selectedCategory.label,
                              icon: _selectedCategory.icon,
                              items: AppCategoryLists.reales,
                              selected: _selectedCategory,
                              itemLabel: (category) => category.label,
                              onSelected: (value) {
                                setState(() => _selectedCategory = value);
                              },
                            ),
                            _SelectChip<String>(
                              label: _ageRange,
                              icon: Icons.cake_rounded,
                              items: _ageRanges,
                              selected: _ageRange,
                              itemLabel: (value) => value,
                              onSelected: (value) {
                                setState(() => _ageRange = value);
                              },
                            ),
                            _SelectChip<String>(
                              label: _duration,
                              icon: Icons.timer_rounded,
                              items: _durations,
                              selected: _duration,
                              itemLabel: (value) => value,
                              onSelected: (value) {
                                setState(() => _duration = value);
                              },
                            ),
                            _SelectChip<String>(
                              label: _mode,
                              icon: Icons.auto_stories_rounded,
                              items: _modes,
                              selected: _mode,
                              itemLabel: (value) => value,
                              onSelected: (value) {
                                setState(() => _mode = value);
                              },
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: FilledButton.icon(
                                onPressed: state.isGenerating
                                    ? null
                                    : _generateResource,
                                icon: state.isGenerating
                                    ? const SizedBox(
                                        width: 18,
                                        height: 18,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: Colors.white,
                                        ),
                                      )
                                    : const Icon(Icons.auto_awesome_rounded),
                                label: Text(
                                  state.isGenerating
                                      ? 'Generando...'
                                      : 'Generar sesión IA',
                                ),
                                style: FilledButton.styleFrom(
                                  backgroundColor: const Color(0xFF2C7BEA),
                                  foregroundColor: Colors.white,
                                  minimumSize: const Size.fromHeight(52),
                                  textStyle: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w800,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            OutlinedButton(
                              onPressed: _openClassicStudio,
                              style: OutlinedButton.styleFrom(
                                minimumSize: const Size(54, 52),
                                side: const BorderSide(
                                  color: Color(0xFF2C7BEA),
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                              ),
                              child: const Icon(
                                Icons.view_compact_alt_rounded,
                                color: Color(0xFF2C7BEA),
                              ),
                            ),
                          ],
                        ),
                        if (state.errorMessage != null &&
                            state.errorMessage!.isNotEmpty) ...[
                          const SizedBox(height: 10),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFFEEED),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: const Color(0xFFFFC3BF),
                              ),
                            ),
                            child: Text(
                              state.errorMessage!,
                              style: const TextStyle(
                                color: Color(0xFF8D2F24),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      const Text(
                        'Recursos recientes',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFF111D3A),
                        ),
                      ),
                      const Spacer(),
                      TextButton.icon(
                        onPressed: () {
                          setState(() => _onlyFavorites = !_onlyFavorites);
                        },
                        icon: Icon(
                          _onlyFavorites
                              ? Icons.star_rounded
                              : Icons.star_border_rounded,
                          color: const Color(0xFF2C7BEA),
                        ),
                        label: Text(
                          _onlyFavorites ? 'Favoritos' : 'Todos',
                          style: const TextStyle(color: Color(0xFF2C7BEA)),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  if (visibleResources.isEmpty)
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: const Color(0xFFD6DFEE)),
                      ),
                      child: const Text(
                        'Aún no hay recursos para este filtro. Genera uno nuevo para empezar.',
                        style: TextStyle(
                          fontSize: 16,
                          color: Color(0xFF5D6F92),
                        ),
                      ),
                    )
                  else
                    ...visibleResources.take(8).map((resource) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: _AiResourceCard(
                          resource: resource,
                          gameLabel: _gameLabel,
                          onToggleFavorite: () {
                            ref
                                .read(
                                  aiResourceStudioViewModelProvider.notifier,
                                )
                                .toggleFavorite(resource.id);
                          },
                          onDelete: () {
                            ref
                                .read(
                                  aiResourceStudioViewModelProvider.notifier,
                                )
                                .delete(resource.id);
                          },
                          onPlay: resource.playableQuestions.isEmpty
                              ? null
                              : () => _openGeneratedGame(resource),
                        ),
                      );
                    }),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RoundIcon extends StatelessWidget {
  const _RoundIcon({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(999),
        onTap: onTap,
        child: Ink(
          width: 48,
          height: 48,
          decoration: const BoxDecoration(
            color: Color(0xFFDCE5F6),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: const Color(0xFF1A2745)),
        ),
      ),
    );
  }
}

class _SelectChip<T> extends StatelessWidget {
  const _SelectChip({
    required this.label,
    required this.icon,
    required this.items,
    required this.selected,
    required this.itemLabel,
    required this.onSelected,
  });

  final String label;
  final IconData icon;
  final List<T> items;
  final T selected;
  final String Function(T value) itemLabel;
  final ValueChanged<T> onSelected;

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<T>(
      onSelected: onSelected,
      itemBuilder: (context) {
        return items.map((item) {
          final isSelected = item == selected;
          return PopupMenuItem<T>(
            value: item,
            child: Row(
              children: [
                Expanded(child: Text(itemLabel(item))),
                if (isSelected)
                  const Icon(
                    Icons.check_circle_rounded,
                    color: Color(0xFF2C7BEA),
                  ),
              ],
            ),
          );
        }).toList();
      },
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: const Color(0xFFF4F7FD),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: const Color(0xFFD2DCF0)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: const Color(0xFF2C7BEA)),
            const SizedBox(width: 6),
            Text(
              label,
              style: const TextStyle(
                fontSize: 13,
                color: Color(0xFF35507B),
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(width: 2),
            const Icon(
              Icons.keyboard_arrow_down_rounded,
              size: 16,
              color: Color(0xFF6D7FA4),
            ),
          ],
        ),
      ),
    );
  }
}

class _AiResourceCard extends StatelessWidget {
  const _AiResourceCard({
    required this.resource,
    required this.gameLabel,
    required this.onToggleFavorite,
    required this.onDelete,
    required this.onPlay,
  });

  final AiResource resource;
  final String Function(ActivityType type) gameLabel;
  final VoidCallback onToggleFavorite;
  final VoidCallback onDelete;
  final VoidCallback? onPlay;

  @override
  Widget build(BuildContext context) {
    final type = ActivityTypeX.fromKey(resource.requestedActivityTypeKey);
    final createdAt = resource.createdAt;

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
          Row(
            children: [
              Expanded(
                child: Text(
                  resource.title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF111D3A),
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              IconButton(
                tooltip: 'Favorito',
                onPressed: onToggleFavorite,
                icon: Icon(
                  resource.isFavorite
                      ? Icons.star_rounded
                      : Icons.star_border_rounded,
                  color: const Color(0xFF2C7BEA),
                ),
              ),
              IconButton(
                tooltip: 'Eliminar',
                onPressed: onDelete,
                icon: const Icon(
                  Icons.delete_outline_rounded,
                  color: Color(0xFF9B4D4D),
                ),
              ),
            ],
          ),
          if (resource.objective.trim().isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(
                resource.objective,
                style: const TextStyle(
                  color: Color(0xFF5A6D93),
                  fontSize: 14,
                  height: 1.3,
                ),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              _InfoChip(label: gameLabel(type), icon: Icons.games_rounded),
              _InfoChip(
                label: resource.categoryLabel,
                icon: Icons.category_rounded,
              ),
              _InfoChip(
                label:
                    '${createdAt.day.toString().padLeft(2, '0')}/${createdAt.month.toString().padLeft(2, '0')}/${createdAt.year}',
                icon: Icons.event_rounded,
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
                    minimumSize: const Size.fromHeight(42),
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
            ],
          ),
        ],
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  const _InfoChip({required this.label, required this.icon});

  final String label;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: const Color(0xFFF2F6FD),
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
