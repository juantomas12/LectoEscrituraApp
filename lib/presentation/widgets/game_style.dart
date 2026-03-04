import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/providers/app_providers.dart';
import '../screens/progress_dashboard_screen.dart';
import '../screens/settings_screen.dart';
import '../viewmodels/home_selection_view_model.dart';
import '../viewmodels/settings_view_model.dart';
import 'upper_text.dart';

const Color kGameBackground = Color(0xFFEDEFF3);
const Color kGameHeaderBackground = Color(0xFFE9F0EE);
const Color kGameSurface = Color(0xFFFDFEFE);
const Color kGameStroke = Color(0xFFC9D5D3);
const Color kGameAccent = Color(0xFF2C86EA);

class GameScaffold extends ConsumerWidget {
  const GameScaffold({
    super.key,
    required this.title,
    required this.body,
    this.actions,
    this.instructionText,
    this.progressCurrent,
    this.progressTotal,
    this.desktopLessonTitle,
    this.desktopHeadline,
    this.enableDesktopShell = true,
  });

  final String title;
  final Widget body;
  final List<Widget>? actions;
  final String? instructionText;
  final int? progressCurrent;
  final int? progressTotal;
  final String? desktopLessonTitle;
  final String? desktopHeadline;
  final bool enableDesktopShell;

