import 'package:ssi/ssi.dart';

import '../../core/command/command.dart';
import 'oob_invitation_message_output.dart';

class OobInvitationMessageCommand
    implements MediatorCommand<OobInvitationMessageOutput> {
  OobInvitationMessageCommand({
    required this.mediatorDid,
    required this.oobDidManager,
  });
  final DidManager oobDidManager;
  final String mediatorDid;
}
