import 'dart:convert';
import 'dart:typed_data';

import 'package:didcomm/didcomm.dart' hide TrustTaskDocument;
import 'package:ed25519_edwards/ed25519_edwards.dart' as ed;
import 'package:meeting_place_vtc/meeting_place_vtc.dart';
import 'package:ssi/ssi.dart';

/// A VTA answering Trust Tasks over DIDComm, keyed by task type, behind a
/// mediator that is an in-memory inbox.
///
/// Unpacks each forwarded request with its own key and authcrypts its
/// answer to the sender, threaded on the request message, as a VTA does.
/// Signs its answers, addressed to the requester and threaded on the
/// request document.
class FakeVta {
  FakeVta() {
    final json = DidKey.resolve(key.did).toJson()
      ..['service'] = [
        {
          'id': '${key.did}#vta-didcomm',
          'type': didCommMessagingServiceType,
          'serviceEndpoint': {
            'uri': mediatorDid,
            'accept': ['didcomm/v2'],
          },
        },
      ];
    document = DidDocument.fromJson(json);
  }

  final key = Ed25519DidKeySigner.generate();
  final _mediatorKey = Ed25519DidKeySigner.generate();
  late final DidDocument document;
  final Map<String, Map<String, dynamic>> answers = {};

  /// Answers that depend on the request's payload, ahead of [answers].
  final Map<String, Map<String, dynamic> Function(Map<String, dynamic>)>
  answerTo = {};
  final Map<String, Map<String, dynamic>> refusals = {};

  /// What `keys/export-secret` answers, by the key id asked for.
  final Map<String, Map<String, dynamic>> exportedKeys = {};
  final List<Map<String, dynamic>> received = [];

  /// The forward messages the mediator was handed.
  final List<ForwardMessage> forwarded = [];

  /// Messages waiting in the manager key's inbox.
  final List<Map<String, dynamic>> inbox = [];

  /// Every answer the VTA sent, packed as it travelled.
  final List<Map<String, dynamic>> sentAnswers = [];

  /// Signs answers with this key instead of the VTA's, when set.
  Ed25519DidKeySigner? answerSigner;

  /// Threads answer documents on this id instead of the request's, when set.
  String? answerThreadId;

  /// When true, requests reach the VTA but it never answers.
  bool isSilent = false;

  /// When set, the VTA answers with a DIDComm problem report of this code.
  String? problemCode;

  /// When true, the mediator cannot be reached.
  bool isMediatorDown = false;

  String get did => key.did;

  /// DID of the VTA's mediator.
  String get mediatorDid => _mediatorKey.did;

  /// Opens the manager key's inbox on this VTA's mediator.
  Future<VtaMailbox> openMailbox({
    required String mediatorDid,
    required DidDocument mediatorDocument,
    required DidManager manager,
  }) async {
    if (isMediatorDown) throw StateError('mediator down');
    return _FakeMailbox(this);
  }

  /// A [DidcommVtaTransport] from [manager] to this VTA, waiting [timeout].
  DidcommVtaTransport transport(
    Ed25519DidKeySigner manager, {
    DidResolver? resolver,
    Duration timeout = const Duration(seconds: 2),
  }) => DidcommVtaTransport(
    vtaDid: did,
    manager: manager,
    didResolver: resolver ?? FakeVtaResolver(this),
    openMailbox: openMailbox,
    timeout: timeout,
    pollInterval: const Duration(milliseconds: 5),
  );

  /// Answers the Trust Task [request] document.
  Future<Map<String, dynamic>> handle(Map<String, dynamic> request) async {
    received.add(request);
    final type = request['type'] as String;
    if (refusals[type] case final payload?) return _error(payload);
    if (type == VtaTask.exportSecret) {
      final keyId = (request['payload'] as Map)['keyId'];
      return _answer(request, exportedKeys[keyId] ?? const {});
    }
    return _answer(
      request,
      answerTo[type]?.call(request['payload'] as Map<String, dynamic>) ??
          answers[type] ??
          const {},
    );
  }

