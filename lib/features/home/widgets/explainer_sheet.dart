import 'dart:ui';

import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';

class ExplainerSheet extends StatelessWidget {
  const ExplainerSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.45),
      isDismissible: true, // tap outside to close
      enableDrag: true, // swipe down anywhere to close
      showDragHandle: false,
      builder: (context) => const ExplainerSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bottomPadding = MediaQuery.paddingOf(context).bottom;
    final maxHeight = MediaQuery.sizeOf(context).height * 0.9;

    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
        child: ConstrainedBox(
          // Safety net only — sheet hugs content height up to this cap,
          // then scrolls internally if content is ever taller than the screen.
          constraints: BoxConstraints(maxHeight: maxHeight),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: AppColors.darkBg.withValues(alpha: 0.72),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(38),
              ),
              border: Border.all(
                color: AppColors.darkBorder.withValues(alpha: 0.5),
              ),
            ),
            child: SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(24, 12, 24, bottomPadding + 28),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 80,
                      height: 4,
                      margin: const EdgeInsets.only(bottom: 20),
                      decoration: BoxDecoration(
                        color: AppColors.darkBorder.withValues(alpha: 0.9),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  // Row(
                  //   children: [
                  //     Container(
                  //       width: 40,
                  //       height: 40,
                  //       decoration: BoxDecoration(
                  //         color: AppColors.countdownAmber.withValues(
                  //           alpha: 0.12,
                  //         ),
                  //         borderRadius: BorderRadius.circular(12),
                  //         border: Border.all(
                  //           color: AppColors.countdownAmber.withValues(
                  //             alpha: 0.25,
                  //           ),
                  //         ),
                  //       ),
                  //       child: const Icon(
                  //         Icons.help_outline_rounded,
                  //         size: 20,
                  //         color: AppColors.countdownAmber,
                  //       ),
                  //     ),
                  //     const SizedBox(width: 14),
                  //     Expanded(
                  //       child: Column(
                  //         crossAxisAlignment: CrossAxisAlignment.start,
                  //         children: [
                  //           Text(
                  //             'How it works',
                  //             style: theme.textTheme.headlineMedium?.copyWith(
                  //               color: AppColors.darkOnBg,
                  //             ),
                  //           ),
                  //           const SizedBox(height: 2),
                  //           Text(
                  //             'Summon your Tesla from anywhere',
                  //             style: theme.textTheme.bodyMedium?.copyWith(
                  //               color: AppColors.darkSubtext,
                  //             ),
                  //           ),
                  //         ],
                  //       ),
                  //     ),
                  //   ],
                  // ),
                  const SizedBox(height: 8),
                  const _ExplainerStep(
                    step: 1,
                    color: AppColors.accent,
                    icon: Icons.gps_fixed_rounded,
                    title: 'Sync vehicle location',
                    body:
                        'Every 5 seconds we fetch your Tesla\'s real GPS position from the Fleet API.',
                    isLast: false,
                  ),
                  const _ExplainerStep(
                    step: 2,
                    color: AppColors.summonMint,
                    icon: Icons.phone_android_rounded,
                    title: 'Mock your phone\'s GPS',
                    body:
                        'Your phone\'s location is locked to your Tesla via Android mock location — Smart Summon thinks you\'re standing next to the car.',
                    isLast: false,
                  ),
                  const _ExplainerStep(
                    step: 3,
                    color: AppColors.countdownAmber,
                    icon: Icons.directions_car_rounded,
                    title: 'Summon in the Tesla app',
                    body:
                        'When the countdown starts, open the Tesla app and pick a destination on the map to summon to. Do not tap "Come to me" — your phone already appears next to the car.',
                    isLast: false,
                  ),
                  const _ExplainerStep(
                    step: 4,
                    color: AppColors.teslaRed,
                    icon: Icons.timer_rounded,
                    title: '5-minute sessions',
                    body:
                        'Each session runs up to 5 minutes and keeps the app running in the background to keep your mocked location reliable.',
                    isLast: true,
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppColors.darkSurface.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: AppColors.darkBorder.withValues(alpha: 0.5),
                      ),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.info_outline_rounded,
                          size: 20,
                          color: AppColors.darkSubtext.withValues(alpha: 0.9),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Summon will not work on public roads. \nUse responsibly and only where Smart Summon is permitted.',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: AppColors.darkSubtext,
                              height: 1.5,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ExplainerStep extends StatelessWidget {
  const _ExplainerStep({
    required this.step,
    required this.color,
    required this.icon,
    required this.title,
    required this.body,
    required this.isLast,
  });

  final int step;
  final Color color;
  final IconData icon;
  final String title;
  final String body;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 32,
            child: Column(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                    border: Border.all(color: color.withValues(alpha: 0.35)),
                  ),
                  child: Center(
                    child: Text(
                      '$step',
                      style: theme.textTheme.labelLarge?.copyWith(
                        color: color,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
                if (!isLast)
                  Expanded(
                    child: Container(
                      width: 2,
                      margin: const EdgeInsets.symmetric(vertical: 6),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            color.withValues(alpha: 0.35),
                            AppColors.darkBorder.withValues(alpha: 0.2),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(1),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: isLast ? 0 : 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(icon, size: 16, color: color),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          title,
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: AppColors.darkOnBg,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    body,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: AppColors.darkSubtext,
                      height: 1.55,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
