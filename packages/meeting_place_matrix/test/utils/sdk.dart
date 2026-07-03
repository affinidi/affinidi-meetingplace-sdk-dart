import 'dart:io';

import 'package:dotenv/dotenv.dart';
import 'package:meeting_place_core/meeting_place_core.dart';
import 'package:meeting_place_matrix/meeting_place_matrix.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:ssi/ssi.dart';
import 'package:uuid/uuid.dart';
import 'package:vodozemac/vodozemac.dart' as vod;

import 'repository/channel_repository_impl.dart';
import 'repository/chat_repository_impl.dart';
import 'repository/connection_group_offer_repository_impl.dart';
import 'repository/connection_offer_repository_impl.dart';
import 'repository/key_repository_impl.dart';
import 'storage/in_memory_storage.dart';
import 'storage/storage.dart';

final env = DotEnv(includePlatformEnvironment: true)..load(['test/.env']);

Uri getMatrixHomeserver() =>
    switch (Platform.environment['MATRIX_HOMESERVER'] ??
    env['MATRIX_HOMESERVER']) {
      final s? => Uri.parse(s),
      _ => throw Exception('MATRIX_HOMESERVER not set in environment'),
    };

String getVodozemacLibraryPath() {
  final override =
      Platform.environment['VODOZEMAC_LIBRARY_PATH'] ??
      env['VODOZEMAC_LIBRARY_PATH'];
  if (override != null) return override;
  if (Platform.isMacOS) return 'test/libvodozemac_bindings_dart.dylib';
  if (Platform.isLinux) return 'test/libvodozemac_bindings_dart.so';
  throw Exception(
    'No bundled vodozemac binary for ${Platform.operatingSystem}; '
    'set VODOZEMAC_LIBRARY_PATH',
  );
}

/// Ensures the vodozemac native library is loaded before any Matrix client is
/// created. The CoreSDK now requires this (matrix E2EE is on by default), so
/// every integration test that spins up an SDK must initialize it first.
Future<void> ensureVodozemacInitialized() async {
  if (vod.isInitialized()) return;
  await vod.init(libraryPath: getVodozemacLibraryPath());
}

Future<DatabaseApi> _openMatrixDatabase(
  Directory directory,
  MatrixDatabaseContext context,
) async {
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;
  await directory.create(recursive: true);
  return MatrixSdkDatabase.init(
    context.databaseName,
    database: await databaseFactoryFfi.openDatabase(
      '${directory.path}/${context.databaseName}.sqlite',
    ),
  );
}

MatrixConfig getMatrixConfig() {
  final directory = Directory.systemTemp.createTempSync(
    'meeting_place_chat_test_matrix_',
  );
  return MatrixConfig(
    mediatorDid: getMediatorDid(),
    controlPlaneDid: getControlPlaneDid(),
    homeserver: getMatrixHomeserver(),
    databaseFactory: CallbackMatrixDatabaseFactory(
      openDatabase: (context) => _openMatrixDatabase(directory, context),
    ),
    deviceId: const Uuid().v4(),
  );
}

Future<MeetingPlaceMatrixSDK> initCoreSDKInstance({
  Wallet? wallet,
  GroupRepository? groupRepository,
  ChannelRepository? channelRepository,
}) async {
  await ensureVodozemacInitialized();
  final storage = InMemoryStorage();
  final sdk = await MeetingPlaceMatrixSDK.create(
    wallet: wallet ?? PersistentWallet(InMemoryKeyStore()),
    repositoryConfig: RepositoryConfig(
      connectionOfferRepository: ConnectionOfferRepositoryImpl(
        storage: storage,
      ),
      groupRepository: groupRepository ?? GroupRepositoryImpl(storage: storage),
      keyRepository: KeyRepositoryImpl(storage: storage),
      channelRepository:
          channelRepository ?? ChannelRepositoryImpl(storage: storage),
    ),
    config: getMatrixConfig(),
  );

  await sdk.registerForPushNotifications(const Uuid().v4());
  return sdk;
}

