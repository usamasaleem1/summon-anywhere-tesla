import 'package:flutter/material.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/logging/app_logger.dart';
import 'core/router/app_router.dart';
import 'core/services/auth_service.dart';
import 'core/storage/prefs_storage.dart';
import 'core/theme/app_theme.dart';

Future<void> main() async {
  AppLogger.info('STARTUP', 'Summon Anywhere starting…');
  WidgetsFlutterBinding.ensureInitialized();

  FlutterForegroundTask.init(
    androidNotificationOptions: AndroidNotificationOptions(
      channelId: 'summon_anywhere_channel',
      channelName: 'Summon Anywhere',
      channelDescription: 'Vehicle GPS sync foreground service',
      channelImportance: NotificationChannelImportance.LOW,
      priority: NotificationPriority.LOW,
    ),
    iosNotificationOptions: const IOSNotificationOptions(
      showNotification: true,
      playSound: false,
    ),
    foregroundTaskOptions: ForegroundTaskOptions(
      eventAction: ForegroundTaskEventAction.nothing(),
      autoRunOnBoot: false,
      allowWakeLock: true,
      allowWifiLock: true,
    ),
  );
  AppLogger.debug('STARTUP', 'Foreground task initialized');

  AuthService.logOAuthConfigSummary();

  final prefs = await PrefsStorage.create();
  AppLogger.info(
    'STARTUP',
    'Prefs loaded — onboardingComplete=${prefs.onboardingComplete}',
  );

  runApp(
    ProviderScope(
      overrides: [
        prefsStorageProvider.overrideWithValue(prefs),
      ],
      child: const SummonAnywhereApp(),
    ),
  );
  AppLogger.info('STARTUP', 'runApp called');
}

class SummonAnywhereApp extends ConsumerWidget {
  const SummonAnywhereApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);

    return WithForegroundTask(
      child: MaterialApp.router(
        title: 'Summon Anywhere',
        theme: AppTheme.light(),
        darkTheme: AppTheme.dark(),
        themeMode: ThemeMode.dark,
        routerConfig: router,
      ),
    );
  }
}
