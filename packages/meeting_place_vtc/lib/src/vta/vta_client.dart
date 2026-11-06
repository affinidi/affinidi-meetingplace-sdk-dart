import 'dart:convert';
import 'dart:typed_data';

import 'package:didcomm/didcomm.dart' show EncryptedMessage, PlainTextMessage;
import 'package:ssi/ssi.dart';
import 'package:uuid/uuid.dart';

import '../join/join_models.dart';
import '../meeting_place_vtc_sdk_error_code.dart';
import '../meeting_place_vtc_sdk_exception.dart';
import '../persona/persona_did_manager.dart';
import '../proof/trust_task_signer.dart';
import '../sign_in/sign_in_agent.dart';
import '../transport/didcomm_vta_transport.dart';
import '../trust_task/trust_task_document.dart';
import 'vta_models.dart';

/// The VTA Trust Task types this client sends.
abstract final class VtaTask {
  static const _base = 'https://trusttasks.org/spec';

  /// Opens a REST session: an unsigned request for a challenge.
  static const challenge = '$_base/auth/challenge/0.1';

  /// Answers the challenge, signed; returns the bearer token.
  static const authenticate = '$_base/auth/authenticate/0.3';

  /// Who the VTA takes this client for.
  static const whoAmI = '$_base/auth/whoami/0.1';

  /// Ends this client's sessions on the VTA.
  static const revokeSession = '$_base/auth/revoke-session/0.2';

  /// Has the VTA sign a Trust Task document as a vault persona.
  static const signTrustTask = '$_base/vault/sign-trust-task/0.2';

  /// Lists vault entry metadata.
  static const vaultList = '$_base/vault/list/0.4';

  /// Creates or updates a vault entry.
  static const vaultUpsert = '$_base/vault/upsert/0.4';

  /// Finds stored credentials.
  static const credentialsQuery = '$_base/vault/credentials/query/0.1';

  /// Presents one stored credential to a verifier, signed as its subject.
  static const credentialsPresent = '$_base/vault/credentials/present/0.1';

  /// Fetches one stored credential.
  static const credentialsGet = '$_base/vault/credentials/get/0.2';

  /// Archives a stored credential: hidden from queries, restorable.
  static const credentialsArchive = '$_base/vault/credentials/archive/0.1';

  /// Stores a credential the member received.
  static const credentialsReceive = '$_base/vault/credentials/receive/0.1';

  /// Lists the VTA contexts this client may act in.
  static const contextsList = '$_base/vta/contexts/list/1.0';

  /// Creates a VTA context.
  static const contextsCreate = '$_base/vta/contexts/create/1.0';

  /// Deletes a VTA context, with its keys and DIDs when forced.
  static const contextsDelete = '$_base/vta/contexts/delete/1.1';

  /// Lists the servers the VTA publishes `did:webvh` DIDs on.
  static const serversList = '$_base/vta/webvh/servers/list/1.0';

  /// Creates a `did:webvh` DID whose keys the VTA holds.
  static const didsCreate = '$_base/vta/webvh/dids/create/1.2';

  /// Composes a profile for one context and has a persona there wear it.
  static const profileCompose = '$_base/persona/profile/compose/1.1';

  /// Takes a profile off every persona wearing it, and keeps it.
  static const profileRetire = '$_base/persona/profile/retire/1.0';

  /// Creates or updates a profile kept in one context.
  static const localProfilePut = '$_base/persona/local/profile/put/1.1';

  /// Reads a profile kept in one context.
  static const localProfileGet = '$_base/persona/local/profile/get/1.0';

  /// Has a persona wear a profile kept in its context, taking its values as
  /// they are now.
  static const localBindingSet = '$_base/persona/local/binding/set/1.0';

  /// Lists the `did:webvh` DIDs the VTA hosts keys for.
  static const didsList = '$_base/vta/webvh/dids/list/1.0';

  /// Checks that the VTA answers, and which transports it serves.
  static const ping = '$_base/messaging/ping/0.2';

  /// Signs a JSON document as the DID it names, with a key the VTA holds.
  static const signDocument = '$_base/keys/sign-document/0.1';

  /// Lends the private half of a key the VTA holds, over DIDComm only.
  static const exportSecret = '$_base/keys/export-secret/0.1';

  /// Creates a key the VTA holds, in one context.
  static const keysCreate = '$_base/keys/create/0.1';

  /// Shows what the VTA would disclose about a persona to a verifier.
  static const disclosurePreview = '$_base/persona/disclosure/preview/1.0';

  /// Discloses an approved preview, and records that it was disclosed.
  static const disclosurePresent = '$_base/persona/disclosure/present/1.0';

  /// Stores one application record in a context.
  static const appStatePut = '$_base/vta/app-state/put/1.1';

  /// Lists the application records of a context.
  static const appStateList = '$_base/vta/app-state/list/1.1';

  /// Registers this phone as a device.
  static const deviceRegister = '$_base/device/register/0.2';

  /// Refreshes this phone's device binding.
  static const deviceHeartbeat = '$_base/device/heartbeat/0.3';
}

/// DID document service type of a VTA's REST Trust Task base.
const vtaRestServiceType = 'VTARest';

/// Device extension that enrols the phone's biometric approval key.
const uvKeyExtension = 'org.openvtc.uv-key';

/// The context a VTA creates by default; personas go there when it exists.
const _defaultContextId = 'vta';

/// What the member's VTA calls an identity's context, DID and profile. The
/// holder's own labels: never disclosed.
const _identityLabel = 'Meeting Place identity';

/// The context the signing keys of Meeting Place connection DIDs live in:
/// one for all connections, so a connection costs a key, not a context.
const connectionKeysContextId = 'mpx-connections';

/// What the member's VTA calls the connection keys' context.
const _connectionKeysLabel = 'Meeting Place connections';

