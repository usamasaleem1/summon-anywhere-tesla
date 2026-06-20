import 'package:geolocator/geolocator.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../logging/app_logger.dart';

part 'device_location_service.g.dart';

@Riverpod(keepAlive: true)
DeviceLocationService deviceLocationService(Ref ref) {
  return DeviceLocationService();
}

class DeviceLocation {
  const DeviceLocation({required this.latitude, required this.longitude});

  final double latitude;
  final double longitude;
}

class DeviceLocationService {
  Future<DeviceLocation?> getCurrentLocation() async {
    AppLogger.debug('DEVICE_LOCATION', 'Requesting current device location…');

    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      AppLogger.warn('DEVICE_LOCATION', 'Location services disabled');
      return null;
    }

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      AppLogger.warn('DEVICE_LOCATION', 'Location permission denied');
      return null;
    }

    try {
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 10),
        ),
      );
      AppLogger.info(
        'DEVICE_LOCATION',
        'Got device location: lat=${position.latitude}, lng=${position.longitude}',
      );
      return DeviceLocation(
        latitude: position.latitude,
        longitude: position.longitude,
      );
    } catch (e, st) {
      AppLogger.error(
        'DEVICE_LOCATION',
        'Failed to get device location',
        error: e,
        stackTrace: st,
      );
      return null;
    }
  }
}
