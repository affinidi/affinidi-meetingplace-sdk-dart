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

/// A DID's inbox on its mediator.
abstract interface class MediatorInbox {
  /// Ids of the messages waiting.
  Future<List<String>> listIds();

  /// The message [id], left in the inbox, or null when it is gone.
  Future<Map<String, dynamic>?> fetch(String id);

  /// Deletes the messages [ids] from the inbox.
  Future<void> delete(List<String> ids);

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
  Future<InboxPickup> issuedCredentials({required String issuerDid}) =>
      _pickUp(
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

  /// The documents of [types] that [senderDid] sent the persona and signed,
  /// oldest first as the mediator lists them. Leaves them there.
  ///
  /// Only an authcrypt message from [senderDid] counts, typed as the task
  /// its document is, whose document [senderDid] issued to the persona and
  /// signed for `authentication`. Throws [MeetingPlaceVtcSDKException] with
  /// a `transportFailed` code when the inbox cannot be read.
  Future<List<PeerDocument>> peerDocuments({
    required String senderDid,
    required Set<String> types,
  }) async {
    final documents = <PeerDocument>[];
    for (final (id, raw) in await _messages()) {
      final message = await _unpack(raw, authenticatedOnly: true);
      if (message == null ||
          message.from != senderDid ||
          !types.contains(message.type.toString())) {
        continue;
      }
      final document = await _readDocument(
        message,
        type: message.type.toString(),
        issuerDid: senderDid,
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
    final message = await _unpack(raw, authenticatedOnly: false);
    if (message == null) return null;
    if (message.from case final from? when from != issuerDid) return null;
    if (message.type.toString() != trustTaskEnvelopeType) return null;
    final document = await _readDocument(
      message,
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
    final client = await MediatorClient.init(
      mediatorDidDocument: mediatorDocument,
      didManager: manager,
      authorizationProvider: await AffinidiAuthorizationProvider.init(
        mediatorDidDocument: mediatorDocument,
        didManager: manager,
      ),
    );
    return _MediatorClientInbox(client);
  }
}

class _MediatorClientInbox implements MediatorInbox {
  _MediatorClientInbox(this._client);

  final MediatorClient _client;

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
  Future<void> close() => _client.disconnect();
}