/// Multicodec prefix of an Ed25519 public key.
const _ed25519Codec = [0xed, 0x01];

/// Multicodec prefix of a compressed P-256 public key.
const _p256Codec = [0x80, 0x24];

/// Vault secret kind of a persona's sign-in entry, as `vault/upsert/0.4`
/// spells it.
const didSelfIssuedSecretKind = 'didSelfIssued';

/// The same kind as entries written with `vault/upsert/0.1` spell it.
const _legacyDidSelfIssuedSecretKind = 'did-self-issued';

/// Type of the DIDComm message a sealed vault secret travels in.
const _vaultSecretMessageType =
    'https://trusttasks.org/spec/vault/_shared/0.1/vault-secret';

/// A Trust Task client for the member's VTA, over DIDComm through the
/// VTA's mediator.
///
/// Signs every request as the phone's manager key, which the VTA's access
/// list must hold; the authcrypt envelope authenticates the key, so there is
/// no login. Nothing is logged.
class VtaClient implements PersonaSigningAgent {
  /// Creates a [VtaClient] for the VTA [vtaDid], acting as [manager].
  ///
  /// [transport] defaults to DIDComm through the VTA's mediator.
  VtaClient({
    required this.vtaDid,
    required Ed25519DidKeySigner manager,
    DidResolver? didResolver,
    VtaTransport? transport,
  }) : _manager = manager,
       _didResolver = didResolver ?? UniversalDIDResolver.defaultResolver,
       _transport =
           transport ??
           DidcommVtaTransport(
             vtaDid: vtaDid,
             manager: manager,
             didResolver: didResolver ?? UniversalDIDResolver.defaultResolver,
           );

  /// A `<task>:<code>` in a message, the task a path such as
  /// `vault/sign-trust-task`. Never a DID: `did:key:z…` names no code.
  static final _innerCode = RegExp(
    r'(?<![\w:.#/-])(?!did:)[a-z][a-z-]*(?:/[a-z0-9.-]+)+:([A-Za-z_]+)',
  );

  /// Multicodec prefixes of an Ed25519, an X25519 and a P-256 private key.
  static const _ed25519SecretPrefix = [0x80, 0x26];
  static const _x25519SecretPrefix = [0x82, 0x26];
  static const _p256SecretPrefix = [0x86, 0x26];
  static const _secretKeyLength = 32;

  @override
  final String vtaDid;

  final Ed25519DidKeySigner _manager;
  final DidResolver _didResolver;
  final VtaTransport _transport;

  DidDocument? _vtaDocument;
  bool _hasSession = false;

  /// DID of the manager key this client acts as.
  String get managerDid => _manager.did;

  /// Asks the VTA what it lets this client do.
  ///
  /// The answer decides whether the phone is linked, so it must be signed by
  /// the VTA, addressed to the manager key and answer this very request.
  ///
  /// Throws [MeetingPlaceVtcSDKException] with
  /// [MeetingPlaceVtcSDKErrorCode.refused] when the manager key is not on
  /// the VTA's access list, and with
  /// [MeetingPlaceVtcSDKErrorCode.invalidProof] when the answer does not
  /// verify.
  Future<VtaAccess> whoAmI() async => VtaAccess.fromWhoAmI(
    await _task(VtaTask.whoAmI, const {}, verifyAnswer: true),
  );

  /// Checks that [vtaDid] resolves to a VTA that answers over DIDComm,
  /// before the manager key is granted: pings it through its mediator. A
  /// refusal is an answer too, so a key not granted yet passes.
  ///
  /// Throws [MeetingPlaceVtcSDKException] with
  /// [MeetingPlaceVtcSDKErrorCode.didResolutionFailed] when the DID does not
  /// resolve, [MeetingPlaceVtcSDKErrorCode.signInNotOffered] when it names no
  /// DIDComm mediator, and another code when the VTA cannot be reached.
  Future<void> checkReachable() async {
    final ping = await TrustTaskDocument.create(
      type: VtaTask.ping,
      issuer: _manager.did,
      recipient: vtaDid,
      payload: const {},
    ).sign(_manager, purpose: ProofPurpose.authentication);
    try {
      await _transport.send(ping);
    } on MeetingPlaceVtcSDKException catch (error) {
      if (error.code != MeetingPlaceVtcSDKErrorCode.refused) rethrow;
    }
  }

  /// Ends every session the VTA holds for the manager key, best effort.
  ///
  /// Does not remove the key from the VTA's access list: only its
  /// administrator can.
  Future<void> signOut() async {
    if (!_hasSession) return;
    try {
      await _send(VtaTask.revokeSession, {'all': true, 'reason': 'unlinked'});
    } on MeetingPlaceVtcSDKException {
      // The session expires on its own.
    } finally {
      _hasSession = false;
    }
  }

  @override
  Future<Map<String, dynamic>> signTrustTask({
    required String entryId,
    required Map<String, dynamic> unsignedEnvelope,
    Map<String, dynamic>? ext,
  }) async {
    final answer = await _task(VtaTask.signTrustTask, {
      'entryId': entryId,
      'unsignedEnvelope': unsignedEnvelope,
      'ext': ?ext,
    });
    final signed = answer['signedEnvelope'];
    if (signed is! Map<String, dynamic>) {
      throw MeetingPlaceVtcSDKException.invalidDocument(
        'no signedEnvelope in the answer',
      );
    }
    return signed;
  }

