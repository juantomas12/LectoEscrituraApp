import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/repositories/dataset_repository.dart';
import '../../data/repositories/image_override_repository.dart';
import '../../data/repositories/local_dataset_repository.dart';
import '../../data/repositories/profile_repository.dart';
import '../../data/repositories/progress_repository.dart';
import '../../data/repositories/settings_repository.dart';
import '../../data/services/tts_service.dart';
import '../../domain/models/user_profile.dart';

final datasetRepositoryProvider = Provider<DatasetRepository>((ref) {
  return LocalDatasetRepository();
});

final progressRepositoryProvider = Provider<ProgressRepository>((ref) {
  return ProgressRepository();
});

final settingsRepositoryProvider = Provider<SettingsRepository>((ref) {
  return SettingsRepository();
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

final localProfileProvider = Provider<UserProfile>((ref) {
  return ref.read(profileRepositoryProvider).loadProfile();
});

final appStartupProvider = FutureProvider<void>((ref) async {
  final datasetRepository = ref.read(datasetRepositoryProvider);
  final progressRepository = ref.read(progressRepositoryProvider);
  final settingsRepository = ref.read(settingsRepositoryProvider);
  final imageOverrideRepository = ref.read(imageOverrideRepositoryProvider);
  final profileRepository = ref.read(profileRepositoryProvider);
  final ttsService = ref.read(ttsServiceProvider);

  await settingsRepository.init();
  await imageOverrideRepository.init();
  await profileRepository.init();
  await progressRepository.init();
  await datasetRepository.load();
  final imageOverrides = imageOverrideRepository.loadOverrides();
  datasetRepository.setImageOverrides(imageOverrides);
  await ttsService.configure();
});
