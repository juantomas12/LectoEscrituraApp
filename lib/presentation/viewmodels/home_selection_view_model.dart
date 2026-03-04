import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/models/activity_type.dart';
import '../../domain/models/category.dart';
import '../../domain/models/difficulty.dart';

class HomeSelectionState {
  const HomeSelectionState({
    required this.category,
    required this.game,
    required this.difficulty,
    required this.categoryOptionId,
  });

  final AppCategory category;
  final ActivityType? game;
  final Difficulty difficulty;
  final String categoryOptionId;

  HomeSelectionState copyWith({
    AppCategory? category,
    ActivityType? game,
    bool clearGame = false,
    Difficulty? difficulty,
    String? categoryOptionId,
  }) {
    return HomeSelectionState(
      category: category ?? this.category,
      game: clearGame ? null : game ?? this.game,
      difficulty: difficulty ?? this.difficulty,
      categoryOptionId: categoryOptionId ?? this.categoryOptionId,
    );
  }
}

class HomeSelectionViewModel extends Notifier<HomeSelectionState> {
  @override
  HomeSelectionState build() {
    return const HomeSelectionState(
      category: AppCategory.mixta,
      game: null,
      difficulty: Difficulty.primaria,
      categoryOptionId: 'MIX_CATEGORIAS',
    );
  }

  void setCategory(AppCategory value, {String? optionId}) {
    state = state.copyWith(
      category: value,
      clearGame: true,
      categoryOptionId: optionId ?? value.id,
    );
  }

  void setGame(ActivityType value) {
    state = state.copyWith(game: value, clearGame: false);
  }

  void setDifficulty(Difficulty value) {
    state = state.copyWith(difficulty: value);
  }
}

final homeSelectionViewModelProvider =
    NotifierProvider<HomeSelectionViewModel, HomeSelectionState>(
      HomeSelectionViewModel.new,
    );
