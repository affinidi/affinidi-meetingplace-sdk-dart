import 'dart:async';

import '../../core/command/command_handler.dart';
import '../../core/mediator/mediator_service.dart';
import '../../protocol/message/oob_invitation_message.dart';
import 'get_oob.dart';
import 'get_oob_output.dart';

class GetOobHandler
    implements MediatorCommandHandler<GetOobCommand, GetOobOutput> {
  GetOobHandler({required MediatorService mediatorService})
      : _mediatorService = mediatorService;
  final MediatorService _mediatorService;

  @override
  Future<GetOobOutput> handle(GetOobCommand command) async {
    final oobMessageBase64 = await _mediatorService.getOob(command.oobUrl);

    return GetOobOutput(
      oobInvitationMessage: oobMessageBase64 == null
          ? null
          : OobInvitationMessage.fromBase64(oobMessageBase64),
    );
  }
}
