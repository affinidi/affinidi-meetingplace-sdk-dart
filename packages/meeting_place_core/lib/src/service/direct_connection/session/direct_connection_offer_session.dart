import 'package:ssi/ssi.dart';

import '../../../protocol/protocol.dart';
import '../../core_sdk_stream_subscription.dart';
import '../stream/direct_connection_stream_data.dart';

/// Represents an active direct connection offer session, created when
/// starting a direct connection as the offerer.
class DirectConnectionOfferSession {
  /// Creates a [DirectConnectionOfferSession] with the given parameters.
  DirectConnectionOfferSession({
    required this.didManager,
    required this.didDocument,
    required this.oobInvitationMessage,
    required this.directConnectionUrl,
    required this.contactCard,
    required this.mediatorDid,
    required this.stream,
  });

  /// The DID manager used for the connection setup.
  final DidManager didManager;

  /// The DID Document associated with the direct connection offer.
  final DidDocument didDocument;

  /// The out-of-band invitation message that is encapsulated in the direct
  /// connection payload.
  final OobInvitationMessage oobInvitationMessage;

  /// The direct connection stream that emits events related to the session,
  /// such as acceptance by the invitee.
  final CoreSDKStreamSubscription<DirectConnectionStreamData, void> stream;

  /// The URL that can be shared with the invitee to accept the direct
  /// connection offer.
  final Uri directConnectionUrl;

  /// The contact card information of the offerer, which are included in the
  /// invitation.
  final ContactCard contactCard;

  /// The DID of the mediator that is used for the connection setup.
  final String mediatorDid;
}
