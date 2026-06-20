import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/logging/app_logger.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/theme/app_colors.dart';
import '../providers/onboarding_provider.dart';

class Step1Auth extends ConsumerStatefulWidget {
  const Step1Auth({super.key});

  @override
  ConsumerState<Step1Auth> createState() => _Step1AuthState();
}

class _Step1AuthState extends ConsumerState<Step1Auth> {
  bool _loading = false;
  String? _error;

  Future<void> _signIn() async {
    AppLogger.info('ONBOARDING', 'Step 1: Sign in with Tesla tapped');
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      await ref.read(authServiceProvider).signIn();
      if (!mounted) return;
      AppLogger.info('ONBOARDING', 'Step 1: Sign in succeeded — advancing to step 2');
      ref.read(onboardingStepProvider.notifier).next();
    } on AuthException catch (e) {
      AppLogger.error('ONBOARDING', 'Step 1: AuthException — ${e.message}');
      if (!mounted) return;
      setState(() => _error = e.message);
    } catch (e, st) {
      AppLogger.error('ONBOARDING', 'Step 1: OAuth failed', error: e, stackTrace: st);
      if (!mounted) return;
      setState(() => _error = 'Sign in failed. Please try again.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
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
                color: AppColors.teslaRed.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: AppColors.teslaRed.withValues(alpha: 0.25),
                  width: 1,
                ),
              ),
              child: const Icon(
                Icons.electric_car_rounded,
                size: 30,
                color: AppColors.teslaRed,
              ),
            ),
          ),
          const SizedBox(height: 28),
          Text(
            'Connect your\nTesla',
            style: theme.textTheme.headlineLarge?.copyWith(
              color: AppColors.darkOnBg,
              height: 1.2,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          Text(
            'Sign in to sync your vehicle location for Smart Summon beyond factory limits.',
            style: theme.textTheme.bodyLarge?.copyWith(
              color: AppColors.darkSubtext,
            ),
            textAlign: TextAlign.center,
          ),
          if (_error != null) ...[
            const SizedBox(height: 20),
            _ErrorBanner(message: _error!),
          ],
          const Spacer(flex: 3),
          FilledButton(
            onPressed: _loading ? null : _signIn,
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.accent,
              foregroundColor: Colors.white,
              disabledBackgroundColor: AppColors.accent.withValues(alpha: 0.4),
            ),
            child: _loading
                ? const SizedBox(
                    height: 18,
                    width: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Text('Sign in with Tesla'),
          ),
          const SizedBox(height: 12),
          Text(
            'Your credentials are only used for OAuth and are never stored.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: AppColors.darkSubtext.withValues(alpha: 0.7),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner({required this.message});
  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.errorCoral.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.errorCoral.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.error_outline_rounded,
            size: 16,
            color: AppColors.errorCoral,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.errorCoral,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