  /// Returns the id of [persona]'s sign-in vault entry for the community
  /// [vtcDid], creating it when missing.
  ///
  /// The VTA creates none when a member joins. The created entry's secret
  /// names the persona's signing key; it holds no key material.
  Future<String> ensureSignInVaultEntry({
    required String vtcDid,
    required VtaPersona persona,
  }) async {
    final answer = await _task(VtaTask.vaultList, {
      'contextId': persona.contextId,
      'targetDid': vtcDid,
    });
    final entries = switch (answer['entries']) {
      final List<dynamic> list => list.whereType<Map<String, dynamic>>(),
      _ => const <Map<String, dynamic>>[],
    };
    for (final entry in entries) {
      if (_isSignInEntry(entry, persona.did, vtcDid)) {
        return entry['id'] as String;
      }
    }

    final upserted = await _task(VtaTask.vaultUpsert, {
      'contextId': persona.contextId,
      'targets': [
        {'kind': 'did', 'did': vtcDid},
      ],
      'label': 'Meeting Place sign-in',
      'secretKind': didSelfIssuedSecretKind,
      'sealedSecret': {
        'envelope': 'didcommAuthcrypt',
        'jwe': await _sealToVta({
          'kind': didSelfIssuedSecretKind,
          'did': persona.did,
          'signingKeyId': persona.signingKeyId,
        }),
      },
    });
    final entryId = (upserted['entry'] as Map<String, dynamic>?)?['id'];
    if (entryId is! String) {
      throw MeetingPlaceVtcSDKException.invalidDocument('no vault entry id');
    }
    return entryId;
  }

  /// Enrols the phone's biometric approval key [uvDid] with the VTA,
  /// registering the phone as a device first if needed.
  ///
  /// Idempotent: the same key again changes nothing. The key is a software
  /// Ed25519 key behind biometric access control, not hardware backed.
  Future<void> enrolUserVerificationKey({
    required String uvDid,
    required String displayName,
    required String platform,
  }) async {
    final ext = {
      uvKeyExtension: {
        'kind': 'hardwareKey',
        'did': uvDid,
        'hardwareBacked': false,
        'biometricGated': true,
      },
    };
    try {
      await _task(VtaTask.deviceRegister, {
        'consumerKind': {'kind': 'companion', 'formFactor': 'mobile'},
        'displayName': displayName,
        'platform': platform,
        'ext': ext,
      });
    } on MeetingPlaceVtcSDKException catch (error) {
      if (error.refusalCode != 'alreadyRegistered') rethrow;
      await _task(VtaTask.deviceHeartbeat, {'ext': ext});
    }
  }

  /// Creates the keys the VTA holds for one Meeting Place connection DID:
  ///
  /// - `signing`, an Ed25519 key that signs its credentials. Its private key
  ///   never leaves the VTA: the VTA signs with it through [signDocument].
  /// - `agreement`, an Ed25519 key it signs in with and, as the X25519 key
  ///   derived from it, agrees keys with. The VTA lends it through
  ///   [lendConnectionKey] when DIDComm needs it. Ed25519, so the DID agrees
  ///   keys over X25519, the curve every DIDComm mediator supports.
  /// - `controlPlaneAgreement`, a P-256 key it agrees keys with the hosted
  ///   control plane over, as that cannot decrypt X25519. Lent like
  ///   `agreement`.
  ///
  /// The keys live in [connectionKeysContextId], which is created on first
  /// use. Throws [MeetingPlaceVtcSDKException] when the VTA refuses or
  /// cannot be reached.
  Future<
    ({
      VtaConnectionKey signing,
      VtaConnectionKey agreement,
      VtaConnectionKey controlPlaneAgreement,
    })
  >
  createConnectionKeys() async {
    await _ensureContext(connectionKeysContextId, name: _connectionKeysLabel);
    return (
      signing: await _createConnectionKey(
        'ed25519',
        codec: _ed25519Codec,
        length: 32,
      ),
      agreement: await _createConnectionKey(
        'ed25519',
        codec: _ed25519Codec,
        length: 32,
      ),
      controlPlaneAgreement: await _createConnectionKey(
        'p256',
        codec: _p256Codec,
        length: 33,
      ),
    );
  }

  /// Borrows the private half of the connection key [keyId] from
  /// [createConnectionKeys], as its 32 bytes: an Ed25519 seed, or a P-256
  /// private key.
  ///
  /// The VTA lends keys over DIDComm only, and audits each loan. Keep the
  /// key in memory and zero-fill it when done. Throws
  /// [MeetingPlaceVtcSDKException] refused when the VTA will not lend it.
  Future<Uint8List> lendConnectionKey(String keyId) async {
    final answer = await _task(VtaTask.exportSecret, {'keyId': keyId});
    for (final (prefix, keyType) in const [
      (_ed25519SecretPrefix, 'ed25519'),
      (_p256SecretPrefix, 'p256'),
    ]) {
      if (_readSecret(answer, prefix: prefix, keyType: keyType)
          case final key?) {
        return key;
      }
    }
    throw MeetingPlaceVtcSDKException.invalidDocument('lent key unreadable');
  }

  Future<VtaConnectionKey> _createConnectionKey(
    String keyType, {
    required List<int> codec,
    required int length,
  }) async {
    final answer = await _task(VtaTask.keysCreate, {
      'keyType': keyType,
      'contextId': connectionKeysContextId,
      'label': _connectionKeysLabel,
    });
    final key = answer['key'];
    final keyId = key is Map<String, dynamic> ? key['keyId'] : null;
    final publicKey = key is Map<String, dynamic> ? key['publicKey'] : null;
    if (keyId is! String ||
        publicKey is! String ||
        (key as Map<String, dynamic>)['keyType'] != keyType) {
      throw MeetingPlaceVtcSDKException.invalidDocument('no $keyType key');
    }
    return VtaConnectionKey(
      keyId: keyId,
      publicKey: _publicKeyBytes(publicKey, codec: codec, length: length),
    );
  }

