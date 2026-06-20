import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/logging/app_logger.dart';
import '../../../core/theme/app_colors.dart';
import '../providers/summon_session_provider.dart';

class SummonButton extends ConsumerStatefulWidget {
  const SummonButton({super.key});

  @override
  ConsumerState<SummonButton> createState() => _SummonButtonState();
}

class _SummonButtonState extends ConsumerState<SummonButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulseController;
  late final Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    );
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.04).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  String _formatDuration(Duration d) {
    final minutes = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  Future<void> _toggleSummon() async {
    final session = ref.read(summonSessionProvider);
    if (session.isActive) {
      AppLogger.info('HOME', 'Summon button tapped — stopping session');
      await ref.read(summonSessionProvider.notifier).stop();
      _pulseController.stop();
      _pulseController.value = 0; // snaps scale back to 1.0, only while idle
      return;
    }
    AppLogger.info('HOME', 'Summon button tapped — starting session');
    final started = await ref.read(summonSessionProvider.notifier).start();
    if (!mounted) return;
    if (started) {
      AppLogger.info('HOME', 'Summon session started');
      _pulseController.repeat(
        reverse: true,
      ); // only pulses while active, always starts from the same phase
    } else {
      final error = ref.read(summonSessionProvider).error;
      AppLogger.warn('HOME', 'Summon session failed: $error');
      if (error != null) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(error)));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(summonSessionProvider);
    final isActive = session.isActive;
    final accentColor = isActive
        ? AppColors.countdownAmber
        : AppColors.summonMint;
    final contentColor = isActive
        ? AppColors.countdownAmber
        : AppColors.darkOnBg;
    final borderRadius = BorderRadius.circular(100);

    return GestureDetector(
      onTap: _toggleSummon,
      child: AnimatedBuilder(
        // Only the scale needs to rebuild per pulse tick.
        animation: _pulseController,
        builder: (context, child) => Transform.scale(
          scale: isActive ? _pulseAnimation.value : 1.0,
          child: child,
        ),
        child: ClipRRect(
          borderRadius: borderRadius,
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeInOut,
              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
              decoration: BoxDecoration(
                borderRadius: borderRadius,
                color: AppColors.darkBg.withValues(alpha: 0.3),
                border: Border.all(
                  color: isActive
                      ? accentColor.withValues(alpha: 0.5)
                      : const Color.fromARGB(36, 42, 42, 54),
                  width: isActive ? 2 : 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: isActive
                        ? accentColor.withValues(alpha: 0.3)
                        : Colors.black.withValues(alpha: 0.1),
                    blurRadius: isActive ? 32 : 12,
                    spreadRadius: isActive ? 4 : 0,
                  ),
                ],
              ),
              // Smoothly resizes when content size changes (icon swap,
              // text length, font size) instead of snapping.
              child: AnimatedSize(
                duration: const Duration(milliseconds: 250),
                curve: Curves.easeInOut,
                alignment: Alignment.center,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 200),
                      child: Icon(
                        key: ValueKey(isActive),
                        isActive ? Icons.stop_rounded : Icons.near_me_rounded,
                        color: contentColor,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 10),
                    // Interpolates font size / letter spacing / color
                    // smoothly instead of jumping on switch.
                    AnimatedDefaultTextStyle(
                      duration: const Duration(milliseconds: 250),
                      curve: Curves.easeInOut,
                      style: GoogleFonts.inter(
                        color: contentColor,
                        fontWeight: FontWeight.w600,
                        fontSize: isActive ? 18 : 16,
                        letterSpacing: isActive ? 1 : 1.5,
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 400),
                        child: Text(
                          key: ValueKey(isActive),
                          isActive
                              ? _formatDuration(session.remaining)
                              : 'SUMMON',
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
