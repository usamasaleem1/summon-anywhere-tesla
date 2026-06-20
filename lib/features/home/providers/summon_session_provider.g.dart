// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'summon_session_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(SummonSession)
final summonSessionProvider = SummonSessionProvider._();

final class SummonSessionProvider
    extends $NotifierProvider<SummonSession, SummonSessionState> {
  SummonSessionProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'summonSessionProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$summonSessionHash();

  @$internal
  @override
  SummonSession create() => SummonSession();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(SummonSessionState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<SummonSessionState>(value),
    );
  }
}

String _$summonSessionHash() => r'1dd8c1910d9db6cacc462592160062f47345beac';

abstract class _$SummonSession extends $Notifier<SummonSessionState> {
  SummonSessionState build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<SummonSessionState, SummonSessionState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<SummonSessionState, SummonSessionState>,
              SummonSessionState,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
