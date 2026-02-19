import 'package:flutter/material.dart';

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

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Wrap(
          spacing: 8,
          runSpacing: 8,
          children: List.generate(steps.length, (index) {
            final stepNumber = index + 1;
            final isActive = stepNumber == currentStep;
            final color = isActive
                ? Theme.of(context).colorScheme.primary
                : Theme.of(context).colorScheme.outline;
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: isActive
                    ? Theme.of(
                        context,
                      ).colorScheme.primary.withValues(alpha: 0.12)
                    : Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: color, width: isActive ? 2 : 1.2),
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
      ),
    );
  }
}