  /// Creates the context [contextId] unless this client may already act
  /// there.
  Future<void> _ensureContext(String contextId, {required String name}) async {
    final contextIds = _ids(
      (await _task(VtaTask.contextsList, const {}))['contexts'],
    );
    if (contextIds.contains(contextId)) return;
    try {
      await _task(VtaTask.contextsCreate, {'id': contextId, 'name': name});
    } on MeetingPlaceVtcSDKException catch (error) {
      // Created meanwhile by another call.
      if (error.refusalCode != 'alreadyExists') rethrow;
    }
  }

  /// The [length] bytes of the public key [multibase], with or without its
  /// multicodec prefix [codec].
  static Uint8List _publicKeyBytes(
    String multibase, {
    required List<int> codec,
    required int length,
  }) {
    final Uint8List bytes;
    try {
      bytes = multiBaseToUint8List(multibase);
    } on Object {
      throw MeetingPlaceVtcSDKException.invalidDocument('bad public key');
    }
    if (bytes.length == codec.length + length &&
        bytes[0] == codec[0] &&
        bytes[1] == codec[1]) {
      return Uint8List.sublistView(bytes, codec.length);
    }
    if (bytes.length == length) return bytes;
    throw MeetingPlaceVtcSDKException.invalidDocument('bad public key');
  }

  /// Lists the `did:webvh` DIDs whose keys the VTA holds: the member's
  /// personas.
  Future<List<VtaPersona>> listPersonas() async {
    final answer = await _task(VtaTask.didsList, const {});
    final dids = switch (answer['dids']) {
      final List<dynamic> list => list.whereType<Map<String, dynamic>>(),
      _ => const <Map<String, dynamic>>[],
    };
    return [
      for (final did in dids)
        if (did['did'] is String && did['contextId'] is String)
          VtaPersona(
            did: did['did'] as String,
            contextId: did['contextId'] as String,
          ),
    ];
  }

  /// Creates a new persona, a `did:webvh` DID published on the VTA's first
  /// DID hosting server, so the community can resolve it.
  ///
  /// The persona lives in the VTA's default context when this client may act
  /// there, else in the first context it may. It advertises the VTA's
  /// mediator, so a community can deliver what it issues later, e.g. the
  /// membership card once an administrator admits the persona.
  ///
  /// Throws [MeetingPlaceVtcSDKException] with
  /// [MeetingPlaceVtcSDKErrorCode.didHostingMissing] when the VTA has no
  /// hosting server.
  Future<VtaPersona> createPersona({required String label}) async {
    final contextIds = _ids(
      (await _task(VtaTask.contextsList, const {}))['contexts'],
    );
    if (contextIds.isEmpty) {
      throw MeetingPlaceVtcSDKException.invalidDocument('no VTA context');
    }
    return _createDid(
      contextId: contextIds.contains(_defaultContextId)
          ? _defaultContextId
          : contextIds.first,
      serverId: await _firstServerId(),
      label: label,
      setPrimary: false,
    );
  }

  /// Creates an identity showing [profile]: a context of its own, a persona
  /// DID published on the VTA's first DID hosting server, and a profile kept
  /// in that context which the persona wears.
  ///
  /// All or nothing: when a step fails, the context is deleted with whatever
  /// was created in it, and the failure is rethrown.
  ///
  /// Throws [MeetingPlaceVtcSDKException] with
  /// [MeetingPlaceVtcSDKErrorCode.didHostingMissing] when the VTA has no
  /// hosting server.
  Future<VtaIdentity> createIdentity(VtaProfile profile) async {
    final serverId = await _firstServerId();
    final contextId = 'mpx-${const Uuid().v4().replaceAll('-', '')}';
    await _task(VtaTask.contextsCreate, {
      'id': contextId,
      'name': _identityLabel,
    });
    try {
      final persona = await _createDid(
        contextId: contextId,
        serverId: serverId,
        label: _identityLabel,
        setPrimary: true,
      );
      final composed = await _task(VtaTask.profileCompose, {
        'contextId': contextId,
        'name': _identityLabel,
        'claims': profile.toClaims(),
        'personaDid': persona.did,
      });
      final profileId = composed['profileId'];
      if (profileId is! String) {
        throw MeetingPlaceVtcSDKException.invalidDocument('no profile id');
      }
      return VtaIdentity(
        persona: persona,
        profileId: profileId,
        profile: profile,
      );
    } catch (_) {
      await _deleteContext(contextId, ignoreFailure: true);
      rethrow;
    }
  }

  /// Reads the profile [profileId] that the identity in [contextId] wears.
  Future<VtaProfile> profile({
    required String contextId,
    required String profileId,
  }) async => VtaProfile.fromEntries(
    (await profileDocument(
      contextId: contextId,
      profileId: profileId,
    ))['entries'],
  );

  /// Reads the profile [profileId] that the identity in [contextId] wears,
  /// as the VTA keeps it: its version, name and entries, unparsed.
  Future<Map<String, dynamic>> profileDocument({
    required String contextId,
    required String profileId,
  }) async {
    final answer = await _task(VtaTask.localProfileGet, {
      'contextId': contextId,
      'profileId': profileId,
    });
    final profile = answer['profile'];
    if (profile is! Map<String, dynamic>) {
      throw MeetingPlaceVtcSDKException.invalidDocument('no profile');
    }
    return profile;
  }

  /// Replaces the details of the profile [profileId] that the identity
  /// [personaDid] in [contextId] wears with [profile].
  ///
  /// The persona then wears the profile again: what the VTA discloses as the
  /// persona is a copy taken when it put the profile on, and writing the
  /// profile alone leaves that copy as it was.
  Future<void> updateProfile({
    required String contextId,
    required String personaDid,
    required String profileId,
    required VtaProfile profile,
  }) async {
    await _task(VtaTask.localProfilePut, {
      'contextId': contextId,
      'profileId': profileId,
      'name': _identityLabel,
      'entries': profile.toEntries(),
    });
    await _task(VtaTask.localBindingSet, {
      'contextId': contextId,
      'personaDid': personaDid,
      'profileId': profileId,
    });
  }

