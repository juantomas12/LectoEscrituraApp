import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/providers/app_providers.dart';
import '../../core/utils/text_utils.dart';
import '../../domain/models/ai_resource.dart';
import '../../domain/models/activity_type.dart';

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
  AiResource? _findExistingByInstruction({
    required String instruction,
    required ActivityType? requestedGameType,
    required List<AiResource> resources,
  }) {
    final normalizedInstruction = normalizeForComparison(
      instruction,
      ignoreAccents: true,
    );
    if (normalizedInstruction.isEmpty) {
      return null;
    }

    for (final resource in resources) {
      final normalizedExisting = normalizeForComparison(
        resource.instruction,
        ignoreAccents: true,
      );
      if (normalizedExisting != normalizedInstruction) {
        continue;
      }
      if (requestedGameType != null &&
          resource.requestedActivityTypeKey != requestedGameType.key) {
        continue;
      }
      return resource;
    }
    return null;
  }

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
    ActivityType? requestedGameType,
    String? apiKey,
    required List<String> allowedWords,
    String? model,
  }) async {
    final repository = ref.read(aiResourceRepositoryProvider);
    state = AiResourceStudioState(
      resources: state.resources,
      isGenerating: true,
      errorMessage: null,
    );

    try {
      final existing = _findExistingByInstruction(
        instruction: instruction,
        requestedGameType: requestedGameType,
        resources: repository.getAll(),
      );
      if (existing != null) {
        final all = repository.getAll();
        state = AiResourceStudioState(resources: all, isGenerating: false);
        return existing;
      }

      final generated = await ref
          .read(openAiResourceGeneratorServiceProvider)
          .generateResource(
            instruction: instruction,
            ageRange: ageRange,
            duration: duration,
            mode: mode,
            categoryLabel: categoryLabel,
            difficultyLabel: difficultyLabel,
            requestedGameType: requestedGameType,
            apiKey: apiKey,
            allowedWords: allowedWords,
            model: model,
          );

      await repository.save(generated);
      final all = repository.getAll();
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
