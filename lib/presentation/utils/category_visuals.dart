import 'package:flutter/material.dart';

import '../../domain/models/category.dart';

extension CategoryVisualsX on AppCategory {
  IconData get icon => switch (this) {
    AppCategory.mixta => Icons.shuffle_rounded,
    AppCategory.cosasDeCasa => Icons.chair_alt_rounded,
    AppCategory.comida => Icons.restaurant_rounded,
    AppCategory.dinero => Icons.paid_rounded,
    AppCategory.bano => Icons.shower_rounded,
    AppCategory.profesiones => Icons.work_rounded,
    AppCategory.salud => Icons.favorite_rounded,
    AppCategory.emociones => Icons.mood_rounded,
  };

  Color get color => switch (this) {
    AppCategory.mixta => const Color(0xFF1A7D95),
    AppCategory.cosasDeCasa => const Color(0xFF2F9E8A),
    AppCategory.comida => const Color(0xFFE8871E),
    AppCategory.dinero => const Color(0xFF3AA356),
    AppCategory.bano => const Color(0xFF3A8CE0),
    AppCategory.profesiones => const Color(0xFF8D62DA),
    AppCategory.salud => const Color(0xFFE75B74),
    AppCategory.emociones => const Color(0xFFF2B705),
  };
}
