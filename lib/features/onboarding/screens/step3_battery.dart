import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/logging/app_logger.dart';
import '../../../core/services/mock_location_service.dart';
import '../../../core/theme/app_colors.dart';
import '../providers/onboarding_provider.dart';

class Step3Battery extends ConsumerStatefulWidget {
  const Step3Battery({super.key});

  @override
  ConsumerState<Step3Battery> createState() => _Step3BatteryState();
}

class _Step3BatteryState extends ConsumerState<Step3Battery> {
  bool _completing = false;

  Future<void> _openBatterySettings() async {
    AppLogger.info('ONBOARDING', 'Step 3: Open Battery Settings tapped');
    try {
      await ref.read(mockLocationServiceProvider).openBatterySettings();
    } on MockLocationException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message)),
      );
    }
  }

  Future<void> _finish() async {
    AppLogger.info('ONBOARDING', 'Step 3: Get Started — completing onboarding');
    setState(() => _completing = true);
    await ref.read(onboardingCompleteProvider.notifier).markComplete();
    if (!mounted) return;
    AppLogger.info('ONBOARDING', 'Onboarding complete — navigating to /home');
    context.go('/home');
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return PopScope(
      canPop: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(28, 0, 28, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Spacer(flex: 2),
            Center(
              child: Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: AppColors.summonMint.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: AppColors.summonMint.withValues(alpha: 0.25),
                    width: 1,
                  ),
                ),
                child: const Icon(
                  Icons.battery_charging_full_rounded,
                  size: 30,
                  color: AppColors.summonMint,
                ),
              ),
            ),
            const SizedBox(height: 28),
            Text(
              'One last\nthing',
              style: theme.textTheme.headlineLarge?.copyWith(
                color: AppColors.darkOnBg,
                height: 1.2,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              'Disable battery optimization so location polling stays alive during summon sessions.',
              style: theme.textTheme.bodyLarge?.copyWith(color: AppColors.darkSubtext),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 28),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.darkSurface,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.darkBorder, width: 1),
              ),
              child: Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: AppColors.countdownAmber.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.info_outline_rounded,
                      size: 18,
                      color: AppColors.countdownAmber,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Without this, Android may kill the background service mid-summon.',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: AppColors.darkSubtext,
                        height: 1.5,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const Spacer(flex: 3),
            OutlinedButton.icon(
              onPressed: _openBatterySettings,
              icon: const Icon(Icons.battery_alert_rounded, size: 18),
              label: const Text('Open Battery Settings'),
            ),
            const SizedBox(height: 12),
            FilledButton(
              onPressed: _completing ? null : _finish,
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.summonMint,
                foregroundColor: Colors.black,
                disabledBackgroundColor:
                    AppColors.summonMint.withValues(alpha: 0.4),
              ),
              child: _completing
                  ? const SizedBox(
                      height: 18,
                      width: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.black,
                      ),
                    )
                  : const Text('Get Started'),
            ),
          ],
        ),
      ),
    );
  }
}
