import '../../protocol/message/oob_invitation_message/oob_invitation_message.dart';
import 'package:ssi/ssi.dart';

class CreateOobResult {
  CreateOobResult({
    required this.invitationMessage,
    required this.invitationMessageDidManager,
  });
  final OobInvitationMessage invitationMessage;
  final DidManager invitationMessageDidManager;
}
