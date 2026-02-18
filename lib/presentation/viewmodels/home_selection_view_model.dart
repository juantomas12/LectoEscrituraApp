import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/models/activity_type.dart';
import '../../domain/models/category.dart';
import '../../domain/models/difficulty.dart';

class HomeSelectionState {
  const HomeSelectionState({
    required this.category,
    required this.game,
    required this.difficulty,
  });

  final AppCategory category;
  final ActivityType game;
  final Difficulty difficulty;

  HomeSelectionState copyWith({
    AppCategory? category,
    ActivityType? game,
    Difficulty? difficulty,
  }) {
    return HomeSelectionState(
      category: category ?? this.category,
      game: game ?? this.game,
      difficulty: difficulty ?? this.difficulty,
    );
  }
}

class HomeSelectionViewModel extends Notifier<HomeSelectionState> {
  @override
  HomeSelectionState build() {
    return const HomeSelectionState(
      category: AppCategory.cosasDeCasa,
      game: ActivityType.imagenPalabra,
      difficulty: Difficulty.primaria,
    );
  }

  void setCategory(AppCategory value) {
    state = state.copyWith(category: value);
  }

  void setGame(ActivityType value) {
    state = state.copyWith(game: value);
  }

  void setDifficulty(Difficulty value) {
    state = state.copyWith(difficulty: value);
  }
}

final homeSelectionViewModelProvider =
    NotifierProvider<HomeSelectionViewModel, HomeSelectionState>(
      HomeSelectionViewModel.new,
    );
