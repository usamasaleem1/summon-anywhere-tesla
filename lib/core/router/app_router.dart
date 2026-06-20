import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../logging/app_logger.dart';
import '../../features/home/screens/home_screen.dart';
import '../../features/onboarding/providers/onboarding_provider.dart';
import '../../features/onboarding/screens/onboarding_shell.dart';

part 'app_router.g.dart';

@Riverpod(keepAlive: true)
GoRouter appRouter(Ref ref) {
  AppLogger.debug('ROUTER', 'Building GoRouter');
  return GoRouter(
    initialLocation: '/onboarding',
    routes: [
      GoRoute(
        path: '/onboarding',
        builder: (context, state) => const OnboardingShell(),
      ),
      GoRoute(
        path: '/home',
        builder: (context, state) => const HomeScreen(),
      ),
    ],
    redirect: (context, state) {
      final complete = ref.read(onboardingCompleteProvider);
      final onOnboarding = state.matchedLocation == '/onboarding';

      if (!complete && !onOnboarding) {
        AppLogger.debug(
          'ROUTER',
          'Redirect ${state.matchedLocation} → /onboarding (incomplete)',
        );
        return '/onboarding';
      }
      if (complete && onOnboarding) {
        AppLogger.debug(
          'ROUTER',
          'Redirect /onboarding → /home (already complete)',
        );
        return '/home';
      }
      AppLogger.debug('ROUTER', 'No redirect for ${state.matchedLocation}');
      return null;
    },
    refreshListenable: _RouterRefresh(ref),
  );
}

class _RouterRefresh extends ChangeNotifier {
  _RouterRefresh(this._ref) {
    _ref.listen(onboardingCompleteProvider, (previous, next) {
      AppLogger.info(
        'ROUTER',
        'onboardingComplete changed: $previous → $next',
      );
      notifyListeners();
    });
  }

  final Ref _ref;
}
