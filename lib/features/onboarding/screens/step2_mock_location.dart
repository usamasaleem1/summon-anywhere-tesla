import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/logging/app_logger.dart';
import '../../../core/services/mock_location_service.dart';
import '../../../core/theme/app_colors.dart';
import '../providers/onboarding_provider.dart';

class Step2MockLocation extends ConsumerStatefulWidget {
  const Step2MockLocation({super.key});

  @override
  ConsumerState<Step2MockLocation> createState() => _Step2MockLocationState();
}

class _Step2MockLocationState extends ConsumerState<Step2MockLocation> {
  bool _checking = false;
  bool _mockEnabled = false;

  @override
  void initState() {
    super.initState();
    _checkMockStatus();
  }

  Future<void> _checkMockStatus() async {
    AppLogger.debug('ONBOARDING', 'Step 2: Checking mock location status');
    setState(() => _checking = true);
    final enabled = await ref.read(mockLocationServiceProvider).isEnabled();
    if (!mounted) return;
    AppLogger.info('ONBOARDING', 'Step 2: Mock location enabled=$enabled');
    setState(() {
      _mockEnabled = enabled;
      _checking = false;
    });
  }

  Future<void> _openSettings() async {
    AppLogger.info('ONBOARDING', 'Step 2: Open Developer Settings tapped');
    try {
      await ref.read(mockLocationServiceProvider).openDeveloperSettings();
    } on MockLocationException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message)),
      );
    }
  }

  void _continue() {
    AppLogger.info('ONBOARDING', 'Step 2: Continue tapped (mockEnabled=$_mockEnabled)');
    if (!_mockEnabled) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Enable mock location for Summon Anywhere first.'),
        ),
      );
      return;
    }
    AppLogger.info('ONBOARDING', 'Step 2: Advancing to step 3');
    ref.read(onboardingStepProvider.notifier).next();
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
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 400),
                curve: Curves.easeInOut,
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: (_mockEnabled ? AppColors.summonMint : AppColors.accent)
                      .withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: (_mockEnabled ? AppColors.summonMint : AppColors.accent)
                        .withValues(alpha: 0.25),
                    width: 1,
                  ),
                ),
                child: Icon(
                  _mockEnabled
                      ? Icons.location_on_rounded
                      : Icons.location_searching_rounded,
                  size: 30,
                  color: _mockEnabled ? AppColors.summonMint : AppColors.accent,
                ),
              ),
            ),
            const SizedBox(height: 28),
            Text(
              'Set mock\nlocation app',
              style: theme.textTheme.headlineLarge?.copyWith(
                color: AppColors.darkOnBg,
                height: 1.2,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              'In Developer options, select Summon Anywhere as your mock location app.',
              style: theme.textTheme.bodyLarge?.copyWith(color: AppColors.darkSubtext),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            Center(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                child: _checking
                    ? const SizedBox(
                        key: ValueKey('loading'),
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : _StatusBadge(
                        key: ValueKey(_mockEnabled),
                        enabled: _mockEnabled,
                      ),
              ),
            ),
            const Spacer(flex: 3),
            OutlinedButton.icon(
              onPressed: _openSettings,
              icon: const Icon(Icons.settings_rounded, size: 18),
              label: const Text('Open Developer Settings'),
            ),
            const SizedBox(height: 12),
            FilledButton(
              onPressed: _checking ? null : _continue,
              style: FilledButton.styleFrom(
                backgroundColor:
                    _mockEnabled ? AppColors.summonMint : AppColors.accent,
                foregroundColor: _mockEnabled ? Colors.black : Colors.white,
                disabledBackgroundColor:
                    AppColors.accent.withValues(alpha: 0.4),
              ),
              child: const Text('Continue'),
            ),
            TextButton(
              onPressed: _checking ? null : _checkMockStatus,
              child: const Text('Refresh status'),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({super.key, required this.enabled});
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final color = enabled ? AppColors.summonMint : AppColors.countdownAmber;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(100),
        border: Border.all(color: color.withValues(alpha: 0.3), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 8),
          Text(
            enabled ? 'Mock location active' : 'Not yet enabled',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
