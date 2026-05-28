import 'package:ssi/ssi.dart';

/// A signature-verified VRC received over VDIP.
class VrcIssuance {
  /// Creates a [VrcIssuance] with the parsed and verified credential fields.
  VrcIssuance({
    required this.senderDid,
    required this.vcBlob,
    required this.parsedCredential,
    this.credentialFormat,
  });

  /// DID of the peer who issued this VRC.
  final String senderDid;

  /// Raw serialised VC JSON as received over the transport.
  final String vcBlob;

  /// Decoded and signature-verified credential.
  final ParsedVerifiableCredential parsedCredential;

  /// Serialisation format identifier, or `null` if the format could not be
  /// determined from the issuance message.
  final String? credentialFormat;
}