  /// Deletes an identity: retires its profile [profileId], then deletes its
  /// context [contextId] with the persona DID and keys in it, including the
  /// copy on the DID hosting server. The DID cannot be used again.
  ///
  /// Safe to repeat: an identity already gone is not an error.
  Future<void> deleteIdentity({
    required String contextId,
    required String profileId,
  }) async {
    try {
      await _task(VtaTask.profileRetire, {
        'contextId': contextId,
        'profileId': profileId,
      });
    } on MeetingPlaceVtcSDKException catch (error) {
      // Already retired, or gone: the context delete below removes it.
      if (error.code != MeetingPlaceVtcSDKErrorCode.refused) rethrow;
    }
    await _deleteContext(contextId);
  }

  Future<String> _firstServerId() async {
    final serverIds = _ids(
      (await _task(VtaTask.serversList, const {}))['servers'],
    );
    if (serverIds.isEmpty) {
      throw MeetingPlaceVtcSDKException.didHostingMissing();
    }
    return serverIds.first;
  }

  /// Creates a persona DID in [contextId], published on [serverId]. It
  /// advertises the VTA's mediator, when the VTA has one, so a community
  /// can deliver what it issues later, e.g. the membership card once an
  /// administrator admits the persona.
  Future<VtaPersona> _createDid({
    required String contextId,
    required String serverId,
    required String label,
    required bool setPrimary,
  }) async {
    final created = await _task(VtaTask.didsCreate, {
      'contextId': contextId,
      'serverId': serverId,
      'label': label,
      'addMediatorService': true,
      // DIDComm only: a community pushes over TSP first when the DID offers
      // it, and Meeting Place collects the persona's mail over DIDComm.
      'addTspService': false,
      'setPrimary': setPrimary,
    });
    final did = created['did'];
    final createdContextId = created['contextId'];
    final signingKeyId = created['signingKeyId'];
    if (did is! String ||
        createdContextId is! String ||
        signingKeyId is! String) {
      throw MeetingPlaceVtcSDKException.invalidDocument('no created persona');
    }
    return VtaPersona(
      did: did,
      contextId: createdContextId,
      signingKeyId: signingKeyId,
    );
  }

  /// Deletes [contextId] with everything in it. A context already gone is
  /// not an error; with [ignoreFailure], neither is any other refusal or
  /// transport failure.
  Future<void> _deleteContext(
    String contextId, {
    bool ignoreFailure = false,
  }) async {
    try {
      await _task(VtaTask.contextsDelete, {'id': contextId, 'force': true});
    } on MeetingPlaceVtcSDKException catch (error) {
      if (ignoreFailure || error.refusalCode == 'notFound') return;
      rethrow;
    }
  }

  /// Stores [credential] in the vault, in the context [contextId] of the
  /// persona it was issued to.
  ///
  /// The VTA verifies the credential's proofs against its issuer before it
  /// stores it, and files a membership credential under purpose
  /// `membership`.
  ///
  /// Returns whether the VTA keeps it as usable: false for a card it found
  /// revoked or expired.
  Future<bool> keepCredential(
    Map<String, dynamic> credential, {
    required String contextId,
  }) async {
    final answer = await _task(VtaTask.credentialsReceive, {
      'credential': credential,
      'contextId': contextId,
      // Its own id, so storing the same card again replaces it.
      if (credential['id'] case final String id) 'id': id,
    });
    return !const {'revoked', 'expired'}.contains(answer['status']);
  }

  /// Stores [value] as the record [key] of the application [namespace] in
  /// the context [contextId], replacing what it held, and returns the
  /// version the write took. With [expectedVersion] the write applies only
  /// over that version, or only when no record exists for `0`.
  ///
  /// The store is not for secrets. Throws [MeetingPlaceVtcSDKException]
  /// refused with `vta/app-state/put:versionConflict` when [expectedVersion]
  /// does not hold.
  Future<int> putAppState({
    required String contextId,
    required String namespace,
    required String key,
    required Object? value,
    int? expectedVersion,
  }) async {
    final answer = await _task(VtaTask.appStatePut, {
      'contextId': contextId,
      'namespace': namespace,
      'key': key,
      'value': value,
      'expectedVersion': ?expectedVersion,
    });
    final version = answer['version'];
    if (version is! int) {
      throw MeetingPlaceVtcSDKException.invalidDocument('no record version');
    }
    return version;
  }

  /// The live records of the application [namespace] in the context
  /// [contextId] whose keys start with [prefix], with their values, in key
  /// order. Reads every page.
  Future<List<AppStateRecord>> listAppState({
    required String contextId,
    required String namespace,
    String? prefix,
  }) async {
    final records = <AppStateRecord>[];
    String? cursor;
    do {
      final answer = await _task(VtaTask.appStateList, {
        'contextId': contextId,
        'namespace': namespace,
        'prefix': ?prefix,
        'includeValues': true,
        'cursor': ?cursor,
      });
      final page = answer['records'];
      if (page is! List) {
        throw MeetingPlaceVtcSDKException.invalidDocument('no records');
      }
      for (final record in page.whereType<Map<String, dynamic>>()) {
        if (record['deleted'] == true) continue;
        records.add(AppStateRecord.fromJson(record));
      }
      cursor = answer['nextCursor'] as String?;
    } while (cursor != null);
    return records;
  }

  @override
  Future<Map<String, dynamic>> signDocument({
    required String keyId,
    required Map<String, dynamic> document,
    required String purpose,
  }) async {
    final answer = await _task(VtaTask.signDocument, {
      'keyId': keyId,
      'document': document,
      'proofPurpose': purpose,
    });
    final signed = answer['document'];
    if (signed is! Map<String, dynamic> || signed['proof'] == null) {
      throw MeetingPlaceVtcSDKException.invalidDocument('no signed document');
    }
    return signed;
  }

