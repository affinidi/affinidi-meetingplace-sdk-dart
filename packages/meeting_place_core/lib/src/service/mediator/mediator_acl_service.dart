import 'package:meeting_place_mediator/meeting_place_mediator.dart';
import 'package:ssi/ssi.dart';

import '../../entity/channel.dart';
import '../../loggers/meeting_place_core_sdk_logger.dart';
import '../connection_manager/connection_manager.dart';

class MediatorAclService {
  MediatorAclService({
    required MeetingPlaceMediatorSDK mediatorSDK,
    required ConnectionManager connectionManager,
    required MeetingPlaceCoreSDKLogger logger,
  }) : _mediatorSDK = mediatorSDK,
       _connectionManager = connectionManager,
       _logger = logger;

  final MeetingPlaceMediatorSDK _mediatorSDK;
  final ConnectionManager _connectionManager;
  final MeetingPlaceCoreSDKLogger _logger;

  Future<void> toPublic({
    required DidManager didManager,
    required String? mediatorDid,
  }) async {
    final didDocument = await didManager.getDidDocument();
    await _mediatorSDK.updateAcl(
      ownerDidManager: didManager,
      mediatorDid: mediatorDid,
      acl: AclSet.toPublic(ownerDid: didDocument.id),
    );
  }

  Future<void> addToAcl({
    required DidManager didManager,
    required String? mediatorDid,
    required List<String> granteeDids,
  }) async {
    final didDocument = await didManager.getDidDocument();
    await _mediatorSDK.updateAcl(
      ownerDidManager: didManager,
      mediatorDid: mediatorDid,
      acl: AccessListAdd(ownerDid: didDocument.id, granteeDids: granteeDids),
    );
  }

  Future<void> removePermissionFromChannel({
    required Wallet wallet,
    required Channel channel,
  }) async {
    final permanentChannelDid = channel.permanentChannelDid;
    final otherPartyPermanentChannelDid = channel.otherPartyPermanentChannelDid;

    if (permanentChannelDid == null || otherPartyPermanentChannelDid == null) {
      return;
    }

    final didManager = await _connectionManager.getDidManagerForDid(
      wallet,
      permanentChannelDid,
    );

    try {
      await _mediatorSDK.updateAcl(
        ownerDidManager: didManager,
        mediatorDid: channel.mediatorDid,
        acl: AccessListRemove(
          ownerDid: permanentChannelDid,
          granteeDids: [otherPartyPermanentChannelDid],
        ),
      );
    } on MeetingPlaceMediatorSDKException catch (e, stackTrace) {
      if (e.innerException is SsiException &&
          (e.innerException as SsiException).code ==
              SsiExceptionType.invalidDidWeb.code) {
        _logger.error(
          '''Failed to remove permission to get messages from channel: ${channel.id}. Continue without removing permission due to invalid did:web mediator DID.''',
          error: e,
          name: '_removePermissionToGetMessagesFromChannel',
        );
        return;
      }
      Error.throwWithStackTrace(e, stackTrace);
    } catch (e, stackTrace) {
      Error.throwWithStackTrace(e, stackTrace);
    }
  }
}
