import '../../entity/connection_offer.dart';

/// Parameters for `MeetingPlaceCoreSDK.sendOutreachInvitation`.
class SendOutreachInvitationRequest {
  const SendOutreachInvitationRequest({
    required this.outreachConnectionOffer,
    required this.inviteToConnectionOffer,
    required this.messageToInclude,
    required this.senderInfo,
  });

  /// The connection offer that receives the outreach notification.
  final ConnectionOffer outreachConnectionOffer;

  /// The connection offer the invitation refers to.
  final ConnectionOffer inviteToConnectionOffer;

  /// Message to include in the DIDComm message.
  final String messageToInclude;

  /// Information about the sender to include in the invitation.
  final String senderInfo;
}
