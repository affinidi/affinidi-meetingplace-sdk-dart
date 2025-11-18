import 'package:ssi/ssi.dart';

import '../../protocol/message/oob_invitation_message.dart';

class CreateOobResult {
  CreateOobResult({
    required this.invitationMessage,
    required this.invitationMessageDidManager,
  });
  final OobInvitationMessage invitationMessage;
  final DidManager invitationMessageDidManager;
}
