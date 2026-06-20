// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'device_location_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(deviceLocation)
final deviceLocationProvider = DeviceLocationProvider._();

final class DeviceLocationProvider
    extends
        $FunctionalProvider<
          AsyncValue<DeviceLocation?>,
          DeviceLocation?,
          FutureOr<DeviceLocation?>
        >
    with $FutureModifier<DeviceLocation?>, $FutureProvider<DeviceLocation?> {
  DeviceLocationProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'deviceLocationProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$deviceLocationHash();

  @$internal
  @override
  $FutureProviderElement<DeviceLocation?> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<DeviceLocation?> create(Ref ref) {
    return deviceLocation(ref);
  }
}

String _$deviceLocationHash() => r'84dccc3b4532d63e8afeb779f1eaff4a3eac99a1';