ChannelRepository initChannelRepository() {
  return ChannelRepositoryImpl(storage: InMemoryStorage());
}

/// Waits until the Matrix room is ready for encrypted messaging between
/// [localDid] and all [expectedDids]. Test-only; production code does not
/// need this synchronisation step because natural latency hides the race.
Future<void> waitForRoomEncryptionReady(
  MeetingPlaceMatrixSDK sdk, {
  required String localDid,
  required Iterable<String> expectedDids,
  Duration timeout = const Duration(seconds: 15),
}) async {
  final channel = await sdk.findChannelByDid(localDid);
  final didManager = await sdk.getDidManager(localDid);
  final roomId = await sdk.matrixService.resolveRoomIdForChannel(
    didManager: didManager,
    channel: channel,
  );
  await sdk.matrixService.waitForRoomEncryptionReady(
    roomId: roomId,
    didManager: didManager,
    expectedDids: expectedDids,
    timeout: timeout,
  );
}

Future<MeetingPlaceChatSDK> initIndividualChatSDK({
  required MeetingPlaceCoreSDK coreSDK,
  required String did,
  required String otherPartyDid,
  required ChannelRepository channelRepository,
  ContactCard? card,
  ContactCard? otherPartyCard,
  ContactCard? channelCard,
  Storage? existingStorage,
  MeetingPlaceChatSDKOptions? options,
}) async {
  final storage = existingStorage ?? InMemoryStorage();
  final channel = Channel(
    offerLink: const Uuid().v4(),
    publishOfferDid: '',
    mediatorDid: getMediatorDid(),
    status: ChannelStatus.inaugurated,
    contactCard: channelCard,
    otherPartyContactCard: otherPartyCard,
    type: ChannelType.individual,
    isConnectionInitiator: false,
    permanentChannelDid: did,
    otherPartyPermanentChannelDid: otherPartyDid,
  );

  await channelRepository.createChannel(channel);

  return IndividualMatrixChatSDK(
    coreSDK: coreSDK,
    did: did,
    otherPartyDid: otherPartyDid,
    card: card,
    mediatorDid: getMediatorDid(),
    chatRepository: ChatRepositoryImpl(storage: storage),
    options:
        options ??
        MeetingPlaceChatSDKOptions(
          chatPresenceSendInterval: const Duration(seconds: 3),
        ),
  );
}

Future<MeetingPlaceChatSDK> initGroupChatSDK({
  required MeetingPlaceCoreSDK coreSDK,
  required String did,
  required String otherPartyDid,
  required Group group,
  required ChannelRepository channelRepository,
  ContactCard? card,
  Storage? existingStorage,
}) async {
  final storage = existingStorage ?? InMemoryStorage();
  final channel = Channel(
    offerLink: group.offerLink,
    publishOfferDid: '',
    mediatorDid: getMediatorDid(),
    status: ChannelStatus.inaugurated,
    contactCard: card,
    type: ChannelType.group,
    isConnectionInitiator: false,
    permanentChannelDid: did,
    otherPartyPermanentChannelDid: otherPartyDid,
  );

  await channelRepository.createChannel(channel);

  return GroupMatrixChatSDK(
    coreSDK: coreSDK,
    group: group,
    did: did,
    otherPartyDid: otherPartyDid,
    mediatorDid: getMediatorDid(),
    card: card,
    chatRepository: ChatRepositoryImpl(storage: storage),
    options: MeetingPlaceChatSDKOptions(
      chatPresenceSendInterval: const Duration(seconds: 3),
    ),
  );
}

String getControlPlaneDid() =>
    Platform.environment['CONTROL_PLANE_DID'] ??
    env['CONTROL_PLANE_DID'] ??
    (throw Exception('CONTROL_PLANE_DID not set in environment'));

String getMediatorDid() =>
    Platform.environment['MEDIATOR_DID'] ??
    env['MEDIATOR_DID'] ??
    (throw Exception('MEDIATOR_DID not set in environment'));
