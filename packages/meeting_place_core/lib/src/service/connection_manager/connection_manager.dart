import 'package:mutex/mutex.dart';
import 'package:ssi/ssi.dart';
import 'package:uuid/uuid.dart';

import '../../loggers/default_meeting_place_core_sdk_logger.dart';
import '../../loggers/meeting_place_core_sdk_logger.dart';
import '../../repository/key_repository.dart';
import '../../utils/string.dart';
import 'connection_manager_exception.dart';
import 'external_connection_keys.dart';

class ConnectionManager {
  /// Creates a [ConnectionManager].
  ///
  /// With [externalConnectionKeys], each new permanent channel DID is made
  /// of keys held outside this device: one that signs its credentials where
  /// it is held, and one lent to this device for DIDComm.
  ConnectionManager({
    required KeyRepository keyRepository,
    ExternalConnectionKeys? externalConnectionKeys,
    MeetingPlaceCoreSDKLogger? logger,
  }) : _keyRepository = keyRepository,
       _externalConnectionKeys = externalConnectionKeys,
       _logger =
           logger ?? DefaultMeetingPlaceCoreSDKLogger(className: _className);

  static const String _className = 'ConnectionManager';
  static const String connectionPrefix = 'connection_';
  static const String lastConnectionIndexPrefix = 'lastConnectionIndex_';

  final KeyRepository _keyRepository;
  final ExternalConnectionKeys? _externalConnectionKeys;
  final String _rootKeyId = "m/44'/60'/0'/0'/0'";
  final Mutex _mutex = Mutex();
  final MeetingPlaceCoreSDKLogger _logger;

  Future<DidManager> generateRootDid(Wallet wallet) async {
    final methodName = 'generateRootDid';
    _logger.info('Generating root DID...', name: methodName);

    final keyId = _rootKeyId;
    final didManager = await _initDidManager(
      wallet: wallet,
      keyId: keyId,
      keyType: _rootKeyType,
    );
    final didDoc = await didManager.getDidDocument();

    await _keyRepository.saveKeyIdForDid(keyId: keyId, did: didDoc.id);

    _logger.info(
      'Generated root DID: ${didDoc.id.topAndTail()}',
      name: methodName,
    );
    return didManager;
  }

  Future<DidManager> generateDid(Wallet wallet) async {
    return _generateDidWithFactory(
      wallet: wallet,
      methodName: 'generateDid',
      factory: (keyId) => _initDidManager(wallet: wallet, keyId: keyId),
    );
  }

  Future<DidManager> generateDidWeb(
    Wallet wallet, {
    required Uri baseHost,
  }) async {
    return _generateDidWithFactory(
      wallet: wallet,
      methodName: 'generateDidWeb',
      factory: (keyId) {
        final segment = const Uuid().v4();
        final domain = baseHost.replace(path: '${baseHost.path}/user/$segment');
        return _initDidWebManager(
          wallet: wallet,
          keyId: keyId,
          domain: domain,
          isNew: true,
        );
      },
    );
  }

  Future<DidManager> _generateDidWithFactory({
    required Wallet wallet,
    required String methodName,
    required Future<DidManager> Function(String keyId) factory,
  }) async {
    _logger.info('Generating new DID...', name: methodName);

    await _mutex.acquire();

    try {
      final lastIndex = await _keyRepository.getLastAccountIndex();
      final currentIndex = lastIndex + 1;

      final keyId = _buildKeyId(currentIndex);
      final didManager = await factory(keyId);
      final didDoc = await didManager.getDidDocument();

      await _keyRepository.setLastAccountIndex(currentIndex);
      await _keyRepository.saveKeyIdForDid(keyId: keyId, did: didDoc.id);

      _logger.info(
        'Generated new DID: ${didDoc.id.topAndTail()} with index: '
        '$currentIndex',
        name: methodName,
      );
      return didManager;
    } finally {
      _mutex.release();
    }
  }

