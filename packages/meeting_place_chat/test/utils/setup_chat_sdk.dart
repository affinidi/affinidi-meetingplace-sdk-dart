import 'package:meeting_place_chat/meeting_place_chat.dart';
import 'package:meeting_place_core/meeting_place_core.dart';
import 'package:ssi/ssi.dart';

import 'sdk.dart';
import 'storage/storage.dart';

class SDKInstance {
  SDKInstance({
    required this.coreSDK,
    required this.didManager,
    required this.didDocument,
    required this.channelRepository,
    required this.contactCard,
  });

  final MeetingPlaceCoreSDK coreSDK;
  final DidManager didManager;
  final DidDocument didDocument;
  final ChannelRepository channelRepository;
  final ContactCard contactCard;
}

class SetupChatSdk {
  Future<SDKInstance> createCoreSDK(Map<String, dynamic> contactInfo) async {
    final channelRepository = initChannelRepository();
    final coreSDK = await initCoreSDKInstance(
      channelRepository: channelRepository,
    );

    final didManager = await coreSDK.generateDid();
    final didDocument = await didManager.getDidDocument();

    return SDKInstance(
      coreSDK: coreSDK,
      didManager: didManager,
      didDocument: didDocument,
      channelRepository: channelRepository,
      contactCard: ContactCard(
        did: didDocument.id,
        type: 'individual',
        contactInfo: contactInfo,
      ),
    );
  }

  Future<MeetingPlaceChatSDK> createChatSdk({
    required SDKInstance sdkInstance,
    required SDKInstance otherPartySdkInstance,
    Storage? storage,
    ContactCard? card,
    ContactCard? channelCard,
  }) async {
    await sdkInstance.coreSDK.mediator.updateAcl(
      ownerDidManager: sdkInstance.didManager,
      acl: AccessListAdd(
        ownerDid: sdkInstance.didDocument.id,
        granteeDids: [otherPartySdkInstance.didDocument.id],
      ),
    );

    await otherPartySdkInstance.coreSDK.mediator.updateAcl(
      ownerDidManager: otherPartySdkInstance.didManager,
      acl: AccessListAdd(
        ownerDid: otherPartySdkInstance.didDocument.id,
        granteeDids: [sdkInstance.didDocument.id],
      ),
    );

    return initIndividualChatSDK(
      coreSDK: sdkInstance.coreSDK,
      did: sdkInstance.didDocument.id,
      otherPartyDid: otherPartySdkInstance.didDocument.id,
      channelRepository: sdkInstance.channelRepository,
      channelCard: channelCard ?? sdkInstance.contactCard,
      card: card ?? sdkInstance.contactCard,
      otherPartyCard: otherPartySdkInstance.contactCard,
      existingStorage: storage,
    );
  }
}
