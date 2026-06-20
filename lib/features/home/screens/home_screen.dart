import 'dart:ui';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/logging/app_logger.dart';
import '../../../core/services/device_location_service.dart';
import '../../../core/services/mock_location_service.dart';
import '../../../core/theme/app_colors.dart';
import '../providers/device_location_provider.dart';
import '../providers/vehicle_location_provider.dart';
import '../widgets/explainer_sheet.dart';
import '../widgets/summon_button.dart';
import '../widgets/vehicle_map.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  bool _offline = false;

  @override
  void initState() {
    super.initState();
    AppLogger.info('HOME', 'HomeScreen mounted');
    _listenConnectivity();
    _checkMockLocation();
  }

  void _listenConnectivity() {
    Connectivity().onConnectivityChanged.listen((results) {
      if (!mounted) return;
      final offline = results.every((r) => r == ConnectivityResult.none);
      if (offline != _offline) {
        AppLogger.warn('HOME', 'Connectivity changed — offline=$offline');
      }
      setState(() => _offline = offline);
    });
    Connectivity().checkConnectivity().then((results) {
      if (!mounted) return;
      final offline = results.every((r) => r == ConnectivityResult.none);
      AppLogger.debug('HOME', 'Initial connectivity — offline=$offline');
      setState(() => _offline = offline);
    });
  }

  Future<void> _checkMockLocation() async {
    final enabled = await ref.read(mockLocationServiceProvider).isEnabled();
    if (!mounted) return;
    AppLogger.info('HOME', 'Mock location check — enabled=$enabled');
    if (!enabled) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Mock location is disabled. Summon sessions may fail.'),
          duration: Duration(seconds: 5),
        ),
      );
    }
  }

  void _recenterToDevice() {
    ref.read(deviceLocationServiceProvider).getCurrentLocation().then((
      location,
    ) {
      if (location != null && context.mounted) {
        ref.read(vehicleLocationProvider.notifier).refresh();
      }
    });
  }

  Widget _buildMap(
    VehicleLocationState vehicle,
    AsyncValue<DeviceLocation?> device,
  ) {
    final hasVehicle = vehicle.latitude != null && vehicle.longitude != null;

    if (hasVehicle) {
      return VehicleMap(
        latitude: vehicle.latitude!,
        longitude: vehicle.longitude!,
        vehicleLatitude: vehicle.latitude,
        vehicleLongitude: vehicle.longitude,
      );
    }

    return device.when(
      data: (location) {
        if (location == null) {
          return const ColoredBox(
            color: AppColors.darkBg,
            child: Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text(
                  'Enable location access to show the map while your vehicle is unavailable.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppColors.darkSubtext),
                ),
              ),
            ),
          );
        }
        return VehicleMap(
          latitude: location.latitude,
          longitude: location.longitude,
        );
      },
      loading: () => const ColoredBox(
        color: AppColors.darkBg,
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (_, _) => const ColoredBox(
        color: AppColors.darkBg,
        child: Center(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Text(
              'Could not load your location.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.darkSubtext),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final location = ref.watch(vehicleLocationProvider);
    final deviceLocation = ref.watch(deviceLocationProvider);
    final theme = Theme.of(context);

    return Scaffold(
      body: Stack(
        children: [
          _buildMap(location, deviceLocation),

          // Offline banner
          if (_offline)
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: SafeArea(
                bottom: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.errorCoral.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: AppColors.errorCoral.withValues(alpha: 0.3),
                            width: 1,
                          ),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.wifi_off_rounded,
                              color: AppColors.errorCoral,
                              size: 16,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'No internet connection',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: AppColors.errorCoral,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),

          // Locate me button
          Positioned(
            bottom: 100 + MediaQuery.of(context).padding.bottom,
            right: 20,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                child: GestureDetector(
                  onTap: _recenterToDevice,
                  child: Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: AppColors.darkBg.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppColors.darkBorder, width: 1),
                    ),
                    child: const Icon(
                      Icons.my_location_rounded,
                      size: 20,
                      color: AppColors.darkOnBg,
                    ),
                  ),
                ),
              ),
            ),
          ),

          // Top overlay + status + summon button
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  // Frosted-glass pill header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(100),
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
                          child: GestureDetector(
                            onTap: () => ExplainerSheet.show(context),
                            behavior: HitTestBehavior.opaque,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 26,
                                vertical: 14,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.darkBg.withValues(alpha: 0.10),
                                borderRadius: BorderRadius.circular(100),
                                border: Border.all(
                                  color: AppColors.darkBorder,
                                  width: 1,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.3),
                                    blurRadius: 20,
                                    spreadRadius: 0,
                                  ),
                                ],
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    'How does it work?',
                                    style: theme.textTheme.titleMedium
                                        ?.copyWith(color: AppColors.darkOnBg),
                                  ),
                                  const SizedBox(width: 8),
                                  const Icon(
                                    Icons.help_outline_rounded,
                                    size: 16,
                                    color: AppColors.countdownAmber,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),

                  // Status badges
                  if (location.isAsleep)
                    const _StatusChip(
                      label: 'Vehicle Asleep',
                      icon: Icons.bedtime_rounded,
                      color: AppColors.countdownAmber,
                    ),
                  if (location.error != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: _StatusChip(
                        label: location.error!,
                        icon: Icons.error_outline_rounded,
                        color: AppColors.errorCoral,
                      ),
                    ),

                  const Spacer(),
                  const SummonButton(),
                  const SizedBox(height: 12),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({
    required this.label,
    required this.icon,
    required this.color,
  });

  final String label;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(100),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(100),
            border: Border.all(color: color.withValues(alpha: 0.25), width: 1),
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
                label,
                style: TextStyle(
                  fontSize: 13,
                  color: color,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
