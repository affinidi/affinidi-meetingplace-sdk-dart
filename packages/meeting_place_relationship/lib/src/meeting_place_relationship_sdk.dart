import 'dart:async';
import 'dart:convert';

import 'package:meeting_place_core/meeting_place_core.dart';
import 'package:ssi/ssi.dart';

import 'rcard/builder/r_card_builder.dart';
import 'rcard/model/r_card_subject.dart';
import 'rcard/model/received_r_card.dart';
import 'rcard/parser/r_card_parser.dart';
import 'rcard/r_card_channel_stream_manager.dart';
import 'rcard/r_card_vdip_stream_manager.dart';
import 'rcard/repository/received_r_card_repository.dart';
import 'vrc/parser/vrc_parser.dart';

/// The Meeting Place Relationship SDK.
///
/// A thin facade that wires R-Card and VRC exchange flows on top of
/// `MeetingPlaceCoreSDK`. All stateful stream management is delegated to
/// [RCardChannelStreamManager] (OOB / inauguration path) and
/// [RCardVdipStreamManager] (chat-time VDIP path).
///
/// Every valid R-Card that arrives via either path is automatically
/// persisted through the provided [ReceivedRCardRepository].
///
/// Example:
/// ```dart
/// final coreSDK = await MeetingPlaceCoreSDK.create(...);
/// final db = ReceivedRCardDatabase(...);
/// final repo = ReceivedRCardRepositoryDrift(database: db);
/// final relationshipSDK = MeetingPlaceRelationshipSDK(
///   coreSDK: coreSDK,
///   receivedRCardRepository: repo,
/// );
///
/// relationshipSDK.watchReceivedRCards().listen((cards) {
///   // driven directly from the local DB — always up to date
/// });
/// ```
class MeetingPlaceRelationshipSDK {
  /// Creates a `MeetingPlaceRelationshipSDK` backed by the given [coreSDK].
  ///
  /// - [receivedRCardRepository]: Required repository used to persist every
  ///   incoming R-Card. Construct one with `ReceivedRCardRepositoryDrift`
  ///   from `meeting_place_drift_repository`.
  MeetingPlaceRelationshipSDK({
    required MeetingPlaceCoreSDK coreSDK,
    required ReceivedRCardRepository receivedRCardRepository,
    MeetingPlaceCoreSDKLogger? logger,
  }) : _coreSDK = coreSDK,
       _receivedRCardRepository = receivedRCardRepository {
    final log =
        logger ?? DefaultMeetingPlaceCoreSDKLogger(className: _className);
    _rCardParser = RCardParser(logger: log);
    _vrcParser = VrcParser(logger: log);
    _attachmentManager = RCardChannelStreamManager(
      channelAttachments: coreSDK.channelAttachments,
      parser: _rCardParser,
      logger: log,
    );
    _vdipManager = RCardVdipStreamManager(
      incomingVdipMessages: coreSDK.vdip.incomingMessages,
      parser: _rCardParser,
      logger: log,
    );
    _receivedRCardsController = StreamController.broadcast();
    _receivedRCardsStream = _receivedRCardsController.stream;
    _attachmentSubscription = _attachmentManager.stream.listen(
      _receivedRCardsController.add,
      onError: _receivedRCardsController.addError,
    );
    // Primary path: forward parsed R-Cards from the VDIP stream manager.
    // Active whenever this SDK instance is alive — covers the common case
    // where both parties are online / in the chat screen.
    _vdipSubscription = _vdipManager.stream.listen(
      _receivedRCardsController.add,
      onError: _receivedRCardsController.addError,
    );
    // Secondary path: processor registered on VdipClient so R-Cards are
    // also persisted before the mediator message is deleted — guarantees
    // persistence even if this SDK was constructed after the message
    // arrived (lazy Riverpod initialisation). upsert is idempotent, so
    // double-emission from both paths is harmless.
    coreSDK.vdip.registerMessageProcessor((message) async {
      final rCard = await _vdipManager.processMessage(message);
      if (rCard != null && !_receivedRCardsController.isClosed) {
        _receivedRCardsController.add(rCard);
      }
    });
    _persistenceSubscription = _receivedRCardsController.stream.listen(
      _receivedRCardRepository.upsert,
    );
  }

  static const _className = 'MeetingPlaceRelationshipSDK';

  final MeetingPlaceCoreSDK _coreSDK;
  final ReceivedRCardRepository _receivedRCardRepository;
  late final RCardParser _rCardParser;
  late final VrcParser _vrcParser;
  late final RCardChannelStreamManager _attachmentManager;
  late final RCardVdipStreamManager _vdipManager;
  late final StreamController<ReceivedRCard> _receivedRCardsController;
  late final Stream<ReceivedRCard> _receivedRCardsStream;
  late final StreamSubscription<ReceivedRCard> _attachmentSubscription;
  late final StreamSubscription<ReceivedRCard> _vdipSubscription;
  late final StreamSubscription<ReceivedRCard> _persistenceSubscription;

