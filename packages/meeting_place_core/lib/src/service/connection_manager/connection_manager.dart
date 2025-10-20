import 'package:mutex/mutex.dart';
import 'package:ssi/ssi.dart';
import '../../loggers/default_mpx_sdk_logger.dart';
import '../../loggers/mpx_sdk_logger.dart';
import '../../utils/string.dart';
import 'connection_manager_exception.dart';
import '../../repository/key_repository.dart';

class ConnectionManager {
  ConnectionManager({
    required KeyRepository keyRepository,
    MeetingPlaceCoreSDKLogger? logger,
  })  : _keyRepository = keyRepository,
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

  Future<DidManager> getDidManagerForDid(
    Wallet wallet,
    String did,
  ) async {
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
