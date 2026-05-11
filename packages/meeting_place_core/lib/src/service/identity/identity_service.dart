import 'package:meeting_place_control_plane/meeting_place_control_plane.dart';
import 'package:ssi/ssi.dart';

import '../../../meeting_place_core.dart';
import '../connection_manager/connection_manager.dart';
import 'model/ephemeral_identity.dart';
import 'model/permanent_identity.dart';

class IdentityService {
  IdentityService({
    required ControlPlaneSDK controlPlaneSDK,
    required ConnectionManager connectionManager,
    required MatrixService matrixService,
    MeetingPlaceCoreSDKLogger? logger,
  }) : _connectionManager = connectionManager,
       _controlPlaneSDK = controlPlaneSDK,
       _matrixService = matrixService,
       _logger =
           logger ?? DefaultMeetingPlaceCoreSDKLogger(className: _className);

  final ConnectionManager _connectionManager;
  final ControlPlaneSDK _controlPlaneSDK;
  final MatrixService _matrixService;
  final MeetingPlaceCoreSDKLogger _logger;

  static const String _className = 'IdentityService';
  static const String _logkey = 'IdentityService';

  Future<EphemeralIdentity> createEphemeralIdentity(Wallet wallet) async {
    final ephemeralDidManager = await _connectionManager.generateDid(wallet);
    final didDocument = await ephemeralDidManager.getDidDocument();

    _logger.info(
      'Created ephemeral identity with DID ${didDocument.id}',
      name: _logkey,
    );

    return EphemeralIdentity(
      didManager: ephemeralDidManager,
      didDocument: didDocument,
    );
  }

  Future<PermanentIdentity> createPermanentIdentity(Wallet wallet) async {
    final permanentChannelDidManager = await _connectionManager.generateDid(
      wallet,
    );

    final matrixTokenCommandOutput = await _controlPlaneSDK.execute(
      MatrixTokenCommand(
        didManager: permanentChannelDidManager,
        homeserver: _matrixService.homeserver,
      ),
    );

    final matrixUserId = await _matrixService.loginWithJwt(
      jwt: matrixTokenCommandOutput.token.toJwt(),
      userScope: matrixTokenCommandOutput.token.sub,
    );

    final didDocument = await permanentChannelDidManager.getDidDocument();

    _logger.info(
      '''Created permanent identity with DID ${didDocument.id} and Matrix user ID $matrixUserId''',
      name: _logkey,
    );

    return PermanentIdentity(
      didManager: permanentChannelDidManager,
      didDocument: didDocument,
      matrixUserId: matrixUserId,
      userScope: matrixTokenCommandOutput.token.sub,
    );
  }
}