  /// A broadcast stream that emits a [ReceivedRCard] whenever a valid,
  /// signature-verified R-Card is received over any channel — either via
  /// the DIDComm attachment path (OOB / inauguration) or the VDIP
  /// issued-credential path (chat-time update).
  Stream<ReceivedRCard> get receivedRCards => _receivedRCardsStream;

  /// Returns a live stream of all persisted R-Cards, ordered by
  /// [ReceivedRCard.receivedAt] descending.
  ///
  /// Backed by [ReceivedRCardRepository.watchAll] — emits a new list
  /// whenever any record is added, updated, or removed from local storage.
  Stream<List<ReceivedRCard>> watchReceivedRCards() =>
      _receivedRCardRepository.watchAll();

  /// Returns a snapshot of all persisted R-Cards, ordered by
  /// [ReceivedRCard.receivedAt] descending.
  Future<List<ReceivedRCard>> listReceivedRCards() =>
      _receivedRCardRepository.listAll();

  /// Returns the persisted R-Card whose sender DID matches [subjectDid],
  /// or `null` if no such record exists.
  Future<ReceivedRCard?> getReceivedRCardBySubjectDid(String subjectDid) =>
      _receivedRCardRepository.getBySubjectDid(subjectDid);

  /// Updates the [ReceivedRCard.notes] field for the R-Card identified by
  /// [subjectDid]. Pass `null` to clear the notes.
  ///
  /// Does nothing if no record with [subjectDid] exists.
  Future<void> updateReceivedRCardNotes(String subjectDid, String? notes) =>
      _receivedRCardRepository.updateNotes(subjectDid, notes);

  /// Removes the persisted R-Card identified by [subjectDid].
  ///
  /// Does nothing if no record with [subjectDid] exists.
  Future<void> deleteReceivedRCard(String subjectDid) =>
      _receivedRCardRepository.deleteBySubjectDid(subjectDid);

  /// Cancels all internal subscriptions and closes [receivedRCards].
  ///
  /// Safe to call more than once — subsequent calls are no-ops.
  Future<void> closeRelationshipStreams() async {
    if (_receivedRCardsController.isClosed) return;
    await _persistenceSubscription.cancel();
    await _vdipSubscription.cancel();
    await _attachmentSubscription.cancel();
    await _vdipManager.close();
    await _attachmentManager.close();
    await _receivedRCardsController.close();
  }

  /// Builds, signs, and delivers an R-Card to the other party in [channel]
  /// via VDIP — the ADR 0002 compliant transport.
  ///
  /// Returns the serialised VC JSON string (vcBlob) so callers can render
  /// the sent R-Card as a chat attachment via
  /// `ChatSDK.createChatMessageFromIssuedCredential`.
  ///
  /// - [channel] — the established channel to the contact.
  /// - [card] — contact fields to embed in the R-Card VC.
  /// - [issuerDidManager] — [DidManager] used to sign the credential.
  Future<String> sendRCard({
    required Channel channel,
    required String subjectDid,
    required RCardSubject card,
    required DidManager issuerDidManager,
  }) async {
    final issuerDid = channel.permanentChannelDid;
    if (issuerDid == null || issuerDid.isEmpty) {
      throw StateError(
        'Channel is missing permanentChannelDid — cannot send R-Card.',
      );
    }
    final vc = await RCardBuilder.build(
      issuerDid: issuerDid,
      subjectDid: subjectDid,
      subject: card,
      issuerDidManager: issuerDidManager,
    );
    await _coreSDK.vdip.issueCredential(channel: channel, credential: vc);
    return jsonEncode(vc.toJson());
  }

  /// Parses and verifies a raw R-Card VC blob.
  ///
  /// Returns `null` if the blob is not a valid, signature-verified R-Card.
  ///
  /// - [vcBlob] — the raw serialised VC JSON string.
  /// - [contactChannelDid] — the channel DID through which this card was
  ///   received, stored on the result for later lookup.
  Future<ReceivedRCard?> parseRCard({
    required String vcBlob,
    String? contactChannelDid,
  }) {
    return _rCardParser.parse(
      vcBlob: vcBlob,
      contactChannelDid: (contactChannelDid?.isEmpty ?? true)
          ? null
          : contactChannelDid,
    );
  }

  /// Parses and validates a VRC from a raw VC blob string.
  ///
  /// Returns `null` if the blob is not a valid, signature-verified VRC.
  ///
  /// - [vcBlob] — the raw serialised VC JSON string.
  Future<ParsedVerifiableCredential?> parseVrc({required String vcBlob}) {
    return _vrcParser.parse(vcBlob: vcBlob);
  }
}
