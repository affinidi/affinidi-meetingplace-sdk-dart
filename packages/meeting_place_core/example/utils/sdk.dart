import 'dart:io';
import 'package:dotenv/dotenv.dart';
import 'package:meeting_place_core/meeting_place_core.dart';
import 'package:ssi/ssi.dart';
import 'repository/channel_repository_impl.dart';
import 'repository/connection_group_offer_repository_impl.dart';
import 'repository/connection_offer_repository_impl.dart';
import 'repository/key_repository_impl.dart';
import 'storage.dart';

final env = DotEnv(includePlatformEnvironment: true)..load(['.env']);

String getControlPlaneDid() =>
    Platform.environment['CONTROL_PLANE_DID'] ??
    env['CONTROL_PLANE_DID'] ??
    (throw Exception('CONTROL_PLANE_DID not set in environment'));

String getMediatorDid() =>
    Platform.environment['MEDIATOR_DID'] ??
    env['MEDIATOR_DID'] ??
    (throw Exception('MEDIATOR_DID not set in environment'));

String getVodozemacLibraryPath() {
  final override = Platform.environment['VODOZEMAC_LIBRARY_PATH'] ??
      env['VODOZEMAC_LIBRARY_PATH'];
  if (override != null) return override;
  if (Platform.isMacOS) return 'example/libvodozemac_bindings_dart.dylib';
  if (Platform.isLinux) return 'example/libvodozemac_bindings_dart.so';
  throw Exception(
    'No bundled vodozemac binary for ${Platform.operatingSystem}; '
    'set VODOZEMAC_LIBRARY_PATH',
  );
}

Config getConfig() => Config(
      mediatorDid: getMediatorDid(),
      controlPlaneDid: getControlPlaneDid(),
    );

RepositoryConfig getRepositoryConfig() {
  final storage = InMemoryStorage();
  return RepositoryConfig(
    connectionOfferRepository: ConnectionOfferRepositoryImpl(storage: storage),
    groupRepository: GroupRepositoryImpl(storage: storage),
    channelRepository: ChannelRepositoryImpl(storage: storage),
    keyRepository: KeyRepositoryImpl(storage: storage),
  );
}

Future<MeetingPlaceCoreSDK> initSDK({required Wallet wallet}) async {
  return MeetingPlaceCoreSDK.create(
    wallet: wallet,
    repositoryConfig: getRepositoryConfig(),
    config: getConfig(),
    logger: DefaultMeetingPlaceCoreSDKLogger(),
  );
}