  Future<DidManager> getDidManagerForDid(Wallet wallet, String did) async {
    final methodName = 'getDidManagerForDid';
    final keyId = await _keyRepository.findKeyIdByDid(did: did);
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
      final domain = _domainFromDidWeb(did);
      return _initDidWebManager(
        wallet: wallet,
        keyId: keyId,
        domain: domain,
        isNew: false,
      );
    }
    return _initDidManager(wallet: wallet, keyId: keyId);
  }

  /// The key type of new DIDs: Ed25519, whose DIDs agree keys over X25519,
  /// the curve every DIDComm mediator supports. A key that exists already
  /// keeps its type, so DIDs made before stay as they are.
  static const _keyType = KeyType.ed25519;

  /// The key type of the root DID: P-256. The root DID signs in to the
  /// control plane and registers did:web documents there, and the hosted
  /// control plane accepts P-256 only. It never talks to a mediator.
  static const _rootKeyType = KeyType.p256;

  /// The key type of a new did:web DID's second agreement key: P-256, for
  /// sealing messages to the hosted control plane, which cannot decrypt
  /// X25519. Every other party is reached over X25519.
  static const _controlPlaneKeyType = KeyType.p256;

  String _buildKeyId(int index) {
    return "m/44'/60'/0'/0'/$index'";
  }

  Future<DidManager> _initDidManager({
    required Wallet wallet,
    required String keyId,
    KeyType keyType = _keyType,
  }) async {
    await wallet.generateKey(keyId: keyId, keyType: keyType);
    final didManager = DidKeyManager(store: InMemoryDidStore(), wallet: wallet);
    await didManager.addVerificationMethod(keyId);
    return didManager;
  }

  /// A did:web manager at [domain]. A new DID is made of external keys when
  /// [ExternalConnectionKeys] are configured and offer them, and otherwise
  /// of the device key [keyId]; an existing one keeps the keys it was made
  /// with.
  Future<DidManager> _initDidWebManager({
    required Wallet wallet,
    required String keyId,
    required Uri domain,
    required bool isNew,
  }) async {
    final did = DidWeb.getDid(domain);
    final externalKeys = _externalConnectionKeys;
    final heldKeys = externalKeys == null
        ? null
        : isNew
        ? await externalKeys.createKeys(did)
        : await externalKeys.findKeys(did);

    if (externalKeys == null || heldKeys == null) {
      await wallet.generateKey(keyId: keyId, keyType: _keyType);
      final didManager = DidWebManager(
        store: InMemoryDidStore(),
        wallet: wallet,
        domain: domain,
      );
      await didManager.addVerificationMethod(
        keyId,
        relationships: {
          VerificationRelationship.authentication,
          VerificationRelationship.keyAgreement,
          VerificationRelationship.assertionMethod,
        },
      );
      final controlPlaneKeyId = _controlPlaneKeyId(keyId);
      if (isNew || await _hasKey(wallet, controlPlaneKeyId)) {
        await wallet.generateKey(
          keyId: controlPlaneKeyId,
          keyType: _controlPlaneKeyType,
        );
        await didManager.addVerificationMethod(
          controlPlaneKeyId,
          relationships: {VerificationRelationship.keyAgreement},
        );
      }
      return didManager;
    }

    final externalWallet = ExternalKeyWallet(wallet, externalKeys);
    final didManager = DidWebManager(
      store: InMemoryDidStore(),
      wallet: externalWallet,
      domain: domain,
    );
    await didManager.addVerificationMethod(
      externalWallet.addAgreementKey(heldKeys.agreement),
      relationships: {
        VerificationRelationship.authentication,
        VerificationRelationship.keyAgreement,
      },
    );
    await didManager.addVerificationMethod(
      externalWallet.addSigningKey(heldKeys.signing),
      relationships: {VerificationRelationship.assertionMethod},
    );
    if (heldKeys.controlPlaneAgreement case final key?) {
      await didManager.addVerificationMethod(
        externalWallet.addAgreementKey(key),
        relationships: {VerificationRelationship.keyAgreement},
      );
    }
    return didManager;
  }

  /// The wallet id of the P-256 agreement key that goes with the device key
  /// [keyId].
  static String _controlPlaneKeyId(String keyId) => '$keyId/control-plane';

  /// Whether [wallet] holds the key [keyId]: a DID made before the control
  /// plane key has none, and must not gain one its published document
  /// lacks.
  static Future<bool> _hasKey(Wallet wallet, String keyId) async {
    try {
      await wallet.getPublicKey(keyId);
      return true;
    } on Exception {
      return false;
    }
  }

  Uri _domainFromDidWeb(String did) {
    final withoutPrefix = did.replaceFirst('did:web:', '');
    var decoded = withoutPrefix.replaceAll('%3A', ':');
    decoded = decoded.replaceAll(':', '/');
    return Uri.parse('https://$decoded');
  }
}
