import 'package:didcomm/didcomm.dart';
import 'package:meeting_place_control_plane/meeting_place_control_plane.dart';
import 'package:meeting_place_mediator/meeting_place_mediator.dart';
import 'package:ssi/ssi.dart';

import '../../entity/connection_offer.dart';
import '../../protocol/message/outreach_invitation.dart';
import '../../utils/string.dart';
import '../connection_manager/connection_manager.dart';

class OutreachService {
  OutreachService({
    required MeetingPlaceMediatorSDK mediatorSDK,
    required ControlPlaneSDK controlPlaneSDK,
    required ConnectionManager connectionManager,
    required DidResolver didResolver,
  })  : _mediatorSDK = mediatorSDK,
        _controlPlaneSDK = controlPlaneSDK,
        _connectionManager = connectionManager,
        _didResolver = didResolver;

  final MeetingPlaceMediatorSDK _mediatorSDK;
  final ControlPlaneSDK _controlPlaneSDK;
  final ConnectionManager _connectionManager;
  final DidResolver _didResolver;

  Future<void> sendOutreachInvitation({
    required Wallet wallet,
    required ConnectionOffer outreachConnectionOffer,
    required ConnectionOffer inviteToConnectionOffer,
    required String messageToInclude,
    required String senderInfo,
  }) async {
    final message = PlainTextMessage.fromJson(
      fromBase64(outreachConnectionOffer.oobInvitationMessage),
    );

    final outreachInvitation = OutreachInvitation.create(
      from: inviteToConnectionOffer.publishOfferDid,
      to: [message.from!],
      mnemonic: inviteToConnectionOffer.mnemonic,
      message: messageToInclude,
    );

    final senderDidManager = await _connectionManager.getDidManagerForDid(
      wallet,
      inviteToConnectionOffer.publishOfferDid,
    );

    await _mediatorSDK.sendMessage(
      outreachInvitation,
      senderDidManager: senderDidManager,
      recipientDidDocument: await _didResolver.resolveDid(message.from!),
    );

    await _controlPlaneSDK.execute(
      NotifyOutreachCommand(
        mnemonic: outreachConnectionOffer.mnemonic,
        senderInfo: senderInfo,
      ),
    );
  }
}
