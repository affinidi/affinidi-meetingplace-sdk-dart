import 'package:didcomm/didcomm.dart';

import '../../core/command/command.dart';
import 'create_oob_output.dart';

/// Model that represents the request sent for the [CreateOobCommand]
/// operation.
class CreateOobCommand extends DiscoveryCommand<CreateOobCommandOutput> {
  /// Creates a new instance of [CreateOobCommand].
  CreateOobCommand({required this.oobInvitationMessage, this.mediatorDid});
  final PlainTextMessage oobInvitationMessage;
  final String? mediatorDid;
}
