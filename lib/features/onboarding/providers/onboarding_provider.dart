import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/storage/prefs_storage.dart';

part 'onboarding_provider.g.dart';

@riverpod
class OnboardingStep extends _$OnboardingStep {
  @override
  int build() => 0;

  void next() => state = (state + 1).clamp(0, 2);
  void goTo(int step) => state = step.clamp(0, 2);
}

@riverpod
class OnboardingComplete extends _$OnboardingComplete {
  @override
  bool build() => ref.watch(prefsStorageProvider).onboardingComplete;

  Future<void> markComplete() async {
    await ref.read(prefsStorageProvider).setOnboardingComplete(true);
    ref.invalidateSelf();
  }
}