  /// Borrows [persona]'s keys from the VTA for this session, so DIDComm can
  /// sign in, seal and unseal as the persona: the first signing key and the
  /// first key agreement key its DID document names.
  ///
  /// The VTA lends keys over DIDComm only, and audits each loan. Keep the
  /// manager in memory and [PersonaDidManager.forget] it when the session
  /// ends. Throws [MeetingPlaceVtcSDKException] refused when the VTA will not
  /// lend a key, and with an `invalidDocument` code when a key it lends is
  /// not the one the persona's DID document states.
  Future<PersonaDidManager> borrowPersonaKeys(VtaPersona persona) async {
    final document = await _resolve(persona.did);
    final signingMethod = document.authentication.firstOrNull;
    final keyAgreementMethod = document.keyAgreement.firstOrNull;
    if (signingMethod == null || keyAgreementMethod == null) {
      throw MeetingPlaceVtcSDKException.invalidDocument(
        'persona names no signing or key agreement key',
      );
    }
    final signingSeed = await _exportKey(
      _absoluteId(signingMethod.id, persona.did),
      prefix: _ed25519SecretPrefix,
      keyType: 'ed25519',
    );
    try {
      final keyAgreementKey = await _exportKey(
        _absoluteId(keyAgreementMethod.id, persona.did),
        prefix: _x25519SecretPrefix,
        keyType: 'x25519',
      );
      try {
        return await PersonaDidManager.borrow(
          document: document,
          signingSeed: signingSeed,
          keyAgreementKey: keyAgreementKey,
        );
      } finally {
        keyAgreementKey.fillRange(0, keyAgreementKey.length, 0);
      }
    } finally {
      signingSeed.fillRange(0, signingSeed.length, 0);
    }
  }

  /// The private key [keyId] the VTA lends: a Multikey with [prefix], or a
  /// bare key when the answer names it [keyType].
  Future<Uint8List> _exportKey(
    String keyId, {
    required List<int> prefix,
    required String keyType,
  }) async {
    final answer = await _task(VtaTask.exportSecret, {'keyId': keyId});
    return _readSecret(answer, prefix: prefix, keyType: keyType) ??
        (throw MeetingPlaceVtcSDKException.invalidDocument(
          'lent key unreadable',
        ));
  }

  /// The private key in a `keys/export-secret` [answer]: a Multikey with
  /// [prefix], or a bare key when the answer names it [keyType]; null when
  /// it is neither.
  ///
  /// Throws [MeetingPlaceVtcSDKException] when the answer holds no key.
  static Uint8List? _readSecret(
    Map<String, dynamic> answer, {
    required List<int> prefix,
    required String keyType,
  }) {
    final multibase = answer['privateKeyMultibase'];
    final Uint8List decoded;
    try {
      decoded = multiBaseToUint8List(multibase as String);
    } on Object {
      throw MeetingPlaceVtcSDKException.invalidDocument('no lent key');
    }
    final hasPrefix =
        decoded.length == prefix.length + _secretKeyLength &&
        decoded[0] == prefix[0] &&
        decoded[1] == prefix[1];
    final isBare =
        decoded.length == _secretKeyLength &&
        '${answer['keyType']}'.toLowerCase().contains(keyType);
    if (!hasPrefix && !isBare) {
      decoded.fillRange(0, decoded.length, 0);
      return null;
    }
    final key = Uint8List.fromList(
      hasPrefix ? decoded.sublist(prefix.length) : decoded,
    );
    decoded.fillRange(0, decoded.length, 0);
    return key;
  }

  static String _absoluteId(String id, String did) =>
      id.startsWith('#') ? '$did$id' : id;

  /// Previews what the VTA would disclose about [persona] to [verifierDid]
  /// for [requestedClaims], the claim types a verifier asks for.
  ///
  /// Nothing is disclosed until [presentDisclosure]. Throws
  /// [MeetingPlaceVtcSDKException] refused with `notBound` when the persona
  /// has no profile bound on the VTA.
  Future<DisclosurePreview> previewDisclosure({
    required VtaPersona persona,
    required String verifierDid,
    required List<String> requestedClaims,
    String? purpose,
  }) async {
    final answer = await _task(VtaTask.disclosurePreview, {
      'contextId': persona.contextId,
      'personaDid': persona.did,
      'verifierDid': verifierDid,
      'requestedClaims': requestedClaims,
      'purpose': ?purpose,
    });
    final previewId = answer['previewId'];
    if (previewId is! String) {
      throw MeetingPlaceVtcSDKException.invalidDocument(
        'no disclosure preview',
      );
    }
    return DisclosurePreview(
      previewId: previewId,
      claims: [
        for (final claim in _maps(answer['claims']))
          if (claim['type'] case final String type)
            DisclosedClaim(
              type: type,
              value: claim['value'],
              stale: claim['stale'] == true,
            ),
      ],
    );
  }

  /// Discloses the preview [previewId] the member approved, so the VTA
  /// records the disclosure to its verifier.
  ///
  /// Throws [MeetingPlaceVtcSDKException] refused with `stepUpRequired` when
  /// the VTA asks for a step-up first, or `staleClaim` or `previewNotFound`
  /// when the preview no longer holds.
  Future<void> presentDisclosure({
    required VtaPersona persona,
    required String previewId,
  }) async {
    await _task(VtaTask.disclosurePresent, {
      'contextId': persona.contextId,
      'previewId': previewId,
    });
  }

  /// Returns the credentials stored in the vault for [purpose], e.g.
  /// `membership`, issued by [issuerDid] and made out to [subjectDid] when
  /// given. Each one found is fetched on its own, so narrowing the query
  /// saves a request per credential left out.
  Future<List<Map<String, dynamic>>> credentials(
    String purpose, {
    String? issuerDid,
    String? subjectDid,
  }) async => [
    for (final stored in await storedCredentials(
      purpose,
      issuerDid: issuerDid,
      subjectDid: subjectDid,
    ))
      stored.credential,
  ];