  void _openTechnicalAidsSheet(BuildContext context, WidgetRef ref) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) {
        return SafeArea(
          child: Consumer(
            builder: (context, ref, _) {
              final settings = ref.watch(settingsViewModelProvider);
              final vm = ref.read(settingsViewModelProvider.notifier);
              return Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const UpperText(
                      'AYUDAS TÉCNICAS',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 10),
                    SwitchListTile(
                      value: settings.showHints,
                      onChanged: vm.setShowHints,
                      title: const UpperText('MOSTRAR PISTAS'),
                    ),
                    SwitchListTile(
                      value: settings.audioEnabled,
                      onChanged: vm.setAudioEnabled,
                      title: const UpperText('AUDIO DE INSTRUCCIONES'),
                    ),
                    SwitchListTile(
                      value: settings.dyslexiaMode,
                      onChanged: vm.setDyslexiaMode,
                      title: const UpperText('MODO DISLEXIA'),
                    ),
                    SwitchListTile(
                      value: settings.highContrast,
                      onChanged: vm.setHighContrast,
                      title: const UpperText('ALTO CONTRASTE'),
                    ),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }

  Future<void> _speakInstruction(BuildContext context, WidgetRef ref) async {
    final text = (instructionText ?? '').trim();
    if (text.isEmpty) {
      return;
    }
    final settings = ref.read(settingsViewModelProvider);
    if (!settings.audioEnabled) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('ACTIVA EL AUDIO EN AYUDAS TÉCNICAS')),
      );
      return;
    }
    await ref.read(ttsServiceProvider).speak(text);
  }

  void _openLearnHome(BuildContext context) {
    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  void _openProgress(BuildContext context, WidgetRef ref) {
    final category = ref.read(homeSelectionViewModelProvider).category;
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => ProgressDashboardScreen(category: category),
      ),
    );
  }

  void _openSettings(BuildContext context) {
    Navigator.of(
      context,
    ).push(MaterialPageRoute<void>(builder: (_) => const SettingsScreen()));
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hasInstruction = (instructionText ?? '').trim().isNotEmpty;
    final media = MediaQuery.sizeOf(context);
    final orientation = MediaQuery.orientationOf(context);
    final isDesktopLandscape =
        enableDesktopShell &&
        hasInstruction &&
        media.width >= 1200 &&
        orientation == Orientation.landscape;

    final appBarActions = <Widget>[
      if (hasInstruction)
        IconButton(
          onPressed: () => _openTechnicalAidsSheet(context, ref),
          icon: const Icon(Icons.tune_rounded),
          tooltip: 'AYUDA TÉCNICA',
        ),
      if (hasInstruction)
        IconButton(
          onPressed: () => _speakInstruction(context, ref),
          icon: const Icon(Icons.headset_rounded),
          tooltip: 'ESCUCHAR INSTRUCCIÓN',
        ),
      ...?actions,
    ];

    if (isDesktopLandscape) {
      final current = progressCurrent ?? 0;
      final total = progressTotal ?? 0;
      final safeTotal = total <= 0 ? 1 : total;
      final progress = (current / safeTotal).clamp(0.0, 1.0);
      return Scaffold(
        backgroundColor: const Color(0xFFF1F3F7),
        body: SafeArea(
          child: Row(
            children: [
              Container(
                width: 320,
                decoration: const BoxDecoration(
                  color: Color(0xFFF8FAFF),
                  border: Border(right: BorderSide(color: Color(0xFFD7DFEC))),
                ),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 22, 24, 22),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 62,
                            height: 62,
                            decoration: BoxDecoration(
                              color: const Color(0xFFEAF1FF),
                              borderRadius: BorderRadius.circular(18),
                            ),
                            child: const Icon(
                              Icons.menu_book_rounded,
                              size: 34,
                            ),
                          ),
                          const SizedBox(width: 10),
                          const Expanded(
                            child: UpperText(
                              'EDUMUNDO\nALFABETIZACIÓN',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w900,
                                height: 1.15,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 18),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEAF1FF),
                          borderRadius: BorderRadius.circular(24),
                        ),
                        child: UpperText(
                          'LECCIÓN ACTUAL\n${desktopLessonTitle ?? title}',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                            height: 1.15,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      _GameDesktopSidebarItem(
                        icon: Icons.menu_book_rounded,
                        label: 'APRENDER',
                        active: true,
                        onTap: () => _openLearnHome(context),
                      ),
                      const SizedBox(height: 10),
                      _GameDesktopSidebarItem(
                        icon: Icons.bar_chart_rounded,
                        label: 'MI PROGRESO',
                        onTap: () => _openProgress(context, ref),
                      ),
                      const SizedBox(height: 10),
                      _GameDesktopSidebarItem(
                        icon: Icons.settings_rounded,
                        label: 'AJUSTES',
                        onTap: () => _openSettings(context),
                      ),
                      const Spacer(),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEFF4FF),
                          borderRadius: BorderRadius.circular(24),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const UpperText(
                              'TU PROGRESO',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF5D6E8C),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Expanded(
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(999),
                                    child: LinearProgressIndicator(
                                      value: progress,
                                      minHeight: 12,
                                      backgroundColor: const Color(0xFFD7DEEA),
                                      color: kGameAccent,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                UpperText(
                                  '$current/$total',
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w900,
                                    color: Color(0xFF2D66C3),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),
                      FilledButton(
                        onPressed: () => _openTechnicalAidsSheet(context, ref),
                        style: FilledButton.styleFrom(
                          backgroundColor: const Color(0xFF0E1A3D),
                          minimumSize: const Size.fromHeight(56),
                        ),
                        child: const UpperText('AYUDA TÉCNICA'),
                      ),
                    ],
                  ),
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(36, 24, 36, 18),
                  child: Column(
                    children: [
                      UpperText(
                        desktopHeadline ?? title,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 58,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFF121C3D),
                          height: 1.05,
                        ),
                      ),
                      const SizedBox(height: 6),
                      UpperText(
                        instructionText ?? '',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF4D638C),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Expanded(child: body),
                      const SizedBox(height: 12),
                      Align(
                        alignment: Alignment.centerRight,
                        child: OutlinedButton.icon(
                          onPressed: () => _speakInstruction(context, ref),
                          icon: const Icon(Icons.headset_rounded),
                          label: const UpperText('ESCUCHAR INSTRUCCIÓN'),
                          style: OutlinedButton.styleFrom(
                            minimumSize: const Size(340, 66),
                            side: const BorderSide(
                              color: kGameAccent,
                              width: 2.5,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(44),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: kGameBackground,
      appBar: AppBar(
        title: UpperText(
          title,
          style: const TextStyle(
            fontSize: 23,
            fontWeight: FontWeight.w900,
            color: Color(0xFF182037),
          ),
        ),
        centerTitle: true,
        backgroundColor: kGameHeaderBackground,
        foregroundColor: const Color(0xFF182037),
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        actions: appBarActions.isEmpty ? null : appBarActions,
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: ColoredBox(
            color: Color(0xFFCFD8E5),
            child: SizedBox(height: 1),
          ),
        ),
      ),
      body: SafeArea(child: body),
    );
  }
}

class _GameDesktopSidebarItem extends StatelessWidget {
  const _GameDesktopSidebarItem({
    required this.icon,
    required this.label,
    this.active = false,
    this.onTap,
  });

  final IconData icon;
  final String label;
  final bool active;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: Ink(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: active ? kGameAccent : Colors.transparent,
            borderRadius: BorderRadius.circular(999),
          ),
          child: Row(
            children: [
              Icon(
                icon,
                color: active ? Colors.white : const Color(0xFF51607C),
              ),
              const SizedBox(width: 10),
              UpperText(
                label,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: active ? Colors.white : const Color(0xFF1D2A49),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class GamePanel extends StatelessWidget {
  const GamePanel({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(14),
    this.backgroundColor = kGameSurface,
    this.borderColor = kGameStroke,
    this.radius = 22,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final Color backgroundColor;
  final Color borderColor;
  final double radius;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: borderColor, width: 1.4),
      ),
      child: child,
    );
  }
}

class GameProgressHeader extends StatelessWidget {
  const GameProgressHeader({
    super.key,
    required this.label,
    required this.current,
    required this.total,
    this.trailingLabel,
  });

  final String label;
  final int current;
  final int total;
  final String? trailingLabel;

  @override
  Widget build(BuildContext context) {
    final safeTotal = total <= 0 ? 1 : total;
    final progress = (current / safeTotal).clamp(0.0, 1.0);

    return GamePanel(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: UpperText(
                  label,
                  style: const TextStyle(
                    fontSize: 16,
                    color: Color(0xFF57698C),
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              UpperText(
                '$current/$total',
                style: const TextStyle(
                  fontSize: 16,
                  color: Color(0xFF1B2950),
                  fontWeight: FontWeight.w900,
                ),
              ),
              if (trailingLabel != null) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(999),
                    color: const Color(0xFFFFEDAF),
                    border: Border.all(color: const Color(0xFFF0D778)),
                  ),
                  child: UpperText(
                    trailingLabel!,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 11,
              backgroundColor: const Color(0xFFD7DEEA),
              color: kGameAccent,
            ),
          ),
        ],
      ),
    );
  }
}
