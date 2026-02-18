import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/models/category.dart';
import '../../domain/models/difficulty.dart';
import '../../domain/models/level.dart';

class HomeSelectionState {
  const HomeSelectionState({
    required this.category,
    required this.level,
    required this.difficulty,
  });

  final AppCategory category;
  final AppLevel level;
  final Difficulty difficulty;

  HomeSelectionState copyWith({
    AppCategory? category,
    AppLevel? level,
    Difficulty? difficulty,
  }) {
    return HomeSelectionState(
      category: category ?? this.category,
      level: level ?? this.level,
      difficulty: difficulty ?? this.difficulty,
    );
  }
}

class HomeSelectionViewModel extends Notifier<HomeSelectionState> {
  @override
  HomeSelectionState build() {
    return const HomeSelectionState(
      category: AppCategory.cosasDeCasa,
      level: AppLevel.uno,
      difficulty: Difficulty.primaria,
    );
  }

  void setCategory(AppCategory value) {
    state = state.copyWith(category: value);
  }

  void setLevel(AppLevel value) {
    state = state.copyWith(level: value);
  }

  void setDifficulty(Difficulty value) {
    state = state.copyWith(difficulty: value);
  }
}

final homeSelectionViewModelProvider =
    NotifierProvider<HomeSelectionViewModel, HomeSelectionState>(
      HomeSelectionViewModel.new,
    );