  /// Returns the credentials stored in the vault for [purpose], by the
  /// vault's own id for each, which [archiveCredential] takes.
  Future<Map<String, Map<String, dynamic>>> heldCredentials(
    String purpose,
  ) async => {
    for (final stored in await storedCredentials(purpose))
      stored.record.id: stored.credential,
  };

  /// Returns the credentials stored in the vault for [purpose], each with
  /// the vault's record of it, narrowed as [credentials] narrows.
  Future<List<StoredCredential>> storedCredentials(
    String purpose, {
    String? issuerDid,
    String? subjectDid,
  }) async {
    return [
      for (final record in await credentialRecords(
        purpose,
        issuerDid: issuerDid,
        subjectDid: subjectDid,
      ))
        if (await credential(record.id) case final credential?)
          StoredCredential(record: record, credential: credential),
    ];
  }

  /// Describes the credentials stored in the vault for [purpose], narrowed
  /// as [credentials] narrows, without fetching any: [credential] fetches
  /// one.
  Future<List<HeldCredential>> credentialRecords(
    String purpose, {
    String? issuerDid,
    String? subjectDid,
  }) async {
    final answer = await _task(VtaTask.credentialsQuery, {
      'purpose': purpose,
      'issuerDid': ?issuerDid,
      'subjectDid': ?subjectDid,
    });
    return _heldOf(_maps(answer['credentials']));
  }

  /// Returns the stored credential [id], or null when the vault answers
  /// with no credential.
  Future<Map<String, dynamic>?> credential(String id) async {
    final got = await _task(VtaTask.credentialsGet, {'id': id});
    final credential = got['credential'];
    return credential is Map<String, dynamic> ? credential : null;
  }

  /// Finds the valid credentials the vault holds, carrying the VC type
  /// [type], issued by [issuerDid] and made out to [subjectDid] when given.
  /// Returns descriptions only, never a credential's claims.
  Future<List<HeldCredential>> findCredentials({
    String? type,
    String? issuerDid,
    String? subjectDid,
  }) async {
    final answer = await _task(VtaTask.credentialsQuery, {
      'type': ?type,
      'issuerDid': ?issuerDid,
      'subjectDid': ?subjectDid,
      'status': 'valid',
    });
    // A description without types cannot be matched to what is asked.
    return _heldOf(
      _maps(answer['credentials']).where((d) => d['types'] is List),
    );
  }

  /// The vault's descriptions of credentials in a query answer.
  static List<HeldCredential> _heldOf(
    Iterable<Map<String, dynamic>> descriptors,
  ) => [
    for (final descriptor in descriptors)
      if (descriptor['id'] case final String id)
        HeldCredential(
          id: id,
          types: switch (descriptor['types']) {
            final List<dynamic> types => List.unmodifiable(
              types.whereType<String>(),
            ),
            _ => const [],
          },
          issuerDid: _stringOf(descriptor['issuerDid']),
          validFrom: DateTime.tryParse('${descriptor['validFrom']}'),
          validUntil: DateTime.tryParse('${descriptor['validUntil']}'),
          purpose: _stringOf(descriptor['purpose']),
          status: _stringOf(descriptor['status']),
        ),
  ];

  static String? _stringOf(Object? value) => value is String ? value : null;

  /// Finds a held credential made out to [subjectDid] for each credential
  /// [request] asks for, from an issuer it admits for the community
  /// [communityDid]. Returns null when one is missing, or the request is
  /// one this wallet cannot read.
  ///
  /// Issuers a community recognises are known only to the community, so
  /// for [JoinCredentialIssuers.recognised] any issuer is taken and the
  /// community decides.
  Future<List<HeldCredential>?> matchCredentials(
    JoinCredentialRequest request, {
    required String subjectDid,
    required String communityDid,
  }) async {
    if (!request.readable) return null;
    final issuerDid = request.issuers == JoinCredentialIssuers.community
        ? communityDid
        : null;
    final matches = <HeldCredential>[];
    for (final alternatives in request.typeAlternatives) {
      HeldCredential? match;
      for (final types in alternatives) {
        // The most specific type narrows the query; the rest are checked.
        final narrowest = types.lastWhere(
          (type) => type != 'VerifiableCredential',
          orElse: () => types.last,
        );
        final held = await findCredentials(
          type: narrowest,
          issuerDid: issuerDid,
          subjectDid: subjectDid,
        );
        match = held
            .where((credential) => types.every(credential.types.contains))
            .firstOrNull;
        if (match != null) break;
      }
      if (match == null) return null;
      matches.add(match);
    }
    return matches;
  }

  /// Presents the stored credential [id] to [audience], bound to [nonce],
  /// disclosing the subject claims [claims]. The VTA signs the presentation
  /// as the credential's subject and records the disclosure.
  ///
  /// Throws [MeetingPlaceVtcSDKException] refused with `wouldOverDisclose`
  /// when the credential cannot disclose less than claims [claims] leaves
  /// out, `claimNotHeld` when it lacks one, or `notPresentable` when it is
  /// no longer valid.
  Future<CredentialPresentation> presentCredential({
    required String id,
    required List<String> claims,
    required String audience,
    required String nonce,
    String? purpose,
  }) async {
    final answer = await _task(VtaTask.credentialsPresent, {
      'id': id,
      'claims': claims,
      'audience': audience,
      'nonce': nonce,
      'purpose': ?purpose,
    });
    final presentation = answer['presentation'];
    if (presentation is! Map<String, dynamic>) {
      throw MeetingPlaceVtcSDKException.invalidDocument('no W3C presentation');
    }
    return CredentialPresentation(
      presentation: presentation,
      disclosed: switch (answer['disclosed']) {
        final List<dynamic> claims => [...claims.whereType<String>()],
        _ => const [],
      },
    );
  }

