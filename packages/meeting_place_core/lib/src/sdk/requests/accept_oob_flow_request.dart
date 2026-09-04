import 'package:didcomm/didcomm.dart' show Attachment;

import '../../protocol/contact_card/contact_card.dart';

/// Parameters for `MeetingPlaceCoreSDK.acceptOobFlow`.
class AcceptOobFlowRequest {
  const AcceptOobFlowRequest({
    required this.oobUrl,
    required this.contactCard,
    this.type,
    this.externalRef,
    this.did,
    this.attachments,
  });

  /// The OOB URL being accepted.
  final Uri oobUrl;

  /// An object that contains information about who is accepting the offer.
  /// This helps others know whom they are connecting with and provides
  /// necessary contact details.
  final ContactCard contactCard;

  /// Type of the out-of-band invitation.
  final String? type;

  /// Application-specific data that is passed through to internal oob
  /// entity and can be referenced later for tracking or identification
  /// purposes. [externalRef] is accessible on the current device only.
  final String? externalRef;

  /// If specified, this DID is used as the permanent channel DID within the
  /// channel entity. If omitted, a new DID will be generated automatically.
  final String? did;

  /// Optional list of attachments (e.g., R-Card credentials) to include in
  /// the invitation acceptance message.
  final List<Attachment>? attachments;
}
