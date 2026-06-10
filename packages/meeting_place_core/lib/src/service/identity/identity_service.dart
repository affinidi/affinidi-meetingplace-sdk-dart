import 'package:ssi/ssi.dart';

import '../../../meeting_place_core.dart';
import '../connection_manager/connection_manager.dart';
import 'model/ephemeral_identity.dart';
import 'model/permanent_identity.dart';

class IdentityService {
  IdentityService({
    required ConnectionManager connectionManager,
    required MatrixService matrixService,
    MeetingPlaceCoreSDKLogger? logger,
  }) : _connectionManager = connectionManager,
       _matrixService = matrixService,
       _logger =
           logger ?? DefaultMeetingPlaceCoreSDKLogger(className: _className);

  final ConnectionManager _connectionManager;
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

  Future<PermanentIdentity> createPermanentIdentity(
    Wallet wallet, {
    required ChannelTransport transport,
  }) async {
    final permanentChannelDidManager = await _connectionManager.generateDid(
      wallet,
    );

    final didDocument = await permanentChannelDidManager.getDidDocument();

    String? matrixUserId;
    if (transport == ChannelTransport.matrix) {
      matrixUserId = await _matrixService.loginWithDid(
        permanentChannelDidManager,
      );
    }

    _logger.info(
      '''Created permanent identity with DID ${didDocument.id} and Matrix user ID $matrixUserId''',
      name: _logkey,
    );

    return PermanentIdentity(
      didManager: permanentChannelDidManager,
      didDocument: didDocument,
      matrixUserId: matrixUserId,
    );
  }

  Future<PermanentIdentity> getPermanentIdentity(
    Wallet wallet,
    String did,
  ) async {
    final permanentChannelDidManager = await _connectionManager
        .getDidManagerForDid(wallet, did);

    final matrixUserId = await _matrixService.loginWithDid(
      permanentChannelDidManager,
    );

    _logger.info(
      '''Restored permanent identity with DID $did and Matrix user ID $matrixUserId''',
      name: _logkey,
    );

    final didDocument = await permanentChannelDidManager.getDidDocument();

    return PermanentIdentity(
      didManager: permanentChannelDidManager,
      didDocument: didDocument,
      matrixUserId: matrixUserId,
    );
  }
}
