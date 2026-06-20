// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'mock_location_service.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(mockLocationService)
final mockLocationServiceProvider = MockLocationServiceProvider._();

final class MockLocationServiceProvider
    extends
        $FunctionalProvider<
          MockLocationService,
          MockLocationService,
          MockLocationService
        >
    with $Provider<MockLocationService> {
  MockLocationServiceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'mockLocationServiceProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$mockLocationServiceHash();

  @$internal
  @override
  $ProviderElement<MockLocationService> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  MockLocationService create(Ref ref) {
    return mockLocationService(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(MockLocationService value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<MockLocationService>(value),
    );
  }
}

String _$mockLocationServiceHash() =>
    r'3d6b5a9e840385a84d3fcc9858ebcb5711d4cec4';
