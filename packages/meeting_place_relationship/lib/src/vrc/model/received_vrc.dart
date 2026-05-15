import 'package:ssi/ssi.dart';

/// A signature-verified VRC received over VDIP.
class ReceivedVrc {
  ReceivedVrc({
    required this.senderDid,
    required this.vcBlob,
    required this.parsedCredential,
    this.credentialFormat,
  });

  final String senderDid;
  final String vcBlob;
  final ParsedVerifiableCredential parsedCredential;
  final String? credentialFormat;
}
