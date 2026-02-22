import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/models/activity_type.dart';
import '../../domain/models/category.dart';
import '../utils/category_visuals.dart';
import '../viewmodels/progress_view_model.dart';
import '../viewmodels/settings_view_model.dart';
import '../widgets/upper_text.dart';

class TherapistPanelScreen extends ConsumerStatefulWidget {
  const TherapistPanelScreen({super.key});

  @override
  ConsumerState<TherapistPanelScreen> createState() =>
      _TherapistPanelScreenState();
}

class _TherapistPanelScreenState extends ConsumerState<TherapistPanelScreen> {
  int _windowDays = 30;

  @override
  Widget build(BuildContext context) {
    ref.watch(progressViewModelProvider);
    final progressVm = ref.read(progressViewModelProvider.notifier);
    final settings = ref.watch(settingsViewModelProvider);
    final settingsVm = ref.read(settingsViewModelProvider.notifier);

    final allResults = progressVm.getAllResults()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    final filteredResults = _windowDays == 0
        ? allResults
        : allResults
              .where(
                (result) => result.createdAt.isAfter(
                  DateTime.now().subtract(Duration(days: _windowDays)),
                ),
              )
              .toList();

    final totalResults = filteredResults.length;
    final totalCorrect = filteredResults.fold<int>(
      0,
      (sum, item) => sum + item.correct,
    );
    final totalIncorrect = filteredResults.fold<int>(
      0,
      (sum, item) => sum + item.incorrect,
    );
    final totalAttempts = totalCorrect + totalIncorrect;
    final globalAccuracy = totalAttempts == 0
        ? 0
        : totalCorrect / totalAttempts;
    final avgDuration = totalResults == 0
        ? 0
        : (filteredResults.fold<int>(
                    0,
                    (sum, result) => sum + result.durationInSeconds,
                  ) /
                  totalResults)
              .round();

    final activities = progressVm.activityPerformance(source: filteredResults);
    final categories = progressVm.categoryPerformance(source: filteredResults);
    final recent = filteredResults.take(8).toList();

    final letters = progressVm.letterPerformance(minAttempts: 2);
    final hardestLetters = List<LetterPerformance>.from(letters)
      ..sort((a, b) {
        final byError = b.errorRate.compareTo(a.errorRate);
        if (byError != 0) {
          return byError;
        }
        return b.totalAttempts.compareTo(a.totalAttempts);
      });
    final masteredLetters = List<LetterPerformance>.from(letters)
      ..sort((a, b) {
        final byMastery = b.masteryRate.compareTo(a.masteryRate);
        if (byMastery != 0) {
          return byMastery;
        }
        return b.totalAttempts.compareTo(a.totalAttempts);
      });

    final supportCategories =
        categories.where((entry) => entry.sessions > 0).toList()
          ..sort((a, b) => a.accuracy.compareTo(b.accuracy));
    final supportLetters = hardestLetters
        .where((entry) => entry.totalAttempts >= 3)
        .toList();

    final recommendedLevels = <ActivityType, int>{
      ActivityType.letraObjetivo: progressVm.recommendedLevelForGame(
        ActivityType.letraObjetivo,
      ),
      ActivityType.discriminacion: progressVm.recommendedLevelForGame(
        ActivityType.discriminacion,
      ),
      ActivityType.discriminacionInversa: progressVm.recommendedLevelForGame(
        ActivityType.discriminacionInversa,
      ),
    };

    return Scaffold(
      appBar: AppBar(title: const UpperText('PANEL ADULTO / TERAPEUTA')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  const UpperText(
                    'PERIODO:',
                    style: TextStyle(fontWeight: FontWeight.w900),
                  ),
                  ChoiceChip(
                    selected: _windowDays == 7,
                    label: const UpperText('7 DÍAS'),
                    onSelected: (_) => setState(() => _windowDays = 7),
                  ),
                  ChoiceChip(
                    selected: _windowDays == 30,
                    label: const UpperText('30 DÍAS'),
                    onSelected: (_) => setState(() => _windowDays = 30),
                  ),
                  ChoiceChip(
                    selected: _windowDays == 0,
                    label: const UpperText('TODO'),
                    onSelected: (_) => setState(() => _windowDays = 0),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  UpperText(
                    'RESUMEN GLOBAL',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  UpperText('ACTIVIDADES: $totalResults'),
                  const SizedBox(height: 4),
                  UpperText('INTENTOS: $totalAttempts'),
                  const SizedBox(height: 4),
                  UpperText('ACIERTOS: $totalCorrect'),
                  const SizedBox(height: 4),
                  UpperText('ERRORES: $totalIncorrect'),
                  const SizedBox(height: 4),
                  UpperText('TIEMPO MEDIO: ${avgDuration}s'),
                  const SizedBox(height: 4),
                  UpperText(
                    'PRECISIÓN: ${(globalAccuracy * 100).toStringAsFixed(0)} %',
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  UpperText(
                    'PRIORIDADES DE INTERVENCIÓN',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  if (supportCategories.isEmpty)
                    const UpperText('SIN DATOS TODAVÍA')
                  else ...[
                    const UpperText('CATEGORÍAS A REFORZAR:'),
                    const SizedBox(height: 6),
                    ...supportCategories.take(3).map((entry) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: Row(
                          children: [
                            Icon(
                              entry.category.icon,
                              color: entry.category.color,
                            ),
                            const SizedBox(width: 8),
                            Expanded(child: UpperText(entry.category.label)),
                            UpperText(
                              '${(entry.accuracy * 100).toStringAsFixed(0)} %',
                              style: TextStyle(
                                fontWeight: FontWeight.w900,
                                color: _accuracyColor(entry.accuracy),
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                  ],
                  const SizedBox(height: 8),
                  if (supportLetters.isNotEmpty) ...[
                    const UpperText('LETRAS A REFORZAR:'),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: supportLetters.take(5).map((entry) {
                        return _letterChip(
                          context,
                          letter: entry.letter,
                          rate: entry.errorRate,
                          attempts: entry.totalAttempts,
                          incorrect: entry.incorrectAttempts,
                          inverseColor: true,
                        );
                      }).toList(),
                    ),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  UpperText(
                    'AJUSTE AUTOMÁTICO',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 6),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    value: settings.autoAdjustLevel,
                    onChanged: settingsVm.setAutoAdjustLevel,
                    title: const UpperText('AJUSTAR NIVEL AUTOMÁTICAMENTE'),
                    subtitle: const UpperText(
                      'USA RESULTADOS RECIENTES PARA SUGERIR NIVEL',
                    ),
                  ),
                  const SizedBox(height: 6),
                  ...recommendedLevels.entries.map((entry) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Row(
                        children: [
                          const Icon(Icons.tune_rounded, size: 18),
                          const SizedBox(width: 6),
                          Expanded(
                            child: UpperText(_shortActivityLabel(entry.key)),
                          ),
                          UpperText(
                            'NIVEL ${entry.value}',
                            style: const TextStyle(fontWeight: FontWeight.w800),
                          ),
                        ],
                      ),
                    );
                  }),
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  UpperText(
                    'RENDIMIENTO POR JUEGO',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  if (activities.isEmpty)
                    const UpperText('SIN DATOS EN ESTE PERIODO')
                  else
                    ...activities.map((entry) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Theme.of(context)
                                .colorScheme
                                .surfaceContainerHighest
                                .withValues(alpha: 0.35),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              UpperText(
                                _shortActivityLabel(entry.activityType),
                                style: const TextStyle(
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Wrap(
                                spacing: 10,
                                runSpacing: 6,
                                children: [
                                  UpperText('SESIONES: ${entry.sessions}'),
                                  UpperText('INTENTOS: ${entry.attempts}'),
                                  UpperText(
                                    'PRECISIÓN: ${(entry.accuracy * 100).toStringAsFixed(0)} %',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w800,
                                      color: _accuracyColor(entry.accuracy),
                                    ),
                                  ),
                                  UpperText(
                                    'TIEMPO MEDIO: ${entry.avgDurationSec}s',
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    }),
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  UpperText(
                    'PRECISIÓN POR CATEGORÍA',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  ...categories.map((entry) {
                    final accuracy = entry.accuracy;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Icon(
                                entry.category.icon,
                                color: entry.category.color,
                              ),
                              const SizedBox(width: 8),
                              Expanded(child: UpperText(entry.category.label)),
                              UpperText(
                                entry.sessions == 0
                                    ? 'SIN DATOS'
                                    : '${(accuracy * 100).toStringAsFixed(0)} %',
                                style: TextStyle(
                                  fontWeight: FontWeight.w900,
                                  color: _accuracyColor(accuracy),
                                ),
                              ),
                            ],
                          ),
                          if (entry.sessions > 0) ...[
                            const SizedBox(height: 4),
                            LinearProgressIndicator(
                              value: accuracy.clamp(0, 1),
                              minHeight: 8,
                              borderRadius: BorderRadius.circular(999),
                              color: _accuracyColor(accuracy),
                            ),
                            const SizedBox(height: 4),
                            Align(
                              alignment: Alignment.centerLeft,
                              child: UpperText(
                                'SESIONES: ${entry.sessions} · INTENTOS: ${entry.attempts}',
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            ),
                          ],
                        ],
                      ),
                    );
                  }),
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  UpperText(
                    'LETRAS CON MÁS DIFICULTAD (HISTÓRICO)',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  if (hardestLetters.isEmpty)
                    const UpperText('SIN DATOS AÚN')
                  else
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: hardestLetters.take(10).map((entry) {
                        return _letterChip(
                          context,
                          letter: entry.letter,
                          rate: entry.errorRate,
                          attempts: entry.totalAttempts,
                          incorrect: entry.incorrectAttempts,
                          inverseColor: true,
                        );
                      }).toList(),
                    ),
                  const SizedBox(height: 12),
                  UpperText(
                    'LETRAS MEJOR DOMINADAS (HISTÓRICO)',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  if (masteredLetters.isEmpty)
                    const UpperText('SIN DATOS AÚN')
                  else
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: masteredLetters
                          .where((entry) => entry.totalAttempts >= 3)
                          .take(8)
                          .map((entry) {
                            return _letterChip(
                              context,
                              letter: entry.letter,
                              rate: entry.masteryRate,
                              attempts: entry.totalAttempts,
                              incorrect: entry.incorrectAttempts,
                              inverseColor: false,
                            );
                          })
                          .toList(),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  UpperText(
                    'ACTIVIDAD RECIENTE',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  if (recent.isEmpty)
                    const UpperText('SIN REGISTROS EN ESTE PERIODO')
                  else
                    ...recent.map((entry) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Row(
                          children: [
                            const Icon(Icons.history_rounded, size: 18),
                            const SizedBox(width: 8),
                            Expanded(
                              child: UpperText(
                                '${_shortActivityLabel(entry.activityType)} · ${entry.category.label}',
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            UpperText(
                              '${(entry.accuracy * 100).toStringAsFixed(0)} %',
                              style: TextStyle(
                                fontWeight: FontWeight.w900,
                                color: _accuracyColor(entry.accuracy),
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _accuracyColor(double value) {
    if (value >= 0.8) {
      return Colors.green.shade700;
    }
    if (value >= 0.6) {
      return Colors.orange.shade700;
    }
    return Colors.red.shade700;
  }

  String _shortActivityLabel(ActivityType activityType) {
    return switch (activityType) {
      ActivityType.imagenPalabra => 'IMAGEN - PALABRA',
      ActivityType.escribirPalabra => 'ESCRITURA',
      ActivityType.palabraPalabra => 'PALABRA - PALABRA',
      ActivityType.imagenFrase => 'IMAGEN - FRASE',
      ActivityType.letraObjetivo => 'LETRA OBJETIVO',
      ActivityType.cambioExacto => 'CAMBIO EXACTO',
      ActivityType.ruletaLetras => 'RULETA LETRAS',
      ActivityType.discriminacion => 'DISCRIMINACIÓN',
      ActivityType.discriminacionInversa => 'DISCRIMINACIÓN INVERSA',
    };
  }

  Widget _letterChip(
    BuildContext context, {
    required String letter,
    required double rate,
    required int attempts,
    required int incorrect,
    required bool inverseColor,
  }) {
    final safeRate = rate.clamp(0.0, 1.0).toDouble();
    final green = inverseColor ? (1 - safeRate) : safeRate;
    final chipColor = Color.lerp(
      Colors.red.shade300,
      Colors.green.shade300,
      green,
    )!;
    final label = inverseColor
        ? '$letter ${(safeRate * 100).toStringAsFixed(0)}% · $incorrect/$attempts'
        : '$letter ${(safeRate * 100).toStringAsFixed(0)}% · ${attempts - incorrect}/$attempts';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: chipColor.withValues(alpha: 0.20),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: chipColor, width: 1.5),
      ),
      child: UpperText(
        label,
        style: const TextStyle(fontWeight: FontWeight.w900),
      ),
    );
  }
}
