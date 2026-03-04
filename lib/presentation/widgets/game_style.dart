import 'package:flutter/material.dart';

import 'upper_text.dart';

const Color kGameBackground = Color(0xFFEDEFF3);
const Color kGameHeaderBackground = Color(0xFFE9F0EE);
const Color kGameSurface = Color(0xFFFDFEFE);
const Color kGameStroke = Color(0xFFC9D5D3);
const Color kGameAccent = Color(0xFF2C86EA);

class GameScaffold extends StatelessWidget {
  const GameScaffold({
    super.key,
    required this.title,
    required this.body,
    this.actions,
  });

  final String title;
  final Widget body;
  final List<Widget>? actions;

  @override
  Widget build(BuildContext context) {
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
        actions: actions,
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
