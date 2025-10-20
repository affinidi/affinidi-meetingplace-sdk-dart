import '../../core/exception/control_plane_exception.dart';

/// QueryOfferExceptionCodes enum definitions.
enum QueryOfferExceptionCodes {
  generic('discovery_query_offer_generic');

  const QueryOfferExceptionCodes(this.code);
  final String code;
}

/// A concrete implementation of the [ControlPlaneException] interface for throwing
/// specific exceptions related to Query Offer command/operation.
class QueryOfferException implements ControlPlaneException {
  QueryOfferException._({
    required this.message,
    required this.code,
    this.innerException,
  });

  /// Creates a `generic` [QueryOfferException] instance.
  ///
  /// This constructor provides the specific message, error code and the actual
  /// exception encountered in the operation.
  ///
  /// **Parameters:**
  /// - [innerException]: The exception object.
  factory QueryOfferException.generic({Object? innerException}) {
    return QueryOfferException._(
      message: 'Query offer exception: ${innerException.toString()}.',
      code: QueryOfferExceptionCodes.generic,
      innerException: innerException,
    );
  }
  @override
  final String message;

  final QueryOfferExceptionCodes code;

  @override
  final Object? innerException;

  @override
  String get errorCode => code.code;
}
