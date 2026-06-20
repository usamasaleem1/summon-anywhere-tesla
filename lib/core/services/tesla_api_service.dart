import 'package:dio/dio.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../logging/app_logger.dart';
import 'auth_service.dart';

part 'tesla_api_service.g.dart';

@Riverpod(keepAlive: true)
TeslaApiService teslaApiService(Ref ref) {
  return TeslaApiService(ref.watch(authServiceProvider));
}

class TeslaApiService {
  TeslaApiService(this._authService);

  final AuthService _authService;

  static const _baseUrl = 'https://fleet-api.prd.na.vn.cloud.tesla.com';

  Dio _dio(String token) => Dio(
    BaseOptions(
      baseUrl: _baseUrl,
      headers: {'Authorization': 'Bearer $token'},
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 15),
    ),
  );

  Future<String> _token() async {
    AppLogger.debug('TESLA_API', 'Resolving valid access token…');
    final token = await _authService.getValidAccessToken();
    if (token == null) {
      AppLogger.warn('TESLA_API', 'Not authenticated — no valid token');
      throw TeslaApiException('Not authenticated', statusCode: 401);
    }
    AppLogger.debug('TESLA_API', 'Using token ${AppLogger.maskToken(token)}');
    return token;
  }

  Future<List<TeslaVehicle>> getVehicles() async {
    const path = '/api/1/vehicles';
    AppLogger.info('TESLA_API', 'GET $_baseUrl$path');
    final dio = _dio(await _token());
    try {
      final response = await dio.get<Map<String, dynamic>>(path);
      AppLogger.info('TESLA_API', 'GET $path → ${response.statusCode}');
      final list = response.data?['response'] as List<dynamic>? ?? [];
      AppLogger.debug('TESLA_API', 'Vehicles count: ${list.length}');
      return list
          .map((v) => TeslaVehicle.fromJson(v as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      final body = e.response?.data;
      AppLogger.error(
        'TESLA_API',
        'GET $path failed: status=${e.response?.statusCode}, body=$body',
        error: e,
      );
      throw _mapDioError(e);
    }
  }

  Future<VehicleLocationResult> getVehicleLocation(String vehicleId) async {
    final path = '/api/1/vehicles/$vehicleId/vehicle_data';
    const query = 'endpoints=location_data;drive_state';
    AppLogger.debug('TESLA_API', 'GET $_baseUrl$path?$query');
    final dio = _dio(await _token());
    try {
      final response = await dio.get<Map<String, dynamic>>(
        path,
        queryParameters: {'endpoints': 'location_data;drive_state'},
      );
      AppLogger.debug('TESLA_API', 'GET $path → ${response.statusCode}');
      final data = response.data?['response'] as Map<String, dynamic>?;
      if (data == null) {
        AppLogger.warn(
          'TESLA_API',
          'Empty vehicle data response for $vehicleId',
        );
        throw TeslaApiException('Empty vehicle data response');
      }

      final state = data['state'] as String?;
      AppLogger.debug('TESLA_API', 'Vehicle $vehicleId state: $state');
      if (state == 'asleep') {
        AppLogger.info('TESLA_API', 'Vehicle $vehicleId is asleep');
        return VehicleLocationResult.asleep();
      }

      final coords = _extractVehicleCoords(data);
      final lat = coords?.$1;
      final lng = coords?.$2;

      if (lat == null || lng == null) {
        AppLogger.info(
          'TESLA_API',
          'Vehicle $vehicleId is online but has no location coords '
          '(check vehicle_location scope / re-sign in)',
        );
        return VehicleLocationResult.locationUnavailable();
      }

      AppLogger.debug(
        'TESLA_API',
        'Vehicle $vehicleId location: lat=$lat, lng=$lng',
      );
      return VehicleLocationResult(
        latitude: lat.toDouble(),
        longitude: lng.toDouble(),
        isAsleep: false,
      );
    } on DioException catch (e) {
      if (e.response?.statusCode == 408) {
        AppLogger.info(
          'TESLA_API',
          'Vehicle $vehicleId unavailable (408) — treating as asleep',
        );
        return VehicleLocationResult.asleep();
      }
      final body = e.response?.data;
      AppLogger.error(
        'TESLA_API',
        'GET $path failed: status=${e.response?.statusCode}, body=$body',
        error: e,
      );
      throw _mapDioError(e);
    }
  }

  /// Tesla returns lat/lng in [drive_state] when [location_data] is requested.
  /// On firmware 2023.38+ they are omitted unless location_data is in endpoints.
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

  TeslaApiException _mapDioError(DioException e) {
    final code = e.response?.statusCode;
    final teslaError = _parseTeslaErrorBody(e.response?.data);

    if (code == 429) {
      AppLogger.warn('TESLA_API', 'Rate limited (429)');
      return TeslaApiException('Rate limited', statusCode: 429);
    }
    if (code == 412) {
      AppLogger.warn(
        'TESLA_API',
        'Precondition failed (412) — partner account not registered in this region',
      );
      return TeslaApiException(
        teslaError ??
            'Fleet API is not registered for this region. '
                'Complete Tesla partner registration (POST /api/1/partner_accounts) '
                'for fleet-api.prd.na.vn.cloud.tesla.com.',
        statusCode: 412,
      );
    }
    if (code == 421) {
      AppLogger.warn('TESLA_API', 'Incorrect region (421)');
      return TeslaApiException(
        teslaError ??
            'Your Tesla account is in a different region. '
                'Update the Fleet API base URL to match your account region (EU, NA, etc.).',
        statusCode: 421,
      );
    }

    return TeslaApiException(
      teslaError ?? e.message ?? 'Tesla API error',
      statusCode: code,
    );
  }

  String? _parseTeslaErrorBody(dynamic data) {
    if (data is! Map) return null;
    final error = data['error'] as String?;
    final description = data['error_description'] as String?;
    if (error != null && description != null) return '$error: $description';
    return description ?? error ?? data['message'] as String?;
  }
}

class TeslaVehicle {
  TeslaVehicle({
    required this.id,
    required this.vin,
    required this.displayName,
    required this.state,
  });

  factory TeslaVehicle.fromJson(Map<String, dynamic> json) {
    return TeslaVehicle(
      id: json['id']?.toString() ?? json['id_s'] as String? ?? '',
      vin: json['vin'] as String? ?? '',
      displayName: json['display_name'] as String? ?? 'Tesla',
      state: json['state'] as String? ?? 'unknown',
    );
  }

  final String id;
  final String vin;
  final String displayName;
  final String state;

  bool get isAsleep => state == 'asleep';
}

class VehicleLocationResult {
  const VehicleLocationResult({
    required this.latitude,
    required this.longitude,
    required this.isAsleep,
    this.isLocationUnavailable = false,
  });

  factory VehicleLocationResult.asleep() =>
      const VehicleLocationResult(latitude: 0, longitude: 0, isAsleep: true);

  factory VehicleLocationResult.locationUnavailable() =>
      const VehicleLocationResult(
        latitude: 0,
        longitude: 0,
        isAsleep: false,
        isLocationUnavailable: true,
      );

  final double latitude;
  final double longitude;
  final bool isAsleep;
  final bool isLocationUnavailable;
}

class TeslaApiException implements Exception {
  TeslaApiException(this.message, {this.statusCode});

  final String message;
  final int? statusCode;

  bool get isRateLimited => statusCode == 429;

  @override
  String toString() => message;
}
