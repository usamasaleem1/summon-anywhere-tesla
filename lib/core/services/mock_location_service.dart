import 'package:flutter/services.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../logging/app_logger.dart';

part 'mock_location_service.g.dart';

const _channelName = 'com.summonanywhere/mock_location';

@Riverpod(keepAlive: true)
MockLocationService mockLocationService(Ref ref) {
  return MockLocationService();
}

class MockLocationService {
  MockLocationService() : _channel = const MethodChannel(_channelName);

  final MethodChannel _channel;

  Future<bool> enableMockProvider() async {
    AppLogger.debug('MOCK_LOCATION', 'invoke enableMockProvider');
    try {
      final result = await _channel.invokeMethod<bool>('enableMockProvider');
      AppLogger.info('MOCK_LOCATION', 'enableMockProvider → $result');
      return result ?? false;
    } on PlatformException catch (e, st) {
      AppLogger.error(
        'MOCK_LOCATION',
        'enableMockProvider PlatformException: code=${e.code}, message=${e.message}',
        error: e,
        stackTrace: st,
      );
      throw MockLocationException(
        e.message ?? 'Failed to enable mock provider',
      );
    }
  }

  Future<void> disableMockProvider() async {
    AppLogger.debug('MOCK_LOCATION', 'invoke disableMockProvider');
    try {
      await _channel.invokeMethod<void>('disableMockProvider');
      AppLogger.info('MOCK_LOCATION', 'disableMockProvider → ok');
    } on PlatformException catch (e, st) {
      AppLogger.error(
        'MOCK_LOCATION',
        'disableMockProvider PlatformException: code=${e.code}',
        error: e,
        stackTrace: st,
      );
      throw MockLocationException(
        e.message ?? 'Failed to disable mock provider',
      );
    }
  }

  Future<void> updateLocation(double latitude, double longitude) async {
    AppLogger.debug(
      'MOCK_LOCATION',
      'invoke updateLocation(lat=$latitude, lng=$longitude)',
    );
    try {
      await _channel.invokeMethod<void>('updateLocation', {
        'latitude': latitude,
        'longitude': longitude,
      });
      AppLogger.debug('MOCK_LOCATION', 'updateLocation → ok');
    } on PlatformException catch (e, st) {
      AppLogger.error(
        'MOCK_LOCATION',
        'updateLocation PlatformException: code=${e.code}',
        error: e,
        stackTrace: st,
      );
      throw MockLocationException(
        e.message ?? 'Failed to update mock location',
      );
    }
  }

  Future<bool> isEnabled() async {
    AppLogger.debug('MOCK_LOCATION', 'invoke isEnabled');
    try {
      final result = await _channel.invokeMethod<bool>('isEnabled');
      AppLogger.debug('MOCK_LOCATION', 'isEnabled → $result');
      return result ?? false;
    } on PlatformException catch (e, st) {
      AppLogger.warn(
        'MOCK_LOCATION',
        'isEnabled PlatformException: code=${e.code} — returning false',
        error: e,
        stackTrace: st,
      );
      return false;
    }
  }

  Future<void> openDeveloperSettings() async {
    AppLogger.debug('MOCK_LOCATION', 'invoke openDeveloperSettings');
    try {
      await _channel.invokeMethod<void>('openDeveloperSettings');
      AppLogger.info('MOCK_LOCATION', 'openDeveloperSettings → ok');
    } on PlatformException catch (e, st) {
      AppLogger.error(
        'MOCK_LOCATION',
        'openDeveloperSettings PlatformException',
        error: e,
        stackTrace: st,
      );
      throw MockLocationException(
        e.message ?? 'Failed to open developer settings',
      );
    }
  }

  Future<void> openBatterySettings() async {
    AppLogger.debug('MOCK_LOCATION', 'invoke openBatterySettings');
    try {
      await _channel.invokeMethod<void>('openBatterySettings');
      AppLogger.info('MOCK_LOCATION', 'openBatterySettings → ok');
    } on PlatformException catch (e, st) {
      AppLogger.error(
        'MOCK_LOCATION',
        'openBatterySettings PlatformException',
        error: e,
        stackTrace: st,
      );
      throw MockLocationException(
        e.message ?? 'Failed to open battery settings',
      );
    }
  }
}

class MockLocationException implements Exception {
  MockLocationException(this.message);
  final String message;

  @override
  String toString() => message;
}
