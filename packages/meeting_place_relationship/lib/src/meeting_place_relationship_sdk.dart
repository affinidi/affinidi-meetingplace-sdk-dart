import 'dart:async';
import 'dart:convert';

import 'package:meeting_place_core/meeting_place_core.dart';
import 'package:ssi/ssi.dart';

import 'rcard/builder/r_card_builder.dart';
import 'rcard/model/r_card.dart';
import 'rcard/model/r_card_subject.dart';
import 'rcard/parser/r_card_parser.dart';
import 'rcard/r_card_channel_stream_manager.dart';
import 'rcard/r_card_vdip_stream_manager.dart';
import 'rcard/repository/r_card_repository.dart';
import 'vrc/parser/vrc_parser.dart';

/// The Meeting Place Relationship SDK.
///
/// A thin facade that wires R-Card and VRC exchange flows on top of
/// `MeetingPlaceCoreSDK`. All stateful stream management is delegated to
/// [RCardChannelStreamManager] (OOB / inauguration path) and
/// [RCardVdipStreamManager] (chat-time VDIP path).
///
/// Every valid R-Card that arrives via either path is automatically
/// persisted through the provided [RCardRepository].
///
/// Example:
/// ```dart
/// final coreSDK = await MeetingPlaceCoreSDK.create(...);
/// final db = RCardDatabase(...);
/// final repo = RCardRepositoryDrift(database: db);
/// final relationshipSDK = MeetingPlaceRelationshipSDK(
///   coreSDK: coreSDK,
///   rCardRepository: repo,
/// );
///
/// relationshipSDK.watchReceivedRCards().listen((cards) {
///   // driven directly from the local DB — always up to date
/// });
/// ```
class MeetingPlaceRelationshipSDK {
  /// Creates a `MeetingPlaceRelationshipSDK` backed by the given [coreSDK].
  ///
  /// - [rCardRepository]: Required repository used to persist every
  ///   incoming R-Card. Construct one with `RCardRepositoryDrift`
  ///   from `meeting_place_drift_repository`.
  MeetingPlaceRelationshipSDK({
    required MeetingPlaceCoreSDK coreSDK,
    required RCardRepository rCardRepository,
    MeetingPlaceCoreSDKLogger? logger,
  }) : _coreSDK = coreSDK,
       _rCardRepository = rCardRepository {
    final log =
        logger ?? DefaultMeetingPlaceCoreSDKLogger(className: _className);
    _logger = log;
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
    // persisted before the mediator message is deleted — guarantees
    // persistence even if this SDK was constructed after the message
    // arrived (lazy Riverpod initialisation). Upserts directly to the
    // repository rather than re-emitting on the stream to avoid the
    // duplicate-event that would otherwise result from the primary
    // _vdipSubscription path also forwarding the same message.
    coreSDK.vdip.registerMessageProcessor((message) async {
      final rCard = await _vdipManager.processMessage(message);
      if (rCard != null) {
        await _rCardRepository.upsert(rCard);
      }
    });
    _persistenceSubscription = _receivedRCardsController.stream
        .asyncMap(_rCardRepository.upsert)
        .listen(
          (_) {},
          onError: (Object error, StackTrace stackTrace) {
            _logger.error(
              'Failed to persist R-Card',
              error: error,
              stackTrace: stackTrace,
              name: _className,
            );
          },
        );
  }

  static const _className = 'MeetingPlaceRelationshipSDK';

  final MeetingPlaceCoreSDK _coreSDK;
  final RCardRepository _rCardRepository;
  late final MeetingPlaceCoreSDKLogger _logger;
  late final RCardParser _rCardParser;
  late final VrcParser _vrcParser;
  late final RCardChannelStreamManager _attachmentManager;
  late final RCardVdipStreamManager _vdipManager;
  late final StreamController<RCard> _receivedRCardsController;
  late final Stream<RCard> _receivedRCardsStream;
  late final StreamSubscription<RCard> _attachmentSubscription;
  late final StreamSubscription<RCard> _vdipSubscription;
  late final StreamSubscription<void> _persistenceSubscription;

  /// A broadcast stream that emits a [RCard] whenever a valid,
  /// signature-verified R-Card is received over any channel — either via
  /// the DIDComm attachment path (OOB / inauguration) or the VDIP
  /// issued-credential path (chat-time update).
  Stream<RCard> get receivedRCards => _receivedRCardsStream;

  /// Returns a live stream of all persisted R-Cards, ordered by
  /// [RCard.receivedAt] descending.
  ///
  /// Backed by [RCardRepository.watchAll] — emits a new list
  /// whenever any record is added, updated, or removed from local storage.
  Stream<List<RCard>> watchReceivedRCards() => _rCardRepository.watchAll();

  /// Returns a snapshot of all persisted R-Cards, ordered by
  /// [RCard.receivedAt] descending.
  Future<List<RCard>> listReceivedRCards() => _rCardRepository.listAll();

  /// Returns the persisted R-Card whose sender DID matches [subjectDid],
  /// or `null` if no such record exists.
  Future<RCard?> getReceivedRCardBySubjectDid(String subjectDid) =>
      _rCardRepository.getBySubjectDid(subjectDid);

  /// Updates the [RCard.notes] field for the R-Card identified by
  /// [subjectDid]. Pass `null` to clear the notes.
  ///
  /// Does nothing if no record with [subjectDid] exists.
  Future<void> updateReceivedRCardNotes(String subjectDid, String? notes) =>
      _rCardRepository.updateNotes(subjectDid, notes);

  /// Removes the persisted R-Card identified by [subjectDid].
  ///
  /// Does nothing if no record with [subjectDid] exists.
  Future<void> deleteReceivedRCard(String subjectDid) =>
      _rCardRepository.deleteBySubjectDid(subjectDid);

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
    await _coreSDK.closeVdipStream();
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
  Future<RCard?> parseRCard({
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
