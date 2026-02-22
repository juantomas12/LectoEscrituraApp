import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/providers/app_providers.dart';
import '../../domain/models/app_settings.dart';
import '../../domain/models/difficulty.dart';

class SettingsViewModel extends Notifier<AppSettings> {
  @override
  AppSettings build() {
    final repository = ref.read(settingsRepositoryProvider);
    final loaded = repository.loadSettings();
    return loaded;
  }

  Future<void> _save(AppSettings next) async {
    state = next;
    await ref.read(settingsRepositoryProvider).saveSettings(next);
  }

  Future<void> setAudioEnabled(bool value) {
    return _save(state.copyWith(audioEnabled: value));
  }

  Future<void> setHighContrast(bool value) {
    return _save(state.copyWith(highContrast: value));
  }

  Future<void> setDyslexiaMode(bool value) {
    return _save(state.copyWith(dyslexiaMode: value));
  }

  Future<void> setAccentTolerance(bool value) {
    return _save(state.copyWith(accentTolerance: value));
  }

  Future<void> setShowHints(bool value) {
    return _save(state.copyWith(showHints: value));
  }

  Future<void> setDifficulty(Difficulty value) {
    return _save(state.copyWith(defaultDifficulty: value));
  }

  Future<void> setUnlockThreshold(int value) {
    return _save(state.copyWith(unlockThreshold: value));
  }

  Future<void> setAutoAdjustLevel(bool value) {
    return _save(state.copyWith(autoAdjustLevel: value));
  }

  Future<void> setOpenAiApiKey(String value) {
    return _save(state.copyWith(openAiApiKey: value.trim()));
  }

  Future<void> setOpenAiModel(String value) {
    return _save(state.copyWith(openAiModel: value.trim()));
  }
}

final settingsViewModelProvider =
    NotifierProvider<SettingsViewModel, AppSettings>(SettingsViewModel.new);
