import 'package:didcomm/didcomm.dart';

import '../../core/command/command.dart';
import 'create_oob_output.dart';

/// Model that represents the request sent for the [CreateOobCommand]
/// operation.
class CreateOobCommand extends DiscoveryCommand<CreateOobCommandOutput> {
  /// Creates a new instance of [CreateOobCommand].
  CreateOobCommand({
    required this.oobInvitationMessage,
    required this.mediatorDid,
  });

  /// The out-of-band invitation message to publish.
  final PlainTextMessage oobInvitationMessage;

  /// The DID of the mediator the invitation is published through.
  final String mediatorDid;
}
