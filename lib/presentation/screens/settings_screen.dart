import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/models/difficulty.dart';
import 'image_manager_screen.dart';
import '../viewmodels/settings_view_model.dart';
import '../widgets/upper_text.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsViewModelProvider);
    final vm = ref.read(settingsViewModelProvider.notifier);

    return Scaffold(
      appBar: AppBar(title: const UpperText('AJUSTES')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  UpperText(
                    'ACCESIBILIDAD',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const UpperText('AUDIO (TTS LOCAL)'),
                    value: settings.audioEnabled,
                    onChanged: vm.setAudioEnabled,
                  ),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const UpperText('ALTO CONTRASTE'),
                    value: settings.highContrast,
                    onChanged: vm.setHighContrast,
                  ),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const UpperText('MODO DISLEXIA (SIMILAR)'),
                    value: settings.dyslexiaMode,
                    onChanged: vm.setDyslexiaMode,
                  ),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const UpperText('TOLERAR ACENTOS EN VALIDACIÓN'),
                    value: settings.accentTolerance,
                    onChanged: vm.setAccentTolerance,
                  ),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const UpperText('MOSTRAR PISTAS'),
                    value: settings.showHints,
                    onChanged: vm.setShowHints,
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
                    'DIFICULTAD POR DEFECTO',
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
                    selected: {settings.defaultDifficulty},
                    onSelectionChanged: (value) {
                      vm.setDifficulty(value.first);
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
                    'DESBLOQUEO DE NIVELES',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  const UpperText('ACTIVIDADES NECESARIAS PARA PASAR DE NIVEL'),
                  const SizedBox(height: 10),
                  SegmentedButton<int>(
                    segments: const [
                      ButtonSegment(value: 0, label: UpperText('TODOS')),
                      ButtonSegment(value: 2, label: UpperText('2')),
                      ButtonSegment(value: 3, label: UpperText('3')),
                      ButtonSegment(value: 4, label: UpperText('4')),
                    ],
                    selected: {settings.unlockThreshold},
                    onSelectionChanged: (value) {
                      vm.setUnlockThreshold(value.first);
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
                    'GESTIÓN DE IMÁGENES',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  const UpperText(
                    'SI UNA IMAGEN NO TE GUSTA, CÁMBIALA Y GUÁRDALA EN LOCAL',
                  ),
                  const SizedBox(height: 10),
                  FilledButton.icon(
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => const ImageManagerScreen(),
                        ),
                      );
                    },
                    icon: const Icon(Icons.photo_library_outlined),
                    label: const UpperText('EDITAR IMÁGENES DE ÍTEMS'),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
