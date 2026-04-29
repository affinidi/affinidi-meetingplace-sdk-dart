import 'package:mutex/mutex.dart';
import 'package:ssi/ssi.dart';
import 'package:uuid/uuid.dart';
import '../../loggers/default_meeting_place_core_sdk_logger.dart';
import '../../loggers/meeting_place_core_sdk_logger.dart';
import '../../utils/string.dart';
import 'connection_manager_exception.dart';
import '../../repository/key_repository.dart';
import '../did_web/did_web_utils.dart';

class ConnectionManager {
  ConnectionManager({
    required KeyRepository keyRepository,
    MeetingPlaceCoreSDKLogger? logger,
  }) : _keyRepository = keyRepository,
       _logger =
           logger ?? DefaultMeetingPlaceCoreSDKLogger(className: _className);

  static const String _className = 'ConnectionManager';
  static const String connectionPrefix = 'connection_';
  static const String lastConnectionIndexPrefix = 'lastConnectionIndex_';

  final KeyRepository _keyRepository;
  final String _rootKeyId = "m/44'/60'/0'/0'/0'";
  final Mutex _mutex = Mutex();
  final MeetingPlaceCoreSDKLogger _logger;

  Future<DidManager> generateRootDid(Wallet wallet) async {
    final methodName = 'generateRootDid';
    _logger.info('Generating root DID...', name: methodName);

    final keyId = _rootKeyId;
    final didManager = await _initDidManager(wallet: wallet, keyId: keyId);
    final didDoc = await didManager.getDidDocument();

    await _keyRepository.saveKeyIdForDid(keyId: keyId, did: didDoc.id);

    _logger.info(
      'Generated root DID: ${didDoc.id.topAndTail()}',
      name: methodName,
    );
    return didManager;
  }

  Future<DidManager> generateDid(Wallet wallet) async {
    final methodName = 'generateDid';
    _logger.info('Generating new DID...', name: methodName);

    await _mutex.acquire();

    try {
      final lastIndex = await _keyRepository.getLastAccountIndex();
      final currentIndex = lastIndex + 1;

      final keyId = _buildKeyId(currentIndex);
      final didManager = await _initDidManager(wallet: wallet, keyId: keyId);
      final didDoc = await didManager.getDidDocument();

      await _keyRepository.setLastAccountIndex(currentIndex);
      await _keyRepository.saveKeyIdForDid(keyId: keyId, did: didDoc.id);

      _logger.info(
        'Generated new DID: ${didDoc.id.topAndTail()} with index: $currentIndex',
        name: methodName,
      );
      return didManager;
    } finally {
      _mutex.release();
    }
  }

  /// Generates a new HD wallet key and wraps it in a [DidWebManager] whose
  /// `did:web` path uses a client-generated UUID segment under `/user/<segment>`
  /// using the canonical host-only domain form.
  ///
  /// The keyId is saved under `manager.did` (the `did:web`) in the repository.
  Future<DidManager> generateDidWeb(Wallet wallet, Uri homeserver) async {
    final methodName = 'generateDidWeb';
    _logger.info('Generating new did:web DID...', name: methodName);

    await _mutex.acquire();

    try {
      final lastIndex = await _keyRepository.getLastAccountIndex();
      final currentIndex = lastIndex + 1;
      final keyId = _buildKeyId(currentIndex);

      await wallet.generateKey(keyId: keyId);
      final segment = const Uuid().v4();

      final domain = Uri(host: homeserver.host, path: '/user/$segment');

      final manager = DidWebManager(
        store: InMemoryDidStore(),
        wallet: wallet,
        domain: domain,
      );
      await manager.addVerificationMethod(
        keyId,
        relationships: {
          VerificationRelationship.authentication,
          VerificationRelationship.keyAgreement,
        },
      );

      await _keyRepository.setLastAccountIndex(currentIndex);
      await _keyRepository.saveKeyIdForDid(keyId: keyId, did: manager.did);

      _logger.info(
        'Generated did:web DID: ${manager.did.topAndTail()} with index: $currentIndex',
        name: methodName,
      );
      return manager;
    } finally {
      _mutex.release();
    }
  }

  Future<DidManager> getDidManagerForDid(Wallet wallet, String did) async {
    final methodName = 'getKeyPairForConnectionDid';
    final keyId = await _keyRepository.getKeyIdByDid(did: did);
    if (keyId == null) {
      _logger.error(
        'Key pair not found for DID: ${did.topAndTail()}',
        name: methodName,
      );
      throw ConnectionManagerException.keyPairNotFoundError(did: did);
    }

    _logger.info(
      'Retrieved key pair for DID: ${did.topAndTail()}',
      name: methodName,
    );

    if (did.startsWith('did:web:')) {
      // Reconstruct the DidWebManager domain from the canonical did:web string.
      final didJsonUri = didWebToUri(did);
      final domain = Uri(
        host: didJsonUri.host,
        path: didJsonUri.pathSegments
            .take(didJsonUri.pathSegments.length - 1)
            .join('/'),
      );
      await wallet.generateKey(keyId: keyId);
      final manager = DidWebManager(
        store: InMemoryDidStore(),
        wallet: wallet,
        domain: domain,
      );
      await manager.addVerificationMethod(
        keyId,
        relationships: {
          VerificationRelationship.authentication,
          VerificationRelationship.keyAgreement,
        },
      );
      return manager;
    }

    return _initDidManager(wallet: wallet, keyId: keyId);
  }

  String _buildKeyId(int index) {
    return "m/44'/60'/0'/0'/$index'";
  }

  Future<DidManager> _initDidManager({
    required Wallet wallet,
    required String keyId,
  }) async {
    await wallet.generateKey(keyId: keyId);
    final didManager = DidKeyManager(store: InMemoryDidStore(), wallet: wallet);
    await didManager.addVerificationMethod(keyId);
    return didManager;
  }
}
