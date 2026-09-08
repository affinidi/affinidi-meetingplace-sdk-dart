import 'package:didcomm/didcomm.dart';

import '../../core/command/command.dart';
import 'create_direct_connection_invitation_result.dart';

/// Model that represents the request sent for the [CreateOobRequest]
/// operation.
class CreateOobRequest
    extends DiscoveryCommand<CreateDirectConnectionInvitationResult> {
  /// Creates a new instance of [CreateOobRequest].
  CreateOobRequest({
    required this.oobInvitationMessage,
    required this.mediatorDid,
  });

  /// The out-of-band invitation message to publish.
  final PlainTextMessage oobInvitationMessage;

  /// The DID of the mediator the invitation is published through.
  final String mediatorDid;
}
