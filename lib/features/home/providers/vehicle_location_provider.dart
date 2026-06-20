import 'dart:async';

import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/logging/app_logger.dart';
import '../../../core/services/tesla_api_service.dart';
import '../../../core/storage/prefs_storage.dart';

part 'vehicle_location_provider.g.dart';

class VehicleLocationState {
  const VehicleLocationState({
    this.latitude,
    this.longitude,
    this.isLoading = false,
    this.isAsleep = false,
    this.error,
    this.isRateLimited = false,
  });

  final double? latitude;
  final double? longitude;
  final bool isLoading;
  final bool isAsleep;
  final String? error;
  final bool isRateLimited;

  VehicleLocationState copyWith({
    double? latitude,
    double? longitude,
    bool? isLoading,
    bool? isAsleep,
    String? error,
    bool? isRateLimited,
    bool clearError = false,
  }) {
    return VehicleLocationState(
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      isLoading: isLoading ?? this.isLoading,
      isAsleep: isAsleep ?? this.isAsleep,
      error: clearError ? null : (error ?? this.error),
      isRateLimited: isRateLimited ?? this.isRateLimited,
    );
  }
}

@riverpod
class VehicleLocation extends _$VehicleLocation {
  String? _vehicleId;

  @override
  VehicleLocationState build() {
    ref.onDispose(() {
      AppLogger.debug('VEHICLE', 'VehicleLocation provider disposed');
    });

    _vehicleId = ref.read(prefsStorageProvider).selectedVehicleId;
    AppLogger.info(
      'VEHICLE',
      'VehicleLocation provider built — selectedVehicleId=$_vehicleId',
    );
    Future.microtask(refresh);
    return const VehicleLocationState(isLoading: true);
  }

  Future<void> refresh() async {
    if (state.isRateLimited) {
      AppLogger.debug('VEHICLE', 'Refresh skipped — rate limited');
      return;
    }

    AppLogger.debug('VEHICLE', 'Refreshing vehicle location…');
    state = state.copyWith(isLoading: true, clearError: true);

    try {
      final api = ref.read(teslaApiServiceProvider);
      var vehicleId = _vehicleId;

      if (vehicleId == null || vehicleId.isEmpty) {
        AppLogger.debug('VEHICLE', 'No vehicle ID — fetching vehicle list');
        final vehicles = await api.getVehicles();
        if (vehicles.isEmpty) {
          AppLogger.warn('VEHICLE', 'No vehicles found on account');
          state = state.copyWith(
            isLoading: false,
            error: 'No vehicles found on your account.',
          );
          return;
        }
        vehicleId = vehicles.first.id;
        _vehicleId = vehicleId;
        AppLogger.info(
          'VEHICLE',
          'Auto-selected vehicle: ${vehicles.first.displayName} ($vehicleId)',
        );
        await ref.read(prefsStorageProvider).setSelectedVehicleId(vehicleId);
      }

      final result = await api.getVehicleLocation(vehicleId);

      if (result.isAsleep) {
        AppLogger.info('VEHICLE', 'Fetch result: vehicle asleep');
        state = state.copyWith(
          isLoading: false,
          isAsleep: true,
          clearError: true,
        );
        return;
      }

      if (result.isLocationUnavailable) {
        AppLogger.info('VEHICLE', 'Fetch result: location unavailable');
        state = state.copyWith(
          isLoading: false,
          isAsleep: false,
          error:
              'Vehicle location unavailable. Sign out and sign in again to grant location access.',
        );
        return;
      }

      AppLogger.info(
        'VEHICLE',
        'Fetch result: lat=${result.latitude}, lng=${result.longitude}',
      );
      state = VehicleLocationState(
        latitude: result.latitude,
        longitude: result.longitude,
        isLoading: false,
        isAsleep: false,
      );
    } on TeslaApiException catch (e) {
      if (e.isRateLimited) {
        AppLogger.warn('VEHICLE', 'Rate limited');
        state = state.copyWith(
          isLoading: false,
          isRateLimited: true,
          error: 'Rate limited — try again later',
        );
      } else {
        AppLogger.error('VEHICLE', 'Tesla API error: ${e.message}');
        state = state.copyWith(isLoading: false, error: e.message);
      }
    } catch (e, st) {
      AppLogger.error(
        'VEHICLE',
        'Failed to fetch vehicle location',
        error: e,
        stackTrace: st,
      );
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to fetch vehicle location.',
      );
    }
  }
}
