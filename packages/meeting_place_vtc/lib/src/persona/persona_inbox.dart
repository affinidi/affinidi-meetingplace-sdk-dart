import 'dart:async';

import 'package:didcomm/didcomm.dart' hide TrustTaskDocument;
import 'package:ssi/ssi.dart';

import '../credentials/credential_fields.dart';
import '../groups/group_admission.dart';
import '../meeting_place_vtc_sdk_exception.dart';
import '../proof/eddsa_jcs_2022.dart';
import '../transport/didcomm_vta_transport.dart';
import '../trust_task/trust_task_document.dart';
import 'persona_did_manager.dart';

/// Trust Task a community issues a credential to its holder with.
const credentialIssueTask =
    'https://trusttasks.org/spec/credential-exchange/issue/0.1';

/// Trust Task a community tells a member it removed them with.
const memberRemovalNoticeTask =
    'https://trusttasks.org/spec/vtc/members/removal-notice/0.1';

/// A DID's inbox on its mediator.
abstract interface class MediatorInbox {
  /// Ids of the messages waiting.
  Future<List<String>> listIds();

  /// The message [id], left in the inbox, or null when it is gone.
  Future<Map<String, dynamic>?> fetch(String id);

  /// Deletes the messages [ids] from the inbox.
  Future<void> delete(List<String> ids);

  /// Fires each time a message reaches the inbox, over a live connection to
  /// the mediator held while listened to; also for those waiting when it
  /// connects. Leaves them in the inbox.
  Stream<void> arrivals();

  /// Ends the session with the mediator.
  Future<void> close();
}

/// Signs in to the mediator [mediatorDid] as [manager] and opens its inbox.
typedef MediatorInboxOpener =
    Future<MediatorInbox> Function({
      required String mediatorDid,
      required DidDocument mediatorDocument,
      required DidManager manager,
    });

/// A credential a community issued to the persona, as it lies in the
/// persona's inbox.
class IssuedCredential {
  /// Creates an [IssuedCredential].
  const IssuedCredential({
    required this.messageId,
    required this.document,
    required this.credential,
  });

  /// Id of the message in the inbox, to [PersonaInbox.remove] it by.
  final String messageId;

  /// The community's signed `credential-exchange/issue` document.
  final TrustTaskDocument document;

  /// The credential it issues.
  final Map<String, dynamic> credential;
}

/// A Trust Task document a peer sent the persona, as it lies in the
/// persona's inbox.
class PeerDocument {
  /// Creates a [PeerDocument].
  const PeerDocument({required this.messageId, required this.document});

  /// Id of the message in the inbox, to [PersonaInbox.remove] it by.
  final String messageId;

  /// The peer's signed document, exactly as received.
  final TrustTaskDocument document;
}

/// A community's signed notice that it removed the persona, as it lies in
/// the persona's inbox.
class RemovalNotice {
  /// Creates a [RemovalNotice].
  const RemovalNotice({
    required this.messageId,
    required this.document,
    required this.code,
    required this.disposition,
    required this.decidedAt,
    required this.decidedBy,
    this.reason,
  });

  /// Id of the message in the inbox, to [PersonaInbox.remove] it by.
  final String messageId;

  /// The community's signed `members/removal-notice` document, exactly as
  /// received, to show to someone else, e.g. in an appeal.
  final TrustTaskDocument document;

  /// Which removal happened, e.g. `adminRemoved` or `purged`.
  final String code;

  /// How the community handled the member's published record, e.g.
  /// `tombstone`.
  final String disposition;

  /// When the community decided the removal, not when it sent the notice.
  final DateTime decidedAt;

  /// DID of who decided it.
  final String decidedBy;

  /// Why, as the community gave it; null when it gave no reason.
  final String? reason;
}

/// What one look into the inbox found.
class InboxPickup {
  /// Creates an [InboxPickup].
  const InboxPickup({required this.waiting, required this.credentials});

  /// How many messages were waiting, of any kind.
  final int waiting;

  /// The credentials among them the asked community issued.
  final List<IssuedCredential> credentials;
}

/// The inbox of a persona on its mediator, read as the persona with keys its
/// VTA lent ([PersonaDidManager]).
///
/// Takes only what a community issued to the persona and leaves everything
/// else where it is, such as a TSP copy or another sender's message, so
/// nothing this client cannot read is ever taken for delivered. Removes a
/// message only when asked to, once its credential is kept. Nothing is
/// logged.
class PersonaInbox {
  /// Creates a [PersonaInbox] for [persona].
  PersonaInbox({
    required PersonaDidManager persona,
    required DidResolver didResolver,
    MediatorInboxOpener? openInbox,
  }) : _persona = persona,
       _didResolver = didResolver,
       _openInbox = openInbox ?? _openMediatorInbox;

