import 'dart:convert';

import 'package:didcomm/didcomm.dart' show EncryptedMessage, PlainTextMessage;
import 'package:ssi/ssi.dart';
import 'package:uuid/uuid.dart';

import '../meeting_place_vtc_sdk_error_code.dart';
import '../meeting_place_vtc_sdk_exception.dart';
import '../proof/trust_task_signer.dart';
import '../sign_in/sign_in_agent.dart';
import '../transport/trust_task_http_transport.dart';
import '../trust_task/trust_task_document.dart';
import '../vtc/service_endpoints.dart';
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
  static const vaultList = '$_base/vault/list/0.1';

  /// Creates or updates a vault entry.
  static const vaultUpsert = '$_base/vault/upsert/0.1';

  /// Finds stored credentials by purpose.
  static const credentialsQuery = '$_base/vault/credentials/query/0.1';

  /// Fetches one stored credential.
  static const credentialsGet = '$_base/vault/credentials/get/0.1';

  /// Stores a credential the member received.
  static const credentialsReceive = '$_base/vault/credentials/receive/0.1';

  /// Lists the VTA contexts this client may act in.
  static const contextsList = '$_base/vta/contexts/list/1.0';

  /// Lists the servers the VTA publishes `did:webvh` DIDs on.
  static const serversList = '$_base/vta/webvh/servers/list/1.0';

  /// Creates a `did:webvh` DID whose keys the VTA holds.
  static const didsCreate = '$_base/vta/webvh/dids/create/1.0';

  /// Lists the `did:webvh` DIDs the VTA hosts keys for.
  static const didsList = '$_base/vta/webvh/dids/list/1.0';

  /// Registers this phone as a device.
  static const deviceRegister = '$_base/device/register/0.2';

  /// Refreshes this phone's device binding.
  static const deviceHeartbeat = '$_base/device/heartbeat/0.2';
}

/// DID document service type of a VTA's REST Trust Task base.
const vtaRestServiceType = 'VTARest';

/// Device extension that enrols the phone's biometric approval key.
const uvKeyExtension = 'org.openvtc.uv-key';

/// The context a VTA creates by default; personas go there when it exists.
const _defaultContextId = 'vta';

/// Vault secret kind of a persona's sign-in entry.
const didSelfIssuedSecretKind = 'did-self-issued';

/// Type of the DIDComm message a sealed vault secret travels in.
const _vaultSecretMessageType =
    'https://trusttasks.org/spec/vault/_shared/0.1/vault-secret';

/// A Trust Task client for the member's VTA, over its REST binding.
///
/// Signs every request as the phone's manager key, which the VTA's access
/// list must hold. Authenticates lazily and again once when the bearer token
/// is rejected. Nothing is logged.
class VtaClient implements SignInAgent {
  /// Creates a [VtaClient] for the VTA [vtaDid], acting as [manager].
  VtaClient({
    required this.vtaDid,
    required Ed25519DidKeySigner manager,
    DidResolver? didResolver,
    TrustTaskHttpTransport? transport,
  }) : _manager = manager,
       _didResolver = didResolver ?? UniversalDIDResolver.defaultResolver,
       _transport = transport ?? TrustTaskHttpTransport();

  static const _unauthorized = 401;
  static final _innerCode = RegExp(r'\b[a-z][a-z/-]*:([A-Za-z_]+)');

  @override
  final String vtaDid;

  final Ed25519DidKeySigner _manager;
  final DidResolver _didResolver;
  final TrustTaskHttpTransport _transport;

  DidDocument? _vtaDocument;
  Uri? _restBase;
  String? _accessToken;

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

  /// Checks that [vtaDid] resolves to a VTA that answers, before the manager
  /// key is granted: resolves the DID, finds its REST endpoint, and asks for
  /// a challenge, which a VTA answers for any key.
  ///
  /// Throws [MeetingPlaceVtcSDKException] with
  /// [MeetingPlaceVtcSDKErrorCode.didResolutionFailed] when the DID does not
  /// resolve, [MeetingPlaceVtcSDKErrorCode.signInNotOffered] when it names no
  /// HTTPS VTA endpoint, and another code when the VTA cannot be reached.
  Future<void> checkReachable() async {
    await _transport.send(
      await _resolveRestBase(),
      TrustTaskDocument.create(
        type: VtaTask.challenge,
        issuer: _manager.did,
        recipient: vtaDid,
        payload: {'subject': _manager.did},
      ),
    );
  }

