import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/services.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';

import '../../core/logging/app_logger.dart';
import '../../core/services/tesla_api_service.dart';

const _channelName = 'com.summonanywhere/mock_location';

@pragma('vm:entry-point')
void startSummonCallback() {
  AppLogger.info('FOREGROUND', 'startSummonCallback invoked');
  FlutterForegroundTask.setTaskHandler(SummonTaskHandler());
}

class SummonTaskHandler extends TaskHandler {
  Timer? _pollTimer;
  MethodChannel? _channel;
  String? _vehicleId;
  String? _accessToken;
  bool _rateLimited = false;
  int _pollCount = 0;

  @override
  Future<void> onStart(DateTime timestamp, TaskStarter starter) async {
    AppLogger.info('FOREGROUND', 'Task onStart at $timestamp (starter=$starter)');
    await _initialize();
  }

  Future<void> _initialize() async {
    _channel = const MethodChannel(_channelName);
    _vehicleId = await FlutterForegroundTask.getData<String>(key: 'vehicleId');
    _accessToken = await FlutterForegroundTask.getData<String>(key: 'accessToken');

    AppLogger.info(
      'FOREGROUND',
      'Task initialized — vehicleId=$_vehicleId, '
      'accessToken=${AppLogger.maskToken(_accessToken)}',
    );

    try {
      AppLogger.debug('FOREGROUND', 'Enabling mock provider from task handler');
      await _channel!.invokeMethod<void>('enableMockProvider');
      AppLogger.info('FOREGROUND', 'Mock provider enabled');
    } on PlatformException catch (e, st) {
      AppLogger.warn(
        'FOREGROUND',
        'Failed to enable mock provider in task: ${e.message}',
        error: e,
        stackTrace: st,
      );
    }

    _pollTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      unawaited(_pollVehicleLocation());
    });

    unawaited(_pollVehicleLocation());
  }

  Future<void> _pollVehicleLocation() async {
    _pollCount++;
    if (_rateLimited) {
      AppLogger.debug('FOREGROUND', 'Poll #$_pollCount skipped — rate limited');
      return;
    }

    final vehicleId = _vehicleId;
    final channel = _channel;
    final token = _accessToken;
    if (vehicleId == null || channel == null || token == null) {
      AppLogger.warn(
        'FOREGROUND',
        'Poll #$_pollCount skipped — missing vehicleId/channel/token',
      );
      return;
    }

    AppLogger.debug('FOREGROUND', 'Poll #$_pollCount for vehicle $vehicleId');

    try {
      final location = await _fetchLocation(vehicleId, token);
      if (location == null) {
        AppLogger.debug('FOREGROUND', 'Poll #$_pollCount — no location data');
        return;
      }
      if (location.isAsleep) {
        AppLogger.debug('FOREGROUND', 'Poll #$_pollCount — vehicle asleep');
        return;
      }
      if (location.isLocationUnavailable) {
        AppLogger.debug(
          'FOREGROUND',
          'Poll #$_pollCount — vehicle online but location unavailable',
        );
        return;
      }

      AppLogger.debug(
        'FOREGROUND',
        'Poll #$_pollCount — updating mock location: '
        'lat=${location.latitude}, lng=${location.longitude}',
      );
      await channel.invokeMethod<void>('updateLocation', {
        'latitude': location.latitude,
        'longitude': location.longitude,
      });

      FlutterForegroundTask.updateService(
        notificationText:
            'Lat ${location.latitude.toStringAsFixed(5)}, Lng ${location.longitude.toStringAsFixed(5)}',
      );
    } on PlatformException catch (e, st) {
      AppLogger.warn(
        'FOREGROUND',
        'Poll #$_pollCount — mock location update failed',
        error: e,
        stackTrace: st,
      );
    } catch (e, st) {
      if (e is TeslaApiException && e.isRateLimited) {
        AppLogger.warn('FOREGROUND', 'Poll #$_pollCount — rate limited (429)');
        _rateLimited = true;
        Future.delayed(const Duration(seconds: 30), () {
          AppLogger.info('FOREGROUND', 'Rate limit cooldown ended');
          _rateLimited = false;
        });
      } else {
        AppLogger.error(
          'FOREGROUND',
          'Poll #$_pollCount failed',
          error: e,
          stackTrace: st,
        );
      }
    }
  }

  Future<VehicleLocationResult?> _fetchLocation(
    String vehicleId,
    String token,
  ) async {
    final client = _BackgroundTeslaClient(token);
    try {
      return await client.getVehicleLocation(vehicleId);
    } catch (e, st) {
      AppLogger.error(
        'FOREGROUND',
        'Background fetch failed for $vehicleId',
        error: e,
        stackTrace: st,
      );
      return null;
    }
  }

  @override
  void onRepeatEvent(DateTime timestamp) {}

  @override
  Future<void> onDestroy(DateTime timestamp, bool isTimeout) async {
    AppLogger.info(
      'FOREGROUND',
      'Task onDestroy at $timestamp (isTimeout=$isTimeout)',
    );
    _pollTimer?.cancel();
    _pollTimer = null;
    await _disableMock();
  }

  Future<void> _disableMock() async {
    try {
      AppLogger.debug('FOREGROUND', 'Disabling mock provider on task destroy');
      await _channel?.invokeMethod<void>('disableMockProvider');
      AppLogger.info('FOREGROUND', 'Mock provider disabled');
    } on PlatformException catch (e, st) {
      AppLogger.warn(
        'FOREGROUND',
        'Failed to disable mock provider on destroy',
        error: e,
        stackTrace: st,
      );
    }
  }
}

class _BackgroundTeslaClient {
  _BackgroundTeslaClient(this._token);

  final String _token;

  Future<VehicleLocationResult> getVehicleLocation(String vehicleId) async {
    final client = HttpClient();
    final url =
        'https://fleet-api.prd.na.vn.cloud.tesla.com/api/1/vehicles/$vehicleId/vehicle_data?endpoints=location_data%3Bdrive_state';
    AppLogger.debug('FOREGROUND', 'Background GET $url');
    try {
      final uri = Uri.parse(url);
      final request = await client.getUrl(uri);
      request.headers.set('Authorization', 'Bearer $_token');
      final response = await request.close();
      final body = await response.transform(utf8.decoder).join();

      AppLogger.debug(
        'FOREGROUND',
        'Background GET → ${response.statusCode}',
      );

      if (response.statusCode == 429) {
        throw TeslaApiException('Rate limited', statusCode: 429);
      }

      final json = jsonDecode(body) as Map<String, dynamic>;
      final data = json['response'] as Map<String, dynamic>?;

      if (data == null) return VehicleLocationResult.asleep();

      if (data['state'] == 'asleep') {
        return VehicleLocationResult.asleep();
      }

      final coords = _extractVehicleCoords(data);
      final lat = coords?.$1;
      final lng = coords?.$2;

      if (lat == null || lng == null) {
        return VehicleLocationResult.locationUnavailable();
      }

      return VehicleLocationResult(
        latitude: lat,
        longitude: lng,
        isAsleep: false,
      );
    } finally {
      client.close();
    }
  }

  (double, double)? _extractVehicleCoords(Map<String, dynamic> data) {
    for (final source in [
      data['drive_state'],
      data['location_data'],
    ]) {
      if (source is! Map<String, dynamic>) continue;
      final lat = source['latitude'] as num?;
      final lng = source['longitude'] as num?;
      if (lat != null && lng != null) {
        return (lat.toDouble(), lng.toDouble());
      }
    }
    return null;
  }
}
