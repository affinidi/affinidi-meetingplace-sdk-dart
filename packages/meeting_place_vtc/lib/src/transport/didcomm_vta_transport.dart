import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:didcomm/didcomm.dart' hide TrustTaskDocument;
import 'package:ed25519_edwards/ed25519_edwards.dart' as ed;
import 'package:ssi/ssi.dart';
import 'package:uuid/uuid.dart';

import '../meeting_place_vtc_sdk_exception.dart';
import '../proof/trust_task_signer.dart';
import '../trust_task/trust_task_document.dart';

/// DIDComm message type that carries a Trust Task document as its body.
const trustTaskEnvelopeType =
    'https://trusttasks.org/binding/didcomm/0.1/envelope';

/// DIDComm service type naming the mediator a DID receives messages through.
const didCommMessagingServiceType = 'DIDCommMessaging';

const _problemReportType =
    'https://didcomm.org/report-problem/2.0/problem-report';

/// Marker in the type URI of a Trust Task error document.
const _trustTaskErrorMarker = '/trust-task-error/';

/// Carries signed Trust Task documents to the member's VTA and back.
abstract interface class VtaTransport {
  /// Sends [request], already signed, and returns the VTA's answer.
  ///
  /// Throws [MeetingPlaceVtcSDKException] refused with the full refusal code
  /// when the VTA answers with a Trust Task error, and with another code
  /// when there is no answer.
  Future<TrustTaskDocument> send(TrustTaskDocument request);
}

/// The manager key's inbox on the VTA's mediator.
abstract interface class VtaMailbox {
  /// Hands [message] to the mediator, to forward to its `next`.
  Future<void> send(ForwardMessage message);

  /// Takes every message waiting in the inbox, deleting them there.
  Future<List<Map<String, dynamic>>> take();
}

/// Opens the manager key's inbox on the mediator [mediatorDid].
typedef VtaMailboxOpener =
    Future<VtaMailbox> Function({
      required String mediatorDid,
      required DidDocument mediatorDocument,
      required DidManager manager,
    });

/// Sends Trust Tasks to the member's VTA over DIDComm, through the mediator
/// the VTA's DID document names, as the VTA's own clients do:
///
/// - the signed document is the body of a [trustTaskEnvelopeType] message
///   from the manager key, authcrypted to the VTA and forwarded by its
///   mediator;
/// - the VTA answers, threaded on that message, into the manager key's inbox
///   on the same mediator, where it is picked up.
///
/// The authcrypt envelope authenticates the manager key: there is no login.
/// One task is in flight at a time, so any other message in the inbox is a
/// stale answer and is dropped. A task without an answer in [timeout] is
/// not sent again: the VTA may have run it. Nothing is logged.
class DidcommVtaTransport implements VtaTransport {
  /// Creates a [DidcommVtaTransport] to [vtaDid], from [manager].
  DidcommVtaTransport({
    required this.vtaDid,
    required Ed25519DidKeySigner manager,
    required DidResolver didResolver,
    VtaMailboxOpener? openMailbox,
    this.timeout = const Duration(seconds: 30),
    this.pollInterval = const Duration(milliseconds: 700),
  }) : _manager = manager,
       _didResolver = didResolver,
       _openMailbox = openMailbox ?? _openMediatorMailbox;

  /// DID of the VTA.
  final String vtaDid;

  /// How long to wait for an answer.
  final Duration timeout;

  /// How often the inbox is checked while waiting.
  final Duration pollInterval;

  final Ed25519DidKeySigner _manager;
  final DidResolver _didResolver;
  final VtaMailboxOpener _openMailbox;

  DidDocument? _vtaDocument;
  String? _mediatorDid;
  DidManager? _managerDidManager;
  VtaMailbox? _mailbox;
  bool _isBusy = false;
  final List<Completer<void>> _waiting = [];

  @override
  Future<TrustTaskDocument> send(TrustTaskDocument request) async {
    // Futures are made per call, in the caller's zone: a queue kept across
    // calls would deliver in the zone it was made in.
    while (_isBusy) {
      final turn = Completer<void>();
      _waiting.add(turn);
      await turn.future;
    }
    _isBusy = true;
    try {
      return await _send(request);
    } finally {
      _isBusy = false;
      if (_waiting.isNotEmpty) _waiting.removeAt(0).complete();
    }
  }