  /// Ends every session the VTA holds for the manager key, best effort.
  ///
  /// Does not remove the key from the VTA's access list: only its
  /// administrator can.
  Future<void> signOut() async {
    if (_accessToken == null) return;
    try {
      await _send(VtaTask.revokeSession, {'all': true, 'reason': 'unlinked'});
    } on MeetingPlaceVtcSDKException {
      // The session expires on its own.
    } finally {
      _accessToken = null;
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
        'envelope': 'didcomm-authcrypt',
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
  /// there, else in the first context it may. It advertises no messaging
  /// service: this phone reaches the community over HTTPS only.
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
    final serverIds = _ids(
      (await _task(VtaTask.serversList, const {}))['servers'],
    );
    if (serverIds.isEmpty) {
      throw MeetingPlaceVtcSDKException.didHostingMissing();
    }

    final created = await _task(VtaTask.didsCreate, {
      'contextId': contextIds.contains(_defaultContextId)
          ? _defaultContextId
          : contextIds.first,
      'serverId': serverIds.first,
      'label': label,
      'addMediatorService': false,
      'setPrimary': false,
    });
    final did = created['did'];
    final contextId = created['contextId'];
    final signingKeyId = created['signingKeyId'];
    if (did is! String || contextId is! String || signingKeyId is! String) {
      throw MeetingPlaceVtcSDKException.invalidDocument('no created persona');
    }
    return VtaPersona(
      did: did,
      contextId: contextId,
      signingKeyId: signingKeyId,
    );
  }

  /// Stores [credential] in the vault, in the context [contextId] of the
  /// persona it was issued to.
  ///
  /// The VTA verifies the credential's proofs against its issuer before it
  /// stores it, and files a membership credential under purpose
  /// `membership`.
  Future<void> keepCredential(
    Map<String, dynamic> credential, {
    required String contextId,
  }) async {
    await _task(VtaTask.credentialsReceive, {
      'credential': credential,
      'contextId': contextId,
    });
  }

  /// Returns the credentials stored in the vault for [purpose], e.g.
  /// `membership`.
  Future<List<Map<String, dynamic>>> credentials(String purpose) async {
    final answer = await _task(VtaTask.credentialsQuery, {'purpose': purpose});
    final ids = _ids(answer['credentials']);

    final credentials = <Map<String, dynamic>>[];
    for (final id in ids) {
      final got = await _task(VtaTask.credentialsGet, {'id': id});
      final credential = got['credential'];
      if (credential is Map<String, dynamic>) credentials.add(credential);
    }
    return credentials;
  }

  /// Sends a signed task and returns the answer's payload, authenticating
  /// first when needed and once more when the token is rejected.
  Future<Map<String, dynamic>> _task(
    String type,
    Map<String, dynamic> payload, {
    bool verifyAnswer = false,
  }) async {
    await _authenticateIfNeeded();
    try {
      return await _send(type, payload, verifyAnswer: verifyAnswer);
    } on MeetingPlaceVtcSDKException catch (error) {
      if (error.httpStatus != _unauthorized) rethrow;
      _accessToken = null;
      await _authenticateIfNeeded();
      return _send(type, payload, verifyAnswer: verifyAnswer);
    }
  }

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
      answer = await _transport.send(
        _restBase!,
        request,
        bearerToken: _accessToken,
      );
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

  Future<void> _authenticateIfNeeded() async {
    if (_accessToken != null) return;
    final restBase = await _resolveRestBase();

    final challenge = await _transport.send(
      restBase,
      TrustTaskDocument.create(
        type: VtaTask.challenge,
        issuer: _manager.did,
        recipient: vtaDid,
        payload: {'subject': _manager.did},
      ),
    );
    final authenticate = await TrustTaskDocument.create(
      type: VtaTask.authenticate,
      issuer: _manager.did,
      recipient: vtaDid,
      payload: {
        'sessionId': challenge.payload['sessionId'],
        'challenge': challenge.payload['challenge'],
      },
    ).sign(_manager, purpose: ProofPurpose.authentication);
    final answer = await _transport.send(restBase, authenticate);

    final tokens = answer.payload['tokens'];
    final token = tokens is Map<String, dynamic>
        ? tokens['accessToken'] ?? tokens['access_token']
        : null;
    if (token is! String) {
      throw MeetingPlaceVtcSDKException.invalidDocument('no access token');
    }
    _accessToken = token;
  }

  Future<Uri> _resolveRestBase() async {
    if (_restBase case final base?) return base;
    final document = await _resolveVta();
    final base = serviceEndpointOfType(document, vtaRestServiceType);
    if (base == null) {
      throw MeetingPlaceVtcSDKException.signInNotOffered(vtaRestServiceType);
    }
    return _restBase = base;
  }

  Future<DidDocument> _resolveVta() async {
    if (_vtaDocument case final document?) return document;
    try {
      final document = await _didResolver.resolveDid(vtaDid);
      if (document.id != vtaDid) {
        throw MeetingPlaceVtcSDKException.didResolutionFailed();
      }
      return _vtaDocument = document;
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
  static List<String> _ids(Object? entries) => switch (entries) {
    final List<dynamic> list =>
      list
          .whereType<Map<String, dynamic>>()
          .map((entry) => entry['id'])
          .whereType<String>()
          .toList(),
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
        (kind == didSelfIssuedSecretKind || kind == 'didSelfIssued') &&
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