  /// Archives the stored credential [id], one of [heldCredentials]: the VTA
  /// hides it from queries and refuses to present it, but can restore it.
  Future<void> archiveCredential(String id) async {
    await _task(VtaTask.credentialsArchive, {'id': id});
  }

  /// Sends a signed task and returns the answer's payload.
  Future<Map<String, dynamic>> _task(
    String type,
    Map<String, dynamic> payload, {
    bool verifyAnswer = false,
  }) => _send(type, payload, verifyAnswer: verifyAnswer);

  Future<Map<String, dynamic>> _send(
    String type,
    Map<String, dynamic> payload, {
    bool verifyAnswer = false,
  }) async {
    final request = await TrustTaskDocument.create(
      type: type,
      issuer: _manager.did,
      recipient: vtaDid,
      payload: payload,
    ).sign(_manager, purpose: ProofPurpose.authentication);
    final TrustTaskDocument answer;
    try {
      answer = await _transport.send(request);
      _hasSession = true;
    } on MeetingPlaceVtcSDKException catch (error) {
      if (error.code != MeetingPlaceVtcSDKErrorCode.refused) rethrow;
      throw MeetingPlaceVtcSDKException.refused(
        _localRefusalCode(error),
        errorPayload: error.errorPayload,
        httpStatus: error.httpStatus,
      );
    }
    if (verifyAnswer) await _verifyAnswer(answer, request);
    return answer.payload;
  }

  /// Checks that [answer] is the VTA's own, signed answer to [request].
  Future<void> _verifyAnswer(
    TrustTaskDocument answer,
    TrustTaskDocument request,
  ) async {
    if (answer.issuer != vtaDid ||
        answer.recipient != _manager.did ||
        answer.threadId != request.id) {
      throw MeetingPlaceVtcSDKException.invalidProof(
        'not an answer from the VTA',
      );
    }
    await answer.verify(
      purpose: ProofPurpose.authentication,
      resolver: _ResolvedVta(await _resolveVta()),
    );
  }

  Future<DidDocument> _resolveVta() async {
    if (_vtaDocument case final document?) return document;
    return _vtaDocument = await _resolve(vtaDid);
  }

  /// [did]'s document, which must name [did] as its id.
  Future<DidDocument> _resolve(String did) async {
    try {
      final document = await _didResolver.resolveDid(did);
      if (document.id != did) {
        throw MeetingPlaceVtcSDKException.didResolutionFailed();
      }
      return document;
    } on MeetingPlaceVtcSDKException {
      rethrow;
    } catch (error) {
      throw MeetingPlaceVtcSDKException.didResolutionFailed(
        innerException: error,
      );
    }
  }

  /// Seals [secret] to the VTA as an authcrypt JWE from the manager key: the
  /// VTA refuses a secret not sent by the authenticated caller.
  Future<String> _sealToVta(Map<String, dynamic> secret) async {
    final managerDocument = DidKey.resolve(_manager.did);
    final message = PlainTextMessage(
      id: 'urn:uuid:${const Uuid().v4()}',
      type: Uri.parse(_vaultSecretMessageType),
      from: _manager.did,
      to: [vtaDid],
      createdTime: DateTime.now().toUtc(),
      body: secret,
    );
    final encrypted = await EncryptedMessage.packWithAuthentication(
      message,
      keyPair: _manager.keyPair,
      didKeyId: managerDocument.keyAgreement.first.id,
      recipientDidDocuments: [await _resolveVta()],
    );
    return jsonEncode(encrypted.toJson());
  }

  /// The VTA's local refusal code: `details.code`, else the `<code>` of a
  /// `<task>:<code>` in the message or the top-level code.
  static String _localRefusalCode(MeetingPlaceVtcSDKException error) {
    final payload = error.errorPayload ?? const {};
    final details = payload['details'];
    if (details is Map && details['code'] is String) {
      return details['code'] as String;
    }
    for (final text in [payload['message'], error.refusalCode]) {
      if (text is! String) continue;
      final match = _innerCode.firstMatch(text);
      if (match != null) return match.group(1)!;
    }
    return error.refusalCode ?? 'unknown';
  }

  /// The `id` of each entry of a list answer.
  static List<String> _ids(Object? entries) => [
    for (final entry in _maps(entries))
      if (entry['id'] case final String id) id,
  ];

  /// The object entries of a list answer.
  static Iterable<Map<String, dynamic>> _maps(Object? list) => switch (list) {
    final List<dynamic> entries => entries.whereType<Map<String, dynamic>>(),
    _ => const [],
  };

  static bool _isSignInEntry(
    Map<String, dynamic> entry,
    String personaDid,
    String vtcDid,
  ) {
    final kind = entry['secretKind'];
    final status = entry['status'];
    final targets = entry['targets'];
    return entry['id'] is String &&
        entry['principalDid'] == personaDid &&
        (kind == didSelfIssuedSecretKind ||
            kind == _legacyDidSelfIssuedSecretKind) &&
        (status == null || status == 'active') &&
        targets is List &&
        targets.any(
          (target) =>
              target is Map &&
              target['kind'] == 'did' &&
              target['did'] == vtcDid,
        );
  }
}

/// Resolves only the VTA, to the document this client already resolved, so
/// an answer is verified against the keys its endpoint was found in.
class _ResolvedVta implements DidResolver {
  _ResolvedVta(this._document);

  final DidDocument _document;

  @override
  Future<DidDocument> resolveDid(String did) async {
    if (did != _document.id) {
      throw MeetingPlaceVtcSDKException.invalidProof('not signed by the VTA');
    }
    return _document;
  }
}
