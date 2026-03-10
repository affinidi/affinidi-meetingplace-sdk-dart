import 'package:meeting_place_chat/meeting_place_chat.dart';

import '../../utils/contact_card_fixture.dart' as fixtures;
import '../../utils/setup_chat_sdk.dart';

class IndividualChatFixture {
  IndividualChatFixture._({required this.setup});

  final SetupChatSdk setup;

  late SDKInstance aliceSDK;
  late SDKInstance bobSDK;

  late MeetingPlaceChatSDK aliceChatSDK;
  late MeetingPlaceChatSDK bobChatSDK;

  static Future<IndividualChatFixture> create({SetupChatSdk? setup}) async {
    final fixture = IndividualChatFixture._(setup: setup ?? SetupChatSdk());

    fixture.aliceSDK = await fixture.setup.createCoreSDK(
      fixtures.ContactCardFixture.alicePrimaryCardInfo,
    );
    fixture.bobSDK = await fixture.setup.createCoreSDK(
      fixtures.ContactCardFixture.bobPrimaryCardInfo,
    );

    fixture.aliceChatSDK = await fixture.setup.createChatSdk(
      sdkInstance: fixture.aliceSDK,
      otherPartySdkInstance: fixture.bobSDK,
    );
    fixture.bobChatSDK = await fixture.setup.createChatSdk(
      sdkInstance: fixture.bobSDK,
      otherPartySdkInstance: fixture.aliceSDK,
    );

    return fixture;
  }

  void dispose() {
    aliceChatSDK.endChatSession();
    bobChatSDK.endChatSession();
  }
}