  final PersonaDidManager _persona;
  final DidResolver _didResolver;
  final MediatorInboxOpener _openInbox;
  MediatorInbox? _inbox;
  String? _mediatorDid;

  /// DID of the mediator the persona's DID document names, once [open].
  String? get mediatorDid => _mediatorDid;

  /// Signs in to the persona's mediator. Does nothing when already open.
  ///
  /// Throws [MeetingPlaceVtcSDKException] with a `signInNotOffered` code when
  /// the persona's DID document names no DIDComm mediator, and with a
  /// `transportFailed` code when the mediator cannot be reached.
  Future<void> open() async {
    if (_inbox != null) return;
    final document = await _persona.getDidDocument();
    final mediatorDid = mediatorDidOf(document);
    if (mediatorDid == null) {
      throw MeetingPlaceVtcSDKException.signInNotOffered(
        didCommMessagingServiceType,
      );
    }
    final DidDocument mediatorDocument;
    try {
      mediatorDocument = await _didResolver.resolveDid(mediatorDid);
    } catch (error) {
      throw MeetingPlaceVtcSDKException.didResolutionFailed(
        innerException: error,
      );
    }
    try {
      _inbox = await _openInbox(
        mediatorDid: mediatorDid,
        mediatorDocument: mediatorDocument,
        manager: _persona,
      );
    } catch (error) {
      throw MeetingPlaceVtcSDKException.transportFailed(
        'mediator unreachable',
        innerException: error,
      );
    }
    _mediatorDid = mediatorDid;
  }

  /// The credentials [issuerDid] issued to the persona that wait in the
  /// inbox, each in a `credential-exchange/issue` document [issuerDid]
  /// signed for the persona. Leaves them there.
  ///
  /// The document's proof is what authenticates the community, so the
  /// envelope may be authcrypt or anoncrypt; an authcrypt sender must be
  /// [issuerDid]. Throws [MeetingPlaceVtcSDKException] with a
  /// `transportFailed` code when the inbox cannot be read.
  Future<InboxPickup> issuedCredentials({required String issuerDid}) => _pickUp(
    issuerDid,
    accepts: (credential) =>
        credentialIssuer(credential) == issuerDid &&
        credentialSubjects(credential).contains(_persona.did),
  );

  /// The credentials of the community [communityDid]'s groups [groupDids]
  /// that wait in the inbox, each in a `credential-exchange/issue` document
  /// the community signed for the persona: a group's membership credential
  /// about the persona, issued by the group's DID, and the community's
  /// authority credential to a group, which comes with it. Leaves them
  /// there.
  ///
  /// Throws as [issuedCredentials] does.
  Future<InboxPickup> groupCredentials({
    required String communityDid,
    required Set<String> groupDids,
  }) => _pickUp(
    communityDid,
    accepts: (credential) {
      final issuer = credentialIssuer(credential);
      final subjects = credentialSubjects(credential);
      final types = credentialTypes(credential);
      return (groupDids.contains(issuer) &&
              subjects.contains(_persona.did) &&
              types.contains(GroupAdmissionVerifier.membershipType)) ||
          (issuer == communityDid &&
              subjects.any(groupDids.contains) &&
              types.contains(GroupAdmissionVerifier.authorityType));
    },
  );

  /// The notices waiting in the inbox that [communityDid] removed the
  /// persona, each in a `members/removal-notice` document [communityDid]
  /// signed for the persona about the persona. Leaves them there.
  ///
  /// Read as [issuedCredentials] reads cards: the proof authenticates the
  /// community. A notice missing what it must say is left alone. Throws as
  /// [issuedCredentials] does.
  Future<List<RemovalNotice>> removalNotices({
    required String communityDid,
  }) async {
    final notices = <RemovalNotice>[];
    for (final (id, raw) in await _messages()) {
      final document = await _readEnveloped(
        raw,
        type: memberRemovalNoticeTask,
        issuerDid: communityDid,
      );
      if (document == null) continue;
      final notice = switch (document.payload) {
        {
          'did': final String did,
          'code': final String code,
          'disposition': final String disposition,
          'decidedAt': final String decidedAt,
          'decidedBy': final String decidedBy,
        }
            when did == _persona.did =>
          switch (DateTime.tryParse(decidedAt)) {
            final decided? => RemovalNotice(
              messageId: id,
              document: document,
              code: code,
              disposition: disposition,
              decidedAt: decided,
              decidedBy: decidedBy,
              reason: switch (document.payload['reason']) {
                final String reason when reason.trim().isNotEmpty => reason,
                _ => null,
              },
            ),
            null => null,
          },
        _ => null,
      };
      if (notice != null) notices.add(notice);
    }
    return notices;
  }

