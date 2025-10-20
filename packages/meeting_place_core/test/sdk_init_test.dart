import 'package:meeting_place_control_plane/meeting_place_control_plane.dart';
import 'package:meeting_place_core/meeting_place_core.dart';
import 'package:ssi/ssi.dart';
import 'package:test/test.dart';
import 'package:uuid/uuid.dart';

import 'utils/repository/channel_repository_impl.dart';
import 'utils/repository/connection_offer_repository_impl.dart';
import 'utils/repository/key_repository_impl.dart';
import 'utils/sdk.dart';
import 'utils/storage/in_memory_storage.dart';

void main() async {
  final aliceSDK = await initSDKInstance();

  test(
    '''Verify that an exception is thrown when using the SDK without registering the device.''',
    () async {
      final sdkWithoutDevice = await initSDKInstance(withoutDevice: true);

      expect(
        () => sdkWithoutDevice.publishOffer(
          offerName: 'Test offer',
          vCard: VCard(values: {}),
          type: SDKConnectionOfferType.invitation,
        ),
        throwsA(isA<MissingDeviceException>()),
      );
    },
  );

  test(
    'Ensure repeated device registration is allowed and handled gracefully',
    () async {
      final tokenA = Uuid().v4();
      final tokenB = Uuid().v4();
      await aliceSDK.registerForPushNotifications(tokenA);
      await aliceSDK.registerForPushNotifications(tokenA);
      await aliceSDK.registerForPushNotifications(tokenB);
    },
  );

  test(
    '''Ensure SDK methods dependent on device registration work correctly after the device is registered''',
    () async {
      await aliceSDK.registerForPushNotifications(Uuid().v4());
      await aliceSDK.publishOffer(
        offerName: 'Test offer',
        vCard: VCard(values: {}),
        type: SDKConnectionOfferType.invitation,
      );
    },
  );

  test('multiple authenticate calls possible', () async {
    await aliceSDK.discovery.execute(
      AuthenticateCommand(controlPlaneDid: getControlPlaneDid()),
    );

    final result = await aliceSDK.discovery.execute(
      AuthenticateCommand(controlPlaneDid: getControlPlaneDid()),
    );

    expect(result.credentials, isA<AuthCredentials>());
  });

  test('SDK can be initialized with minimum required repositories', () async {
    final storage = InMemoryStorage();
    final minimumSDK = await MeetingPlaceCoreSDK.create(
      wallet: PersistentWallet(InMemoryKeyStore()),
      repositoryConfig: RepositoryConfig(
        connectionOfferRepository: ConnectionOfferRepositoryImpl(
          storage: storage,
        ),
        channelRepository: ChannelRepositoryImpl(storage: storage),
        keyRepository: KeyRepositoryImpl(storage: storage),
      ),
      mediatorDid: getMediatorDid(),
      controlPlaneDid: getControlPlaneDid(),
    );

    await minimumSDK.registerForPushNotifications(Uuid().v4());

    expect(
      () => minimumSDK.publishOffer(
        offerName: 'Test offer',
        vCard: VCard(values: {}),
        type: SDKConnectionOfferType.groupInvitation,
      ),
      throwsA(isA<UnimplementedError>()),
    );
  });
}
