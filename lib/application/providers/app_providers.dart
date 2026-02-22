import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/repositories/ai_resource_repository.dart';
import '../../data/repositories/dataset_repository.dart';
import '../../data/repositories/image_override_repository.dart';
import '../../data/repositories/local_dataset_repository.dart';
import '../../data/repositories/profile_repository.dart';
import '../../data/repositories/progress_repository.dart';
import '../../data/repositories/session_plan_repository.dart';
import '../../data/repositories/settings_repository.dart';
import '../../data/services/openai_resource_generator_service.dart';
import '../../data/services/openai_session_copilot_service.dart';
import '../../data/services/tts_service.dart';
import '../../core/config/env_config.dart';
import '../../domain/models/user_profile.dart';

final datasetRepositoryProvider = Provider<DatasetRepository>((ref) {
  return LocalDatasetRepository();
});

final progressRepositoryProvider = Provider<ProgressRepository>((ref) {
  return ProgressRepository();
});

final aiResourceRepositoryProvider = Provider<AiResourceRepository>((ref) {
  return AiResourceRepository();
});

final settingsRepositoryProvider = Provider<SettingsRepository>((ref) {
  return SettingsRepository();
});

final sessionPlanRepositoryProvider = Provider<SessionPlanRepository>((ref) {
  return SessionPlanRepository();
});

final imageOverrideRepositoryProvider = Provider<ImageOverrideRepository>((
  ref,
) {
  return ImageOverrideRepository();
});

final profileRepositoryProvider = Provider<ProfileRepository>((ref) {
  return ProfileRepository();
});

final ttsServiceProvider = Provider<TtsService>((ref) {
  final service = TtsService();
  ref.onDispose(service.stop);
  return service;
});

final openAiResourceGeneratorServiceProvider =
    Provider<OpenAiResourceGeneratorService>((ref) {
      return OpenAiResourceGeneratorService();
    });

final openAiSessionCopilotServiceProvider =
    Provider<OpenAiSessionCopilotService>((ref) {
      return OpenAiSessionCopilotService();
    });

final localProfileProvider = Provider<UserProfile>((ref) {
  return ref.read(profileRepositoryProvider).loadProfile();
});

final appStartupProvider = FutureProvider<void>((ref) async {
  final datasetRepository = ref.read(datasetRepositoryProvider);
  final progressRepository = ref.read(progressRepositoryProvider);
  final aiResourceRepository = ref.read(aiResourceRepositoryProvider);
  final sessionPlanRepository = ref.read(sessionPlanRepositoryProvider);
  final settingsRepository = ref.read(settingsRepositoryProvider);
  final imageOverrideRepository = ref.read(imageOverrideRepositoryProvider);
  final profileRepository = ref.read(profileRepositoryProvider);
  final ttsService = ref.read(ttsServiceProvider);

  await settingsRepository.init();
  final currentSettings = settingsRepository.loadSettings();
  if (currentSettings.openAiApiKey.trim().isEmpty &&
      EnvConfig.openAiApiKey.isNotEmpty) {
    await settingsRepository.saveSettings(
      currentSettings.copyWith(
        openAiApiKey: EnvConfig.openAiApiKey,
        openAiModel: currentSettings.openAiModel.trim().isEmpty
            ? EnvConfig.openAiModel
            : currentSettings.openAiModel,
      ),
    );
  }
  await imageOverrideRepository.init();
  await profileRepository.init();
  await progressRepository.init();
  await aiResourceRepository.init();
  await sessionPlanRepository.init();
  await datasetRepository.load();
  final imageOverrides = imageOverrideRepository.loadOverrides();
  datasetRepository.setImageOverrides(imageOverrides);
  await ttsService.configure();
});