  /// The credentials in `credential-exchange/issue` documents [senderDid]
  /// signed for the persona that [accepts], waiting in the inbox.
  Future<InboxPickup> _pickUp(
    String senderDid, {
    required bool Function(Map<String, dynamic> credential) accepts,
  }) async {
    final messages = await _messages();
    final credentials = <IssuedCredential>[];
    for (final (id, raw) in messages) {
      final issued = await _readIssue(id, raw, senderDid, accepts);
      if (issued != null) credentials.add(issued);
    }
    return InboxPickup(waiting: messages.length, credentials: credentials);
  }

  /// The documents of [types] that [senderDid], or anyone when null, sent
  /// the persona and signed, oldest first as the mediator lists them.
  /// Leaves them there.
  ///
  /// Only an authcrypt message counts, typed as the task its document is,
  /// whose document its authenticated sender issued to the persona and
  /// signed for `authentication`. Throws [MeetingPlaceVtcSDKException] with
  /// a `transportFailed` code when the inbox cannot be read.
  Future<List<PeerDocument>> peerDocuments({
    String? senderDid,
    required Set<String> types,
  }) async {
    final documents = <PeerDocument>[];
    for (final (id, raw) in await _messages()) {
      final message = await _unpack(raw, authenticatedOnly: true);
      final from = message?.from;
      if (message == null ||
          from == null ||
          (senderDid != null && from != senderDid) ||
          !types.contains(message.type.toString())) {
        continue;
      }
      final document = await _readDocument(
        message,
        type: message.type.toString(),
        issuerDid: from,
      );
      if (document != null) {
        documents.add(PeerDocument(messageId: id, document: document));
      }
    }
    return documents;
  }

  /// Every message waiting, by id.
  Future<List<(String, Map<String, dynamic>)>> _messages() async {
    final inbox = _openedInbox();
    try {
      final messages = <(String, Map<String, dynamic>)>[];
      for (final id in await inbox.listIds()) {
        if (await inbox.fetch(id) case final raw?) messages.add((id, raw));
      }
      return messages;
    } catch (error) {
      throw MeetingPlaceVtcSDKException.transportFailed(
        'mediator inbox unreadable',
        innerException: error,
      );
    }
  }

  /// Fires each time a message reaches the persona's inbox, while listened
  /// to, e.g. to [issuedCredentials] again; what arrived is read only
  /// there, where it is checked. Requires [open].
  ///
  /// Errors with [MeetingPlaceVtcSDKException] with a `transportFailed` code
  /// when the live connection fails.
  Stream<void> arrivals() => _openedInbox().arrivals().handleError(
    (Object error) => throw MeetingPlaceVtcSDKException.transportFailed(
      'mediator connection failed',
      innerException: error,
    ),
  );

  /// Deletes the messages [messageIds] from the inbox, once handled.
  ///
  /// Throws [MeetingPlaceVtcSDKException] with a `transportFailed` code when
  /// the mediator refuses.
  Future<void> remove(List<String> messageIds) async {
    if (messageIds.isEmpty) return;
    try {
      await _openedInbox().delete(messageIds);
    } catch (error) {
      throw MeetingPlaceVtcSDKException.transportFailed(
        'mediator refused to delete',
        innerException: error,
      );
    }
  }

  /// Ends the session with the mediator, best effort. Leaves the persona's
  /// keys to their owner to forget.
  Future<void> close() async {
    final inbox = _inbox;
    _inbox = null;
    try {
      await inbox?.close();
    } catch (_) {
      // The session ends on the mediator's side all the same.
    }
  }

  MediatorInbox _openedInbox() =>
      _inbox ?? (throw StateError('persona inbox not open'));

  /// [raw] read as [issuerDid]'s issue to the persona of a credential that
  /// [accepts], or null when it is anything else.
  Future<IssuedCredential?> _readIssue(
    String messageId,
    Map<String, dynamic> raw,
    String issuerDid,
    bool Function(Map<String, dynamic> credential) accepts,
  ) async {
    final document = await _readEnveloped(
      raw,
      type: credentialIssueTask,
      issuerDid: issuerDid,
    );
    if (document == null) return null;

    final credential = switch (document.payload['credential_response']) {
      {'credential': final Map<String, dynamic> credential} => credential,
      _ => null,
    };
    if (credential == null || !accepts(credential)) return null;
    return IssuedCredential(
      messageId: messageId,
      document: document,
      credential: credential,
    );
  }

