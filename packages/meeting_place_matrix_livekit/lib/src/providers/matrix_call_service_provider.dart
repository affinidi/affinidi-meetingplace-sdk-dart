import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../services/matrix_call_service.dart';

part 'matrix_call_service_provider.g.dart';

/// [MatrixCallService] instance for the current plugin session.
///
/// Always overridden via [matrixCallServiceProvider.overrideWithValue] in
/// [MeetingPlaceLiveKitCallPlugin._buildContainer].
@riverpod
MatrixCallService matrixCallService(Ref ref) {
  throw UnimplementedError(
    'matrixCallServiceProvider must be overridden with an initialized '
    'MatrixCallService instance.',
  );
}
