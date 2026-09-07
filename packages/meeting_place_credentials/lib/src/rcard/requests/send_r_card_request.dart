import 'package:meeting_place_core/meeting_place_core.dart';

import '../model/r_card_subject.dart';

/// Parameters for `MeetingPlaceCredentialsSDK.sendRCard`.
class SendRCardRequest {
  const SendRCardRequest({
    required this.channel,
    required this.subjectDid,
    required this.card,
    required this.issuerDidManager,
  });

  /// The established channel to the contact the R-Card is sent to.
  final Channel channel;

  /// The DID of the subject the R-Card describes.
  final String subjectDid;

  /// The R-Card subject data to sign and deliver.
  final RCardSubject card;

  /// The DID manager used to sign the R-Card as issuer.
  final DidManager issuerDidManager;
}
