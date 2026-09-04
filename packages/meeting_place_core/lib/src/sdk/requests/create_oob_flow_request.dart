import '../../protocol/contact_card/contact_card.dart';

/// Parameters for `MeetingPlaceCoreSDK.createOobFlow`.
class CreateOobFlowRequest {
  const CreateOobFlowRequest({
    required this.contactCard,
    this.type,
    this.did,
    this.mediatorDid,
    this.externalRef,
  });

  /// An object that contains information about who is offering the offer.
  /// This helps others know whom they are connecting with and provides
  /// necessary contact details.
  final ContactCard contactCard;

  /// Type of the out-of-band invitation.
  final String? type;

  /// If specified, this DID is used as the permanent channel DID within the
  /// channel entity. If omitted, a new DID will be generated automatically.
  final String? did;

  /// The mediator's DID. If not provided, the SDK will use the mediator DID
  /// configured in the current instance.
  final String? mediatorDid;

  /// Application-specific data that is passed through to internal oob
  /// entity and can be referenced later for tracking or identification
  /// purposes. [externalRef] is accessible on the current device only.
  final String? externalRef;
}
