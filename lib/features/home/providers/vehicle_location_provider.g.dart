// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'vehicle_location_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(VehicleLocation)
final vehicleLocationProvider = VehicleLocationProvider._();

final class VehicleLocationProvider
    extends $NotifierProvider<VehicleLocation, VehicleLocationState> {
  VehicleLocationProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'vehicleLocationProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$vehicleLocationHash();

  @$internal
  @override
  VehicleLocation create() => VehicleLocation();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(VehicleLocationState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<VehicleLocationState>(value),
    );
  }
}

String _$vehicleLocationHash() => r'cfdd0e38b88209fd951c8d1211fb424f289a381b';

abstract class _$VehicleLocation extends $Notifier<VehicleLocationState> {
  VehicleLocationState build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<VehicleLocationState, VehicleLocationState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<VehicleLocationState, VehicleLocationState>,
              VehicleLocationState,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
