import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/providers/app_providers.dart';
import '../../domain/models/ai_resource.dart';

class AiResourceStudioState {
  const AiResourceStudioState({
    required this.resources,
    required this.isGenerating,
    this.errorMessage,
  });

  final List<AiResource> resources;
  final bool isGenerating;
  final String? errorMessage;

  AiResourceStudioState copyWith({
    List<AiResource>? resources,
    bool? isGenerating,
    String? errorMessage,
  }) {
    return AiResourceStudioState(
      resources: resources ?? this.resources,
      isGenerating: isGenerating ?? this.isGenerating,
      errorMessage: errorMessage,
    );
  }
}

class AiResourceStudioViewModel extends Notifier<AiResourceStudioState> {
  @override
  AiResourceStudioState build() {
    final all = ref.read(aiResourceRepositoryProvider).getAll();
    return AiResourceStudioState(resources: all, isGenerating: false);
  }

  void refresh() {
    final all = ref.read(aiResourceRepositoryProvider).getAll();
    state = AiResourceStudioState(
      resources: all,
      isGenerating: state.isGenerating,
      errorMessage: null,
    );
  }

  void clearError() {
    state = state.copyWith(
      resources: state.resources,
      isGenerating: state.isGenerating,
      errorMessage: null,
    );
  }

  Future<AiResource?> generateAndSave({
    required String instruction,
    required String ageRange,
    required String duration,
    required String mode,
    required String categoryLabel,
    required String difficultyLabel,
    String? apiKey,
    required List<String> allowedWords,
    String? model,
  }) async {
    state = AiResourceStudioState(
      resources: state.resources,
      isGenerating: true,
      errorMessage: null,
    );

    try {
      final generated = await ref
          .read(openAiResourceGeneratorServiceProvider)
          .generateResource(
            instruction: instruction,
            ageRange: ageRange,
            duration: duration,
            mode: mode,
            categoryLabel: categoryLabel,
            difficultyLabel: difficultyLabel,
            apiKey: apiKey,
            allowedWords: allowedWords,
            model: model,
          );

      await ref.read(aiResourceRepositoryProvider).save(generated);
      final all = ref.read(aiResourceRepositoryProvider).getAll();
      state = AiResourceStudioState(resources: all, isGenerating: false);
      return generated;
    } catch (error) {
      state = AiResourceStudioState(
        resources: state.resources,
        isGenerating: false,
        errorMessage: error.toString(),
      );
      return null;
    }
  }

  Future<void> delete(String id) async {
    await ref.read(aiResourceRepositoryProvider).delete(id);
    refresh();
  }

  Future<void> toggleFavorite(String id) async {
    AiResource? target;
    for (final item in state.resources) {
      if (item.id == id) {
        target = item;
        break;
      }
    }
    if (target == null) {
      return;
    }
    final updated = target.copyWith(isFavorite: !target.isFavorite);
    await ref.read(aiResourceRepositoryProvider).save(updated);
    refresh();
  }
}

final aiResourceStudioViewModelProvider =
    NotifierProvider<AiResourceStudioViewModel, AiResourceStudioState>(
      AiResourceStudioViewModel.new,
    );
