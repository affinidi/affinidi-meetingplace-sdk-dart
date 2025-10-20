import 'dart:async';
import 'package:ssi/ssi.dart';

import '../../acl/methods/acl_set.dart';
import '../../core/command/command_handler.dart';
import '../../core/mediator/mediator_service.dart';
import '../../utils/mediator_utils.dart';
import 'oob_invitation_message.dart';
import 'oob_invitation_message_output.dart';

class OobInvitationMessageHandler
    implements
        MediatorCommandHandler<OobInvitationMessageCommand,
            OobInvitationMessageOutput> {
  OobInvitationMessageHandler({
    required MediatorService mediatorService,
    required DidResolver didResolver,
  })  : _mediatorService = mediatorService,
        _didResolver = didResolver;
  final MediatorService _mediatorService;
  final DidResolver _didResolver;

  @override
  Future<OobInvitationMessageOutput> handle(
    OobInvitationMessageCommand command,
  ) async {
    final didDocument = await command.oobDidManager.getDidDocument();

    final oobId = await _mediatorService.createOob(
      command.oobDidManager,
      command.mediatorDid,
    );

    await _mediatorService.updateAcl(
      ownerDidManager: command.oobDidManager,
      mediatorDid: command.mediatorDid,
      acl: AclSet.toPublic(ownerDid: didDocument.id),
    );

    return OobInvitationMessageOutput(
      oobId: oobId,
      oobUrl: await _getOobUrl(oobId, command.mediatorDid),
    );
  }

  Future<Uri> _getOobUrl(String oobId, String mediatorDid) async {
    final mediatorEndpoint = await MediatorUtils.getMediatorEndpointByDid(
      mediatorDid,
      didResolver: _didResolver,
    );

    return Uri.parse('$mediatorEndpoint/oob?_oobid=$oobId');
  }
}