  Future<TrustTaskDocument> _send(TrustTaskDocument request) async {
    final vta = await _resolveVta();
    final mailbox = await _openInbox();
    final message = PlainTextMessage(
      id: 'urn:uuid:${const Uuid().v4()}',
      type: Uri.parse(trustTaskEnvelopeType),
      from: _manager.did,
      to: [vtaDid],
      createdTime: DateTime.now().toUtc(),
      expiresTime: DateTime.now().toUtc().add(const Duration(minutes: 5)),
      body: request.toJson(),
    );
    final encrypted = await EncryptedMessage.packWithAuthentication(
      message,
      keyPair: _manager.keyPair,
      didKeyId: DidKey.resolve(_manager.did).keyAgreement.first.id,
      recipientDidDocuments: [vta],
    );
    final forward = ForwardMessage(
      id: const Uuid().v4(),
      // The mediator resolves the forward's signer from `from`.
      from: _manager.did,
      to: [_mediatorDid!],
      next: vtaDid,
      expiresTime: DateTime.now().toUtc().add(const Duration(minutes: 30)),
      attachments: [
        Attachment(
          mediaType: 'application/json',
          data: AttachmentData(
            base64: base64UrlEncode(
              utf8.encode(jsonEncode(encrypted)),
            ).replaceAll('=', ''),
          ),
        ),
      ],
    );

    try {
      await mailbox.send(forward);
    } on MeetingPlaceVtcSDKException {
      rethrow;
    } catch (error) {
      throw MeetingPlaceVtcSDKException.transportFailed(
        'mediator refused the message',
        innerException: error,
      );
    }
    return _awaitAnswer(mailbox, message.id);
  }

  Future<TrustTaskDocument> _awaitAnswer(
    VtaMailbox mailbox,
    String messageId,
  ) async {
    final deadline = DateTime.now().add(timeout);
    while (true) {
      final List<Map<String, dynamic>> messages;
      try {
        messages = await mailbox.take();
      } catch (error) {
        throw MeetingPlaceVtcSDKException.transportFailed(
          'mediator inbox unreadable',
          innerException: error,
        );
      }
      for (final raw in messages) {
        final answer = await _unpack(raw);
        if (answer == null || answer.from != vtaDid) continue;
        if (answer.threadId != messageId &&
            answer.parentThreadId != messageId) {
          continue;
        }
        return _readAnswer(answer);
      }
      if (DateTime.now().isAfter(deadline)) {
        throw MeetingPlaceVtcSDKException.transportFailed('no answer');
      }
      await Future<void>.delayed(pollInterval);
    }
  }

  /// [raw] unpacked as a message authcrypted to the manager key, or null.
  Future<PlainTextMessage?> _unpack(Map<String, dynamic> raw) async {
    try {
      return await DidcommMessage.unpackToPlainTextMessage(
        message: raw,
        recipientDidManager: await _managerManager(),
        expectedMessageWrappingTypes: const [
          MessageWrappingType.authcryptPlaintext,
          MessageWrappingType.authcryptSignPlaintext,
        ],
      );
    } catch (_) {
      // Not for this key, or not from an authenticated sender.
      return null;
    }
  }

  static TrustTaskDocument _readAnswer(PlainTextMessage answer) {
    final body = answer.body ?? const <String, dynamic>{};
    if (answer.type.toString() == _problemReportType) {
      final code = body['code'];
      throw MeetingPlaceVtcSDKException.refused(
        code is String ? code : 'unknown',
        errorPayload: body,
      );
    }
    final type = body['type'];
    if (type is String && type.contains(_trustTaskErrorMarker)) {
      final payload = body['payload'];
      final errorPayload = payload is Map<String, dynamic> ? payload : null;
      final code = errorPayload?['code'];
      throw MeetingPlaceVtcSDKException.refused(
        code is String ? code : 'unknown',
        errorPayload: errorPayload,
      );
    }
    return TrustTaskDocument.fromJson(Map<String, dynamic>.of(body));
  }

