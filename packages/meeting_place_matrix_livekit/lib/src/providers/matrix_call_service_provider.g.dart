// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'matrix_call_service_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// [MatrixCallService] instance for the current plugin session.
///
/// Override in tests to return a mock without requiring a real Matrix session.

@ProviderFor(matrixCallService)
const matrixCallServiceProvider = MatrixCallServiceProvider._();

/// [MatrixCallService] instance for the current plugin session.
///
/// Override in tests to return a mock without requiring a real Matrix session.

final class MatrixCallServiceProvider
    extends
        $FunctionalProvider<
          MatrixCallService,
          MatrixCallService,
          MatrixCallService
        >
    with $Provider<MatrixCallService> {
  /// [MatrixCallService] instance for the current plugin session.
  ///
  /// Override in tests to return a mock without requiring a real Matrix session.
  const MatrixCallServiceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'matrixCallServiceProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$matrixCallServiceHash();

  @$internal
  @override
  $ProviderElement<MatrixCallService> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  MatrixCallService create(Ref ref) {
    return matrixCallService(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(MatrixCallService value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<MatrixCallService>(value),
    );
  }
}

String _$matrixCallServiceHash() => r'ad1063d8a5ed9ea5f4c1fb57db2f90caac8bca44';
