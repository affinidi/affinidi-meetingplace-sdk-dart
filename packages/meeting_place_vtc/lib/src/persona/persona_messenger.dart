import 'dart:convert';

import 'package:didcomm/didcomm.dart' hide TrustTaskDocument;
import 'package:ssi/ssi.dart';
import 'package:uuid/uuid.dart';

import '../meeting_place_vtc_sdk_exception.dart';
import '../transport/didcomm_vta_transport.dart';
import '../trust_task/trust_task_document.dart';
import 'persona_did_manager.dart';

/// A session with a peer's mediator, to hand it messages to forward.
abstract interface class MediatorOutbox {
  /// Hands [message] to the mediator, to forward to its `next`.
  Future<void> send(ForwardMessage message);

  /// Ends the session with the mediator.
  Future<void> close();
}

/// Signs in to the mediator [mediatorDid] as [manager] to send through it.
typedef MediatorOutboxOpener =
    Future<MediatorOutbox> Function({
      required String mediatorDid,
      required DidDocument mediatorDocument,
      required DidManager manager,
    });

/// Sends Trust Task documents from a persona to another member, such as a
/// vetter, over DIDComm, as the persona's keys its VTA lent
/// ([PersonaDidManager]).
///
/// A document travels the way peers expect it: the body of a plaintext
/// message typed as the task itself, authcrypted from the persona to the
/// peer and forwarded by the mediator the peer's DID document names. The
/// peer answers into the persona's inbox (`PersonaInbox.peerDocuments`).
/// Nothing is logged.
class PersonaMessenger {
  /// Creates a [PersonaMessenger] for [persona].
  PersonaMessenger({
    required PersonaDidManager persona,
    required DidResolver didResolver,
    MediatorOutboxOpener? openOutbox,
  }) : _persona = persona,
       _didResolver = didResolver,
       _openOutbox = openOutbox ?? _openMediatorOutbox;

  final PersonaDidManager _persona;
  final DidResolver _didResolver;
  final MediatorOutboxOpener _openOutbox;

  /// How long a sent message stays deliverable: a person answers it.
  static const messageLifetime = Duration(minutes: 15);

  /// Sends [document], signed as the persona, to its `recipient`.
  ///
  /// Accepted by the mediator is not delivered: the answer, if any, arrives
  /// in the persona's inbox. Throws [MeetingPlaceVtcSDKException] with a
  /// `signInNotOffered` code when the recipient names no DIDComm mediator,
  /// e.g. when it speaks TSP only, a `didResolutionFailed` code when a DID
  /// cannot be resolved, and a `transportFailed` code when the mediator
  /// cannot be reached or refuses.
  Future<void> send(TrustTaskDocument document) async {
    final recipient = document.recipient;
    if (document.issuer != _persona.did || recipient == null) {
      throw ArgumentError.value(document.id, 'document', 'not to a peer');
    }
    final recipientDocument = await _resolve(recipient);
    final mediatorDid = mediatorDidOf(recipientDocument);
    if (mediatorDid == null) {
      throw MeetingPlaceVtcSDKException.signInNotOffered(
        didCommMessagingServiceType,
      );
    }
    final mediatorDocument = await _resolve(mediatorDid);

    final now = DateTime.now().toUtc();
    final message = PlainTextMessage(
      id: document.id,
      type: Uri.parse(document.type),
      from: _persona.did,
      to: [recipient],
      threadId: document.threadId,
      createdTime: now,
      expiresTime: now.add(messageLifetime),
      body: document.toJson(),
    );
    final personaDocument = await _persona.getDidDocument();
    final keyIds = personaDocument.matchKeysInKeyAgreement(
      otherDidDocuments: [recipientDocument],
    );
    if (keyIds.isEmpty) {
      throw MeetingPlaceVtcSDKException.invalidDocument(
        'no key agreement in common with the recipient',
      );
    }
    final encrypted = await EncryptedMessage.packWithAuthentication(
      message,
      keyPair: await _persona.getKeyPairByDidKeyId(keyIds.first),
      didKeyId: keyIds.first,
      recipientDidDocuments: [recipientDocument],
    );
    final forward = ForwardMessage(
      id: const Uuid().v4(),
      from: _persona.did,
      to: [mediatorDid],
      next: recipient,
      expiresTime: now.add(messageLifetime),
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

    MediatorOutbox? outbox;
    try {
      outbox = await _openOutbox(
        mediatorDid: mediatorDid,
        mediatorDocument: mediatorDocument,
        manager: _persona,
      );
      await outbox.send(forward);
    } catch (error) {
      throw MeetingPlaceVtcSDKException.transportFailed(
        'mediator refused the message',
        innerException: error,
      );
    } finally {
      try {
        await outbox?.close();
      } catch (_) {
        // The session ends on the mediator's side all the same.
      }
    }
  }

  Future<DidDocument> _resolve(String did) async {
    try {
      return await _didResolver.resolveDid(did);
    } catch (error) {
      throw MeetingPlaceVtcSDKException.didResolutionFailed(
        innerException: error,
      );
    }
  }

  static Future<MediatorOutbox> _openMediatorOutbox({
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
    return _MediatorClientOutbox(client);
  }
}

class _MediatorClientOutbox implements MediatorOutbox {
  _MediatorClientOutbox(this._client);

  final MediatorClient _client;

  @override
  Future<void> send(ForwardMessage message) => _client.sendMessage(message);

  @override
  Future<void> close() => _client.disconnect();
}
