import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/providers/app_providers.dart';
import '../../domain/models/category.dart';
import '../../domain/models/difficulty.dart';
import '../../domain/models/level.dart';
import '../viewmodels/home_selection_view_model.dart';
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

    if (!_didSyncSettings) {
      _didSyncSettings = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        selectionVm.setDifficulty(settings.defaultDifficulty);
      });
    }

    // EN MODO PRUEBA, LOS NIVELES SUPERIORES QUEDAN SIEMPRE DISPONIBLES.
    final canLevel2 = true;
    final canLevel3 = true;

    final isCurrentUnlocked = switch (selection.level) {
      AppLevel.uno => true,
      AppLevel.dos => canLevel2,
      AppLevel.tres => canLevel3,
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
            icon: const Icon(Icons.settings),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  const Icon(Icons.person_outline),
                  const SizedBox(width: 10),
                  Expanded(
                    child: UpperText('PERFIL LOCAL: ${profile.displayName}'),
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
                    'SELECCIONA DIFICULTAD',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 10),
                  SegmentedButton<Difficulty>(
                    segments: const [
                      ButtonSegment(
                        value: Difficulty.primaria,
                        label: UpperText('PRIMARIA'),
                      ),
                      ButtonSegment(
                        value: Difficulty.secundaria,
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
                    'SELECCIONA CATEGORÍA',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: AppCategory.values.map((category) {
                      return ChoiceChip(
                        label: UpperText(category.label),
                        selected: selection.category == category,
                        onSelected: (_) => selectionVm.setCategory(category),
                      );
                    }).toList(),
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
                    'SELECCIONA NIVEL',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 12),
                  _LevelTile(
                    title: 'NIVEL 1 - INICIACIÓN',
                    subtitle: 'SIEMPRE DISPONIBLE',
                    selected: selection.level == AppLevel.uno,
                    locked: false,
                    onTap: () => selectionVm.setLevel(AppLevel.uno),
                  ),
                  const SizedBox(height: 8),
                  _LevelTile(
                    title: 'NIVEL 2 - PALABRA ↔ PALABRA',
                    subtitle: 'SIEMPRE DESBLOQUEADO (MODO PRUEBA)',
                    selected: selection.level == AppLevel.dos,
                    locked: !canLevel2,
                    onTap: () => selectionVm.setLevel(AppLevel.dos),
                  ),
                  const SizedBox(height: 8),
                  _LevelTile(
                    title: 'NIVEL 3 - IMAGEN ↔ FRASE',
                    subtitle: 'SIEMPRE DESBLOQUEADO (MODO PRUEBA)',
                    selected: selection.level == AppLevel.tres,
                    locked: !canLevel3,
                    onTap: () => selectionVm.setLevel(AppLevel.tres),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 18),
          FilledButton(
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
            child: const UpperText('CONTINUAR'),
          ),
        ],
      ),
    );
  }
}

class _LevelTile extends StatelessWidget {
  const _LevelTile({
    required this.title,
    required this.subtitle,
    required this.selected,
    required this.locked,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final bool selected;
  final bool locked;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: locked ? null : onTap,
      borderRadius: BorderRadius.circular(14),
      child: Ink(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected
                ? Theme.of(context).colorScheme.primary
                : Theme.of(context).colorScheme.outlineVariant,
            width: selected ? 3 : 1,
          ),
          color: locked ? Colors.grey.shade200 : null,
        ),
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Icon(locked ? Icons.lock : Icons.check_circle_outline),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  UpperText(title),
                  const SizedBox(height: 4),
                  UpperText(
                    subtitle,
                    style: Theme.of(context).textTheme.bodySmall,
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