  Future<DidDocument> _resolveVta() async {
    if (_vtaDocument case final document?) return document;
    final DidDocument document;
    try {
      document = await _didResolver.resolveDid(vtaDid);
    } catch (error) {
      throw MeetingPlaceVtcSDKException.didResolutionFailed(
        innerException: error,
      );
    }
    if (document.id != vtaDid) {
      throw MeetingPlaceVtcSDKException.didResolutionFailed();
    }
    final mediatorDid = mediatorDidOf(document);
    if (mediatorDid == null) {
      throw MeetingPlaceVtcSDKException.signInNotOffered(
        didCommMessagingServiceType,
      );
    }
    _mediatorDid = mediatorDid;
    return _vtaDocument = document;
  }

  Future<VtaMailbox> _openInbox() async {
    if (_mailbox case final mailbox?) return mailbox;
    final mediatorDid = _mediatorDid!;
    final DidDocument mediatorDocument;
    try {
      mediatorDocument = await _didResolver.resolveDid(mediatorDid);
    } catch (error) {
      throw MeetingPlaceVtcSDKException.didResolutionFailed(
        innerException: error,
      );
    }
    try {
      return _mailbox = await _openMailbox(
        mediatorDid: mediatorDid,
        mediatorDocument: mediatorDocument,
        manager: await _managerManager(),
      );
    } catch (error) {
      throw MeetingPlaceVtcSDKException.transportFailed(
        'mediator unreachable',
        innerException: error,
      );
    }
  }

  /// The manager key as a [DidManager], which DIDComm unpacks with. Held in
  /// memory only.
  Future<DidManager> _managerManager() async {
    if (_managerDidManager case final manager?) return manager;
    final keyStore = InMemoryKeyStore();
    const keyId = 'manager';
    await keyStore.set(
      keyId,
      StoredKey(
        keyType: KeyType.ed25519,
        privateKeyBytes: Uint8List.fromList(
          ed.newKeyFromSeed(_manager.seed).bytes,
        ),
      ),
    );
    final manager = DidKeyManager(
      store: InMemoryDidStore(),
      wallet: PersistentWallet(keyStore),
    );
    await manager.addVerificationMethod(keyId);
    return _managerDidManager = manager;
  }

  static Future<VtaMailbox> _openMediatorMailbox({
    required String mediatorDid,
    required DidDocument mediatorDocument,
    required DidManager manager,
  }) async {
    final client = await MediatorClient.init(
      mediatorDidDocument: mediatorDocument,
      didManager: manager,
      forwardMessageOptions: vtaForwardMessageOptions,
      authorizationProvider: await AffinidiAuthorizationProvider.init(
        mediatorDidDocument: mediatorDocument,
        didManager: manager,
      ),
    );
    return _MediatorMailbox(client);
  }
}

/// How a task is wrapped for the mediator. Signed: a mediator that blocks
/// anonymous outer envelopes refuses the forward otherwise, as the task
/// inside is encrypted for the VTA alone.
const vtaForwardMessageOptions = ForwardMessageOptions(
  shouldSign: true,
  shouldEncrypt: true,
  keyWrappingAlgorithm: KeyWrappingAlgorithm.ecdhEs,
  encryptionAlgorithm: EncryptionAlgorithm.a256cbc,
);

/// The DID of the mediator [document]'s `DIDCommMessaging` service names,
/// or null when it names none.
String? mediatorDidOf(DidDocument document) {
  for (final service in document.service) {
    if (service.type != const StringServiceType(didCommMessagingServiceType)) {
      continue;
    }
    for (final uri in _uris(service.serviceEndpoint)) {
      if (uri.startsWith('did:')) return uri;
    }
  }
  return null;
}

Iterable<String> _uris(ServiceEndpointValue endpoint) sync* {
  switch (endpoint) {
    case StringEndpoint(:final url):
      yield url;
    case MapEndpoint(:final data):
      if (data['uri'] case final String uri) yield uri;
    case SetEndpoint(:final endpoints):
      for (final entry in endpoints) {
        yield* _uris(entry);
      }
  }
}

class _MediatorMailbox implements VtaMailbox {
  _MediatorMailbox(this._client);

  final MediatorClient _client;

  @override
  Future<void> send(ForwardMessage message) => _client.sendMessage(message);

  @override
  Future<List<Map<String, dynamic>>> take() => _client.fetchMessages();
}
