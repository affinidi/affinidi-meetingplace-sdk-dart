/// Transport selected by the offer publisher. The value is the
/// lowercase `name` of the enum and is forwarded verbatim to the control
/// plane and surfaced back to the acceptor via QueryOffer.
enum OfferTransport {
  didcomm,
  matrix;

  /// Returns the wire string representation.
  String get value => name;

  /// Parses the string back into an [OfferTransport]. Throws
  /// [ArgumentError] if [value] is not a known transport.
  static OfferTransport fromString(String value) {
    return OfferTransport.values.firstWhere(
      (t) => t.value == value,
      orElse: () =>
          throw ArgumentError.value(value, 'value', 'Unknown OfferTransport'),
    );
  }
}