  Future<void> _receive(ForwardMessage forward) async {
    if (isMediatorDown) throw StateError('mediator down');
    forwarded.add(forward);
    final data = forward.attachments!.single.data!.base64!;
    final sealed =
        jsonDecode(
              utf8.decode(
                base64Url.decode(
                  data.padRight(data.length + (4 - data.length % 4) % 4, '='),
                ),
              ),
            )
            as Map<String, dynamic>;
    final request = await DidcommMessage.unpackToPlainTextMessage(
      message: sealed,
      recipientDidManager: await _didManager(),
      expectedMessageWrappingTypes: const [
        MessageWrappingType.authcryptPlaintext,
      ],
    );
    if (isSilent) {
      await handle(request.body!);
      return;
    }
    final body = problemCode != null
        ? {'code': problemCode}
        : await handle(request.body!);
    final answer = PlainTextMessage(
      id: 'urn:uuid:answer-${forwarded.length}',
      type: Uri.parse(
        problemCode != null
            ? 'https://didcomm.org/report-problem/2.0/problem-report'
            : trustTaskEnvelopeType,
      ),
      from: did,
      to: [request.from!],
      threadId: request.id,
      body: body,
    );
    final packed = await EncryptedMessage.packWithAuthentication(
      answer,
      keyPair: key.keyPair,
      didKeyId: DidKey.resolve(did).keyAgreement.first.id,
      recipientDidDocuments: [DidKey.resolve(request.from!)],
    );
    sentAnswers.add(packed.toJson());
    inbox.add(packed.toJson());
  }

  DidManager? _manager;

  Future<DidManager> _didManager() async {
    if (_manager case final manager?) return manager;
    final keyStore = InMemoryKeyStore();
    await keyStore.set(
      'vta',
      StoredKey(
        keyType: KeyType.ed25519,
        privateKeyBytes: Uint8List.fromList(ed.newKeyFromSeed(key.seed).bytes),
      ),
    );
    final manager = DidKeyManager(
      store: InMemoryDidStore(),
      wallet: PersistentWallet(keyStore),
    );
    await manager.addVerificationMethod('vta');
    return _manager = manager;
  }

  Map<String, dynamic> _error(Map<String, dynamic> payload) => {
    'id': 'urn:uuid:error',
    'type': 'https://trusttasks.org/spec/trust-task-error/0.1',
    'issuer': did,
    'payload': payload,
  };

  Future<Map<String, dynamic>> _answer(
    Map<String, dynamic> request,
    Map<String, dynamic> payload,
  ) async {
    final signer = answerSigner ?? key;
    final answer = await TrustTaskDocument.create(
      type: '${request['type']}#response',
      issuer: signer.did,
      recipient: request['issuer'] as String,
      threadId: answerThreadId ?? request['id'] as String,
      payload: payload,
    ).sign(signer, purpose: ProofPurpose.authentication);
    return answer.toJson();
  }
}

/// Resolves the fake VTA's DID to its document, and `did:key`s.
class FakeVtaResolver implements DidResolver {
  FakeVtaResolver(this._vta, [this._others = const {}]);

  final FakeVta _vta;
  final Map<String, DidDocument> _others;

  @override
  Future<DidDocument> resolveDid(String did) async {
    if (did == _vta.did) return _vta.document;
    if (_others[did] case final document?) return document;
    if (did.startsWith('did:key:')) return DidKey.resolve(did);
    throw StateError('unknown DID');
  }
}

class _FakeMailbox implements VtaMailbox {
  _FakeMailbox(this._vta);

  final FakeVta _vta;

  @override
  Future<void> send(ForwardMessage message) => _vta._receive(message);

  @override
  Future<List<Map<String, dynamic>>> take() async {
    if (_vta.isMediatorDown) throw StateError('mediator down');
    final messages = [..._vta.inbox];
    _vta.inbox.clear();
    return messages;
  }
}