  /// [raw] read as a [type] document [issuerDid] signed for the persona, in
  /// a Trust Task envelope, or null when it is anything else. The envelope
  /// may be anoncrypt, as the proof authenticates [issuerDid]; an authcrypt
  /// sender must be [issuerDid].
  Future<TrustTaskDocument?> _readEnveloped(
    Map<String, dynamic> raw, {
    required String type,
    required String issuerDid,
  }) async {
    final message = await _unpack(raw, authenticatedOnly: false);
    if (message == null) return null;
    if (message.from case final from? when from != issuerDid) return null;
    if (message.type.toString() != trustTaskEnvelopeType) return null;
    return _readDocument(message, type: type, issuerDid: issuerDid);
  }

  /// [raw] unpacked as a message sealed to the persona, or null when it is
  /// not one, e.g. a TSP copy. Only authcrypt when [authenticatedOnly].
  Future<PlainTextMessage?> _unpack(
    Map<String, dynamic> raw, {
    required bool authenticatedOnly,
  }) async {
    try {
      return await DidcommMessage.unpackToPlainTextMessage(
        message: raw,
        recipientDidManager: _persona,
        expectedMessageWrappingTypes: [
          MessageWrappingType.authcryptPlaintext,
          MessageWrappingType.authcryptSignPlaintext,
          if (!authenticatedOnly) ...[
            MessageWrappingType.anoncryptPlaintext,
            MessageWrappingType.anoncryptSignPlaintext,
            MessageWrappingType.anoncryptAuthcryptPlaintext,
          ],
        ],
      );
    } catch (_) {
      return null;
    }
  }

  /// [message]'s body read as a [type] document [issuerDid] issued to the
  /// persona and signed, or null when it is anything else.
  Future<TrustTaskDocument?> _readDocument(
    PlainTextMessage message, {
    required String type,
    required String issuerDid,
  }) async {
    final TrustTaskDocument document;
    try {
      document = TrustTaskDocument.fromJson(
        Map<String, dynamic>.of(message.body ?? const {}),
      );
    } on MeetingPlaceVtcSDKException {
      return null;
    }
    if (document.type != type ||
        document.issuer != issuerDid ||
        document.recipient != _persona.did) {
      return null;
    }
    try {
      await EddsaJcs2022.verify(
        document.toJson(),
        purpose: ProofPurpose.authentication,
        resolver: _didResolver,
        expectedSigner: issuerDid,
      );
    } on MeetingPlaceVtcSDKException {
      return null;
    }
    return document;
  }

  static Future<MediatorInbox> _openMediatorInbox({
    required String mediatorDid,
    required DidDocument mediatorDocument,
    required DidManager manager,
  }) async {
    // A pool of its own: starting it leaves the app's other mediator
    // connections, in the shared pool, as they are.
    final pool = ConnectionPool();
    final client = await MediatorClient.init(
      mediatorDidDocument: mediatorDocument,
      didManager: manager,
      authorizationProvider: await AffinidiAuthorizationProvider.init(
        mediatorDidDocument: mediatorDocument,
        didManager: manager,
      ),
      connectionPool: pool,
      // Messages stay until handled: the caller removes them once kept.
      webSocketOptions: const WebSocketOptions(
        deleteOnReceive: false,
        statusRequestMessageOptions: StatusRequestMessageOptions(
          shouldSend: true,
          shouldSign: true,
          shouldEncrypt: true,
        ),
        liveDeliveryChangeMessageOptions: LiveDeliveryChangeMessageOptions(
          shouldSend: true,
          shouldSign: true,
          shouldEncrypt: true,
        ),
      ),
    );
    return _MediatorClientInbox(client, pool);
  }
}

class _MediatorClientInbox implements MediatorInbox {
  _MediatorClientInbox(this._client, this._pool);

  final MediatorClient _client;
  final ConnectionPool _pool;

  @override
  Future<List<String>> listIds() => _client.listInboxMessageIds();

  @override
  Future<Map<String, dynamic>?> fetch(String id) async =>
      (await _client.fetchMessagesByIds([
        id,
      ], deleteOnMediator: false)).firstOrNull;

  @override
  Future<void> delete(List<String> ids) =>
      _client.deleteMessages(messageIds: ids);

  @override
  Stream<void> arrivals() {
    late final StreamController<void> arrived;
    arrived = StreamController<void>(
      onListen: () {
        _client.listenForIncomingMessages(
          (_) {
            if (!arrived.isClosed) arrived.add(null);
          },
          onError: arrived.addError,
          onDone: ({closeCode, closeReason}) => arrived.close(),
        );
        _pool.startConnections().catchError(arrived.addError);
      },
      onCancel: _client.disconnect,
    );
    return arrived.stream;
  }

  @override
  Future<void> close() => _client.disconnect();
}
