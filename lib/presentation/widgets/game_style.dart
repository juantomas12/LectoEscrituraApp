import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/providers/app_providers.dart';
import '../viewmodels/settings_view_model.dart';
import 'upper_text.dart';

const Color kGameBackground = Color(0xFFEDEFF3);
const Color kGameHeaderBackground = Color(0xFFE9F0EE);
const Color kGameSurface = Color(0xFFFDFEFE);
const Color kGameStroke = Color(0xFFC9D5D3);
const Color kGameAccent = Color(0xFF2C86EA);

bool isPrimaryTabletLandscape(BuildContext context) {
  final media = MediaQuery.sizeOf(context);
  final orientation = MediaQuery.orientationOf(context);
  return media.width >= 700 &&
      media.width < 1200 &&
      orientation == Orientation.landscape;
}

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
    final isTabletLandscape =
        enableDesktopShell &&
        !isDesktopLandscape &&
        isPrimaryTabletLandscape(context);

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
      return Scaffold(
        backgroundColor: const Color(0xFFF1F3F7),
        body: SafeArea(
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
                      side: const BorderSide(color: kGameAccent, width: 2.5),
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
      );
    }

    if (isTabletLandscape) {
      return Scaffold(
        backgroundColor: kGameBackground,
        body: SafeArea(
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.fromLTRB(6, 4, 6, 4),
                decoration: const BoxDecoration(
                  color: kGameHeaderBackground,
                  border: Border(
                    bottom: BorderSide(color: Color(0xFFCFD8E5), width: 1),
                  ),
                ),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () => Navigator.of(context).maybePop(),
                      icon: const Icon(Icons.arrow_back_rounded),
                      tooltip: 'VOLVER',
                    ),
                    Expanded(
                      child: UpperText(
                        title,
                        maxLines: 1,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 21,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFF182037),
                        ),
                      ),
                    ),
                    ...appBarActions,
                  ],
                ),
              ),
              if (hasInstruction)
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 6, 12, 2),
                  child: UpperText(
                    instructionText!,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF425A87),
                    ),
                  ),
                ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(10, 4, 10, 8),
                  child: ScrollConfiguration(
                    behavior: const _NoScrollBehavior(),
                    child: MediaQuery(
                      data: MediaQuery.of(
                        context,
                      ).copyWith(textScaler: const TextScaler.linear(0.94)),
                      child: body,
                    ),
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

class _NoScrollBehavior extends MaterialScrollBehavior {
  const _NoScrollBehavior();

  @override
  ScrollPhysics getScrollPhysics(BuildContext context) {
    return const NeverScrollableScrollPhysics();
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
