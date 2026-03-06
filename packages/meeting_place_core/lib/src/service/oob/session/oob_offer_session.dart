import 'package:ssi/ssi.dart';

import '../../../loggers/meeting_place_core_sdk_logger.dart';
import '../../../protocol/protocol.dart';
import '../../core_sdk_stream_subscription.dart';
import '../stream/oob_stream_data.dart';

/// Represents an active OOB offer session, created when starting an OOB flow
/// as the offerer.
class OobOfferSession {
  /// Creates an [OobOfferSession] with the given parameters.
  OobOfferSession({
    required this.didManager,
    required this.didDocument,
    required this.oobInvitationMessage,
    required this.oobUrl,
    required this.contactCard,
    required this.mediatorDid,
    required this.stream,
    required MeetingPlaceCoreSDKLogger logger,
  });

  /// The DID manager used for the connection setup.
  final DidManager didManager;

  /// The DID Document associated with the OOB offer.
  final DidDocument didDocument;

  /// The OOB invitation message that is encapsulated in the OOB payload.
  final OobInvitationMessage oobInvitationMessage;

  /// The OOB stream that emits events related to the OOB session,
  /// such as acceptance by the invitee.
  final CoreSDKStreamSubscription<OobStreamData, void> stream;

  /// The OOB URL that can be shared with the invitee to accept the OOB offer.
  final Uri oobUrl;

  /// The contact card information of the offerer, which are included in the
  /// OOB invitation.
  final ContactCard contactCard;

  /// The DID of the mediator that is used for the connection setup.
  final String mediatorDid;
}
