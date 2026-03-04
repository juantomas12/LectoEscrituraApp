import 'package:flutter/material.dart';

import 'game_style.dart';
import 'upper_text.dart';

class RoutineSteps extends StatelessWidget {
  const RoutineSteps({super.key, required this.currentStep});

  final int currentStep;

  @override
  Widget build(BuildContext context) {
    final steps = <({String label, IconData icon})>[
      (label: 'OBJETIVO', icon: Icons.flag_rounded),
      (label: 'TARJETAS', icon: Icons.style_rounded),
      (label: 'RESPUESTA', icon: Icons.check_circle_outline_rounded),
      (label: 'SIGUIENTE', icon: Icons.navigate_next_rounded),
    ];

    return GamePanel(
      padding: const EdgeInsets.all(10),
      radius: 20,
      backgroundColor: const Color(0xFFF1F5F9),
      borderColor: const Color(0xFFC5D2E2),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: List.generate(steps.length, (index) {
          final stepNumber = index + 1;
          final isActive = stepNumber == currentStep;
          final color = isActive ? kGameAccent : const Color(0xFF74818E);
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: isActive ? const Color(0xFFE0ECFF) : Colors.white,
              borderRadius: BorderRadius.circular(13),
              border: Border.all(
                color: isActive ? kGameAccent : const Color(0xFF9AA4AF),
                width: isActive ? 2.2 : 1.4,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircleAvatar(
                  radius: 12,
                  backgroundColor: color,
                  foregroundColor: Colors.white,
                  child: Text(
                    '$stepNumber',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                Icon(steps[index].icon, size: 16, color: color),
                const SizedBox(width: 4),
                UpperText(
                  steps[index].label,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: color,
                  ),
                ),
              ],
            ),
          );
        }),
      ),
    );
  }
}
