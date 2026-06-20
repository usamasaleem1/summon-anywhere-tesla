// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'tesla_api_service.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(teslaApiService)
final teslaApiServiceProvider = TeslaApiServiceProvider._();

final class TeslaApiServiceProvider
    extends
        $FunctionalProvider<TeslaApiService, TeslaApiService, TeslaApiService>
    with $Provider<TeslaApiService> {
  TeslaApiServiceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'teslaApiServiceProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$teslaApiServiceHash();

  @$internal
  @override
  $ProviderElement<TeslaApiService> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  TeslaApiService create(Ref ref) {
    return teslaApiService(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(TeslaApiService value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<TeslaApiService>(value),
    );
  }
}

String _$teslaApiServiceHash() => r'5c4c5d02b65f9120d61268ead1cbb08e1d1d1a6c';
