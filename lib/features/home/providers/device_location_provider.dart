import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/services/device_location_service.dart';

part 'device_location_provider.g.dart';

@riverpod
Future<DeviceLocation?> deviceLocation(Ref ref) {
  return ref.read(deviceLocationServiceProvider).getCurrentLocation();
}
