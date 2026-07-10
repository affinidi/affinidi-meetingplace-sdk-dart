import 'package:ssi/ssi.dart';

import '../../../meeting_place_core.dart';
import '../connection_manager/connection_manager.dart';
import 'did_web_document_service.dart';
import 'model/ephemeral_identity.dart';
import 'model/permanent_identity.dart';

class IdentityService {
  IdentityService({
    required ConnectionManager connectionManager,
    required MeetingPlaceTransport channelTransport,
    required DidWebDocumentService didWebDocumentService,
    required Uri didWebBaseHost,
    MeetingPlaceCoreSDKLogger? logger,
  }) : _connectionManager = connectionManager,
       _channelTransport = channelTransport,
       _didWebDocumentService = didWebDocumentService,
       _didWebBaseHost = didWebBaseHost,
       _logger =
           logger ?? DefaultMeetingPlaceCoreSDKLogger(className: _className);

  final ConnectionManager _connectionManager;
  final MeetingPlaceTransport _channelTransport;
  final DidWebDocumentService _didWebDocumentService;
  final Uri _didWebBaseHost;
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
    final permanentChannelDidManager = await _connectionManager.generateDidWeb(
      wallet,
      baseHost: _didWebBaseHost,
    );

    final didDocument = await permanentChannelDidManager.getDidDocument();

    await _didWebDocumentService.register(
      didManager: permanentChannelDidManager,
      didDocument: didDocument,
    );

    await _channelTransport.authenticate(permanentChannelDidManager);

    _logger.info(
      'Created permanent identity with DID ${didDocument.id}',
      name: _logkey,
    );

    return PermanentIdentity(
      didManager: permanentChannelDidManager,
      didDocument: didDocument,
    );
  }

  Future<PermanentIdentity> getPermanentIdentity(
    Wallet wallet,
    String did,
  ) async {
    final permanentChannelDidManager = await _connectionManager
        .getDidManagerForDid(wallet, did);

    await _channelTransport.authenticate(permanentChannelDidManager);

    _logger.info('Restored permanent identity with DID $did', name: _logkey);

    final didDocument = await permanentChannelDidManager.getDidDocument();

    return PermanentIdentity(
      didManager: permanentChannelDidManager,
      didDocument: didDocument,
    );
  }
}
