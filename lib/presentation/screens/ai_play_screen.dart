import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/providers/app_providers.dart';
import '../../domain/models/activity_type.dart';
import '../../domain/models/ai_resource.dart';
import '../../domain/models/category.dart';
import '../../domain/models/difficulty.dart';
import '../viewmodels/ai_resource_studio_view_model.dart';
import '../viewmodels/settings_view_model.dart';
import 'generated_session_game_screen.dart';
import 'settings_screen.dart';

class AiPlayScreen extends ConsumerStatefulWidget {
  const AiPlayScreen({super.key, this.embedded = false, this.onOpenSettings});

  final bool embedded;
  final VoidCallback? onOpenSettings;

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
      ActivityType.sonidos => 'Juego de sonidos',
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
        SnackBar(
          content: Text('Recurso IA generado: ${generated.title}'),
          action: generated.isFavorite
              ? null
              : SnackBarAction(
                  label: 'Guardar en inicio',
                  onPressed: () {
                    vm.toggleFavorite(generated.id);
                  },
                ),
        ),
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

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(aiResourceStudioViewModelProvider);
    final width = MediaQuery.sizeOf(context).width;
    final isTablet = width >= 900;

    final resources = state.resources.toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    final visibleResources = _onlyFavorites
        ? resources.where((resource) => resource.isFavorite).toList()
        : resources;
    final content = Column(
      children: [
        Expanded(
          child: ListView(
            padding: EdgeInsets.fromLTRB(
              isTablet ? 28 : 20,
              14,
              isTablet ? 28 : 20,
              26,
            ),
            children: [
              Center(
                child: ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: isTablet ? 1180 : 900),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          if (!widget.embedded)
                            _RoundIcon(
                              icon: Icons.arrow_back_rounded,
                              onTap: () => Navigator.of(context).maybePop(),
                            ),
                          if (!widget.embedded) const SizedBox(width: 10),
                          const Icon(
                            Icons.auto_awesome_rounded,
                            color: Color(0xFF2C7BEA),
                            size: 30,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Generador de Sesiones IA',
                              style: TextStyle(
                                fontSize: isTablet ? 52 : 34,
                                fontWeight: FontWeight.w900,
                                color: const Color(0xFF111D3A),
                                height: 1.0,
                              ),
                            ),
                          ),
                          _RoundIcon(
                            icon: Icons.settings_rounded,
                            onTap: () {
                              if (widget.onOpenSettings != null) {
                                widget.onOpenSettings!();
                                return;
                              }
                              Navigator.of(context).push(
                                MaterialPageRoute<void>(
                                  builder: (_) => const SettingsScreen(),
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'Crea actividades personalizadas en segundos. Define tus objetivos y nuestra IA se encargará del resto.',
                        style: TextStyle(
                          fontSize: 18,
                          color: Color(0xFF5F6F8F),
                          fontWeight: FontWeight.w500,
                          height: 1.35,
                        ),
                      ),
                      const SizedBox(height: 18),
                      Container(
                        padding: EdgeInsets.all(isTablet ? 24 : 16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(28),
                          border: Border.all(color: const Color(0xFFDCE4F2)),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(
                                0xFF113066,
                              ).withValues(alpha: 0.04),
                              blurRadius: 20,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (isTablet)
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    flex: 11,
                                    child: _PromptField(
                                      controller: _promptController,
                                      onChanged: () => setState(() {}),
                                    ),
                                  ),
                                  const SizedBox(width: 18),
                                  Expanded(
                                    flex: 10,
                                    child: Column(
                                      children: [
                                        Row(
                                          children: [
                                            Expanded(
                                              child: _PickerField<ActivityType>(
                                                label: 'Categoría',
                                                value: _selectedGame,
                                                items: ActivityType.values,
                                                itemLabel: _gameLabel,
                                                onChanged: (value) {
                                                  if (value == null) return;
                                                  setState(
                                                    () => _selectedGame = value,
                                                  );
                                                },
                                              ),
                                            ),
                                            const SizedBox(width: 12),
                                            Expanded(
                                              child: _PickerField<String>(
                                                label: 'Grupo de edad',
                                                value: _ageRange,
                                                items: _ageRanges,
                                                itemLabel: (value) => value,
                                                onChanged: (value) {
                                                  if (value == null) return;
                                                  setState(
                                                    () => _ageRange = value,
                                                  );
                                                },
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 12),
                                        Row(
                                          children: [
                                            Expanded(
                                              child: _PickerField<String>(
                                                label: 'Duración',
                                                value: _duration,
                                                items: _durations,
                                                itemLabel: (value) => value,
                                                onChanged: (value) {
                                                  if (value == null) return;
                                                  setState(
                                                    () => _duration = value,
                                                  );
                                                },
                                              ),
                                            ),
                                            const SizedBox(width: 12),
                                            Expanded(
                                              child: _PickerField<String>(
                                                label: 'Modo de juego',
                                                value: _mode,
                                                items: _modes,
                                                itemLabel: (value) => value,
                                                onChanged: (value) {
                                                  if (value == null) return;
                                                  setState(() => _mode = value);
                                                },
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 12),
                                        _PickerField<AppCategory>(
                                          label: 'Dominio',
                                          value: _selectedCategory,
                                          items: AppCategoryLists.reales,
                                          itemLabel: (category) =>
                                              category.label,
                                          onChanged: (value) {
                                            if (value == null) return;
                                            setState(
                                              () => _selectedCategory = value,
                                            );
                                          },
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              )
                            else ...[
                              _PromptField(
                                controller: _promptController,
                                onChanged: () => setState(() {}),
                              ),
                              const SizedBox(height: 12),
                              _PickerField<ActivityType>(
                                label: 'Categoría',
                                value: _selectedGame,
                                items: ActivityType.values,
                                itemLabel: _gameLabel,
                                onChanged: (value) {
                                  if (value == null) return;
                                  setState(() => _selectedGame = value);
                                },
                              ),
                              const SizedBox(height: 10),
                              _PickerField<AppCategory>(
                                label: 'Dominio',
                                value: _selectedCategory,
                                items: AppCategoryLists.reales,
                                itemLabel: (category) => category.label,
                                onChanged: (value) {
                                  if (value == null) return;
                                  setState(() => _selectedCategory = value);
                                },
                              ),
                              const SizedBox(height: 10),
                              _PickerField<String>(
                                label: 'Grupo de edad',
                                value: _ageRange,
                                items: _ageRanges,
                                itemLabel: (value) => value,
                                onChanged: (value) {
                                  if (value == null) return;
                                  setState(() => _ageRange = value);
                                },
                              ),
                              const SizedBox(height: 10),
                              _PickerField<String>(
                                label: 'Duración',
                                value: _duration,
                                items: _durations,
                                itemLabel: (value) => value,
                                onChanged: (value) {
                                  if (value == null) return;
                                  setState(() => _duration = value);
                                },
                              ),
                              const SizedBox(height: 10),
                              _PickerField<String>(
                                label: 'Modo de juego',
                                value: _mode,
                                items: _modes,
                                itemLabel: (value) => value,
                                onChanged: (value) {
                                  if (value == null) return;
                                  setState(() => _mode = value);
                                },
                              ),
                            ],
                            const SizedBox(height: 18),
                            Center(
                              child: SizedBox(
                                width: isTablet ? 320 : double.infinity,
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
                                    backgroundColor: const Color(0xFF2C8CEE),
                                    foregroundColor: Colors.white,
                                    minimumSize: const Size.fromHeight(58),
                                    textStyle: const TextStyle(
                                      fontSize: 19,
                                      fontWeight: FontWeight.w800,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(999),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            if (state.errorMessage != null &&
                                state.errorMessage!.isNotEmpty) ...[
                              const SizedBox(height: 12),
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
                      const SizedBox(height: 18),
                      Row(
                        children: [
                          const Text(
                            'Recursos recientes',
                            style: TextStyle(
                              fontSize: 42,
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
                                  ? Icons.bookmark_rounded
                                  : Icons.bookmark_border_rounded,
                              color: const Color(0xFF2C7BEA),
                            ),
                            label: Text(
                              _onlyFavorites ? 'Ver todos' : 'Solo guardados',
                              style: const TextStyle(
                                color: Color(0xFF2C7BEA),
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
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
                      else if (isTablet)
                        GridView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: visibleResources.take(6).length,
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 3,
                                mainAxisSpacing: 10,
                                crossAxisSpacing: 10,
                                mainAxisExtent: 238,
                              ),
                          itemBuilder: (context, index) {
                            final resource = visibleResources[index];
                            return _AiResourceCard(
                              resource: resource,
                              gameLabel: _gameLabel,
                              onToggleSaved: () {
                                ref
                                    .read(
                                      aiResourceStudioViewModelProvider
                                          .notifier,
                                    )
                                    .toggleFavorite(resource.id);
                              },
                              onDelete: () {
                                ref
                                    .read(
                                      aiResourceStudioViewModelProvider
                                          .notifier,
                                    )
                                    .delete(resource.id);
                              },
                              onPlay: resource.playableQuestions.isEmpty
                                  ? null
                                  : () => _openGeneratedGame(resource),
                            );
                          },
                        )
                      else
                        ...visibleResources.take(8).map((resource) {
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: _AiResourceCard(
                              resource: resource,
                              gameLabel: _gameLabel,
                              onToggleSaved: () {
                                ref
                                    .read(
                                      aiResourceStudioViewModelProvider
                                          .notifier,
                                    )
                                    .toggleFavorite(resource.id);
                              },
                              onDelete: () {
                                ref
                                    .read(
                                      aiResourceStudioViewModelProvider
                                          .notifier,
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
              ),
            ],
          ),
        ),
      ],
    );

    if (widget.embedded) {
      return ColoredBox(color: const Color(0xFFEDEFF3), child: content);
    }

    return Scaffold(
      backgroundColor: const Color(0xFFEDEFF3),
      body: SafeArea(child: content),
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

class _PromptField extends StatelessWidget {
  const _PromptField({required this.controller, required this.onChanged});

  final TextEditingController controller;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'OBJETIVO DE LA SESIÓN',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.5,
            color: Color(0xFF53658A),
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          minLines: 4,
          maxLines: 6,
          onChanged: (_) => onChanged(),
          style: const TextStyle(fontSize: 16, color: Color(0xFF111D3A)),
          decoration: InputDecoration(
            hintText:
                'Ej: trabajar la letra R con vocabulario de casa y objetos cotidianos...',
            hintStyle: const TextStyle(color: Color(0xFF95A3BD), fontSize: 15),
            filled: true,
            fillColor: const Color(0xFFF6F8FC),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(22),
              borderSide: const BorderSide(color: Color(0xFFD5DDEE)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(22),
              borderSide: const BorderSide(color: Color(0xFFD5DDEE)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(22),
              borderSide: const BorderSide(
                color: Color(0xFF2C7BEA),
                width: 1.4,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _PickerField<T> extends StatelessWidget {
  const _PickerField({
    required this.label,
    required this.value,
    required this.items,
    required this.itemLabel,
    required this.onChanged,
  });

  final String label;
  final T value;
  final List<T> items;
  final String Function(T value) itemLabel;
  final ValueChanged<T?> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(),
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.5,
            color: Color(0xFF53658A),
          ),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<T>(
          key: ValueKey<String>('picker-$label-$value'),
          initialValue: value,
          onChanged: onChanged,
          items: items.map((item) {
            return DropdownMenuItem<T>(
              value: item,
              child: Text(
                itemLabel(item),
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            );
          }).toList(),
          decoration: InputDecoration(
            isDense: true,
            filled: true,
            fillColor: const Color(0xFFF2F5FA),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 14,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(999),
              borderSide: const BorderSide(color: Color(0xFFD5DDEE)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(999),
              borderSide: const BorderSide(color: Color(0xFFD5DDEE)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(999),
              borderSide: const BorderSide(
                color: Color(0xFF2C7BEA),
                width: 1.4,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _AiResourceCard extends StatelessWidget {
  const _AiResourceCard({
    required this.resource,
    required this.gameLabel,
    required this.onToggleSaved,
    required this.onDelete,
    required this.onPlay,
  });

  final AiResource resource;
  final String Function(ActivityType type) gameLabel;
  final VoidCallback onToggleSaved;
  final VoidCallback onDelete;
  final VoidCallback? onPlay;

  @override
  Widget build(BuildContext context) {
    final type = ActivityTypeX.fromKey(resource.requestedActivityTypeKey);
    final createdAt = resource.createdAt;
    final palette = _ResourcePalette.fromType(type);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: palette.borderColor, width: 1.6),
        boxShadow: [
          BoxShadow(
            color: palette.accent.withValues(alpha: 0.08),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: palette.softBackground,
                  shape: BoxShape.circle,
                ),
                child: Icon(palette.icon, color: palette.accent, size: 24),
              ),
              const SizedBox(width: 10),
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
                tooltip: resource.isFavorite
                    ? 'Quitar de inicio'
                    : 'Guardar en inicio',
                onPressed: onToggleSaved,
                icon: Icon(
                  resource.isFavorite
                      ? Icons.bookmark_rounded
                      : Icons.bookmark_border_rounded,
                  color: palette.accent,
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
              _InfoChip(
                label: gameLabel(type),
                icon: Icons.games_rounded,
                backgroundColor: palette.softBackground,
                foregroundColor: palette.accent,
              ),
              _InfoChip(
                label: resource.categoryLabel,
                icon: Icons.category_rounded,
                backgroundColor: palette.softBackground,
                foregroundColor: palette.accent,
              ),
              _InfoChip(
                label:
                    '${createdAt.day.toString().padLeft(2, '0')}/${createdAt.month.toString().padLeft(2, '0')}/${createdAt.year}',
                icon: Icons.event_rounded,
                backgroundColor: palette.softBackground,
                foregroundColor: palette.accent,
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
                    backgroundColor: palette.playButton,
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
              const SizedBox(width: 8),
              OutlinedButton.icon(
                onPressed: onToggleSaved,
                icon: Icon(
                  resource.isFavorite
                      ? Icons.bookmark_remove_rounded
                      : Icons.bookmark_add_rounded,
                  size: 18,
                ),
                label: Text(resource.isFavorite ? 'Guardado' : 'Guardar'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: palette.accent,
                  side: BorderSide(color: palette.accent),
                  minimumSize: const Size(112, 42),
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

class _InfoChip extends StatelessWidget {
  const _InfoChip({
    required this.label,
    required this.icon,
    this.backgroundColor = const Color(0xFFF2F6FD),
    this.foregroundColor = const Color(0xFF406196),
  });

  final String label;
  final IconData icon;
  final Color backgroundColor;
  final Color foregroundColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: foregroundColor),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: foregroundColor,
            ),
          ),
        ],
      ),
    );
  }
}

class _ResourcePalette {
  const _ResourcePalette({
    required this.accent,
    required this.playButton,
    required this.softBackground,
    required this.borderColor,
    required this.icon,
  });

  final Color accent;
  final Color playButton;
  final Color softBackground;
  final Color borderColor;
  final IconData icon;

  factory _ResourcePalette.fromType(ActivityType type) {
    return switch (type) {
      ActivityType.imagenPalabra => const _ResourcePalette(
        accent: Color(0xFFFF9F43),
        playButton: Color(0xFF2ECC71),
        softBackground: Color(0xFFFFF1E3),
        borderColor: Color(0xFFFFD7B2),
        icon: Icons.abc_rounded,
      ),
      ActivityType.escribirPalabra => const _ResourcePalette(
        accent: Color(0xFF10A5B5),
        playButton: Color(0xFF20B486),
        softBackground: Color(0xFFE4F7FA),
        borderColor: Color(0xFFB9E9F0),
        icon: Icons.edit_note_rounded,
      ),
      ActivityType.palabraPalabra => const _ResourcePalette(
        accent: Color(0xFF2B8CEE),
        playButton: Color(0xFF2ECC71),
        softBackground: Color(0xFFE7F1FF),
        borderColor: Color(0xFFBED7FA),
        icon: Icons.house_rounded,
      ),
      ActivityType.imagenFrase => const _ResourcePalette(
        accent: Color(0xFF7A6BF8),
        playButton: Color(0xFF2ECC71),
        softBackground: Color(0xFFEEEAFE),
        borderColor: Color(0xFFD7CCFB),
        icon: Icons.chat_bubble_rounded,
      ),
      ActivityType.sonidos => const _ResourcePalette(
        accent: Color(0xFF0F9C78),
        playButton: Color(0xFF0F9C78),
        softBackground: Color(0xFFE0F6F0),
        borderColor: Color(0xFFB7E8D8),
        icon: Icons.volume_up_rounded,
      ),
      ActivityType.letraObjetivo => const _ResourcePalette(
        accent: Color(0xFFEF7D32),
        playButton: Color(0xFF2ECC71),
        softBackground: Color(0xFFFFEEDC),
        borderColor: Color(0xFFFFD5AF),
        icon: Icons.spellcheck_rounded,
      ),
      ActivityType.cambioExacto => const _ResourcePalette(
        accent: Color(0xFF1DAA62),
        playButton: Color(0xFF1DAA62),
        softBackground: Color(0xFFE3F6EA),
        borderColor: Color(0xFFBAE9CB),
        icon: Icons.shopping_bag_rounded,
      ),
      ActivityType.ruletaLetras => const _ResourcePalette(
        accent: Color(0xFF7D54D8),
        playButton: Color(0xFF2ECC71),
        softBackground: Color(0xFFEDE6FD),
        borderColor: Color(0xFFD4C4F6),
        icon: Icons.casino_rounded,
      ),
      ActivityType.discriminacion => const _ResourcePalette(
        accent: Color(0xFF0F9C78),
        playButton: Color(0xFF2ECC71),
        softBackground: Color(0xFFE1F6F0),
        borderColor: Color(0xFFBAEBDD),
        icon: Icons.filter_center_focus_rounded,
      ),
      ActivityType.discriminacionInversa => const _ResourcePalette(
        accent: Color(0xFFA55EEA),
        playButton: Color(0xFF2ECC71),
        softBackground: Color(0xFFF1E8FD),
        borderColor: Color(0xFFE0CDF7),
        icon: Icons.pets_rounded,
      ),
    };
  }
}
