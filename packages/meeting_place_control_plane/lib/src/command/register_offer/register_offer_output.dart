import 'package:didcomm/didcomm.dart';

/// Model that represents the output data returned from a successful execution
/// of [RegisterOfferCommandOutput] operation.
class RegisterOfferCommandOutput {
  /// Creates a new instance of [RegisterOfferCommandOutput].
  RegisterOfferCommandOutput({
    required this.mediatorDid,
    required this.offerName,
    required this.offerLink,
    required this.mnemonic,
    required this.didcommMessage,
    required this.expiresAt,
    required this.maximumUsage,
    this.offerDescription,
  });
  final String mediatorDid;
  final String offerName;
  final String offerLink;
  final String mnemonic;
  final PlainTextMessage didcommMessage;
  final DateTime? expiresAt;
  final int? maximumUsage;
  final String? offerDescription;
}
