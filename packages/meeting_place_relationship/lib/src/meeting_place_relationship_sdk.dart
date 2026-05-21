import 'dart:async';
import 'dart:convert';

import 'package:meeting_place_core/meeting_place_core.dart';
import 'package:ssi/ssi.dart';

import 'meeting_place_relationship_sdk_error_code.dart';
import 'meeting_place_relationship_sdk_exception.dart';
import 'rcard/builder/r_card_builder.dart';
import 'rcard/model/channel_r_card_event.dart';
import 'rcard/model/r_card.dart';
import 'rcard/model/r_card_constants.dart';
import 'rcard/model/r_card_subject.dart';
import 'rcard/parser/r_card_parser.dart';
import 'rcard/r_card_channel_stream_manager.dart';
import 'rcard/r_card_vdip_stream_manager.dart';
import 'rcard/repository/r_card_repository.dart';
import 'shared/relationship_vdip_stream_manager.dart';
import 'vrc/model/vrc.dart';
import 'vrc/model/vrc_exchange_state.dart';
import 'vrc/model/vrc_issuance.dart';
import 'vrc/model/vrc_processing_result.dart';
import 'vrc/model/vrc_request.dart';
import 'vrc/model/vrc_request_processing_result.dart';
import 'vrc/parser/vrc_parser.dart';
import 'vrc/repository/vrc_repository.dart';
import 'vrc/vrc_exchange_client.dart';
import 'vrc/vrc_protocol_handler.dart';
import 'vrc/vrc_vdip_stream_manager.dart';

/// The Meeting Place Relationship SDK.
///
/// A thin facade that wires R-Card and VRC exchange flows on top of
/// `MeetingPlaceCoreSDK`. All stateful stream management is delegated to
/// [RCardChannelStreamManager] (OOB / inauguration path),
/// [RelationshipVdipStreamManager] (VDIP routing),
/// [RCardVdipStreamManager] (chat-time R-Card path), and
/// [VrcVdipStreamManager] (chat-time VRC path).
///
/// Every valid R-Card that arrives via either path is automatically
/// persisted through the provided [RCardRepository].
///
/// Example:
/// ```dart
/// final coreSDK = await MeetingPlaceCoreSDK.create(...);
/// final rCardDb = RCardDatabase(...);
/// final vrcDb = VrcDatabase(...);
/// final relationshipSDK = MeetingPlaceRelationshipSDK(
///   coreSDK: coreSDK,
///   rCardRepository: RCardRepositoryDrift(database: rCardDb),
///   vrcRepository: VrcRepositoryDrift(database: vrcDb),
/// );
///
/// relationshipSDK.watchReceivedRCards().listen((cards) {
///   // driven directly from the local DB — always up to date
/// });
/// ```
class MeetingPlaceRelationshipSDK {
  /// Creates a `MeetingPlaceRelationshipSDK` backed by the given [coreSDK].
  ///
  /// - [rCardRepository]: Repository used to persist every incoming R-Card.
  ///   Construct one with `RCardRepositoryDrift` from
  ///   `meeting_place_drift_repository`.
  /// - [vrcRepository]: Repository used to persist every received VRC.
  ///   Construct one with `VrcRepositoryDrift` from
  ///   `meeting_place_drift_repository`.
  MeetingPlaceRelationshipSDK({
    required MeetingPlaceCoreSDK coreSDK,
    required RCardRepository rCardRepository,
    required VrcRepository vrcRepository,
    MeetingPlaceCoreSDKLogger? logger,
  }) : _logger =
           logger ?? DefaultMeetingPlaceCoreSDKLogger(className: _className),
       _coreSDK = coreSDK,
       _rCardRepository = rCardRepository,
       _vrcRepository = vrcRepository {
    _rCardParser = RCardParser(logger: _logger);
    _vrcParser = VrcParser(logger: _logger);

    _attachmentManager = RCardChannelStreamManager(
      channelAttachments: coreSDK.channelAttachments,
      parser: _rCardParser,
      logger: _logger,
    );
    _relationshipVdipStreamManager = RelationshipVdipStreamManager(
      incomingVdipMessages: coreSDK.vdip.incomingMessages,
      logger: _logger,
    );
    _rCardVdipStreamManager = RCardVdipStreamManager(
      incomingVdipMessages: _relationshipVdipStreamManager.rCardMessages,
      parser: _rCardParser,
      logger: _logger,
    );
    _receivedRCardsController = StreamController<RCard>.broadcast();
    _receivedRCardsStream = _receivedRCardsController.stream;
    _attachmentSubscription = _attachmentManager.stream.listen(
      (event) => _receivedRCardsController.add(event.rCard),
      onError: _receivedRCardsController.addError,
    );
    _rCardVdipSubscription = _rCardVdipStreamManager.stream.listen(
      _receivedRCardsController.add,
      onError: _receivedRCardsController.addError,
    );
    // Secondary path: processor registered on VdipClient so R-Cards are
    // persisted before the mediator message is deleted — guarantees
    // persistence even if this SDK was constructed after the message
    // arrived (lazy Riverpod initialisation). Upserts directly to the
    // repository rather than re-emitting on the stream to avoid the
    // duplicate-event that would otherwise result from the primary
    // _rCardVdipSubscription path also forwarding the same message.
    coreSDK.vdip.registerMessageProcessor((message) async {
      if (!_relationshipVdipStreamManager.isRCardIssuedCredentialMessage(
        message,
      )) {
        _logger.info(
          'Skipping R-Card message processor for non-R-Card VDIP message',
        );
        return;
      }

      final rCard = await _rCardVdipStreamManager.processMessage(message);
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

    _vrcVdipStreamManager = VrcVdipStreamManager(
      incomingVdipMessages: _relationshipVdipStreamManager.vrcMessages,
      parser: _vrcParser,
      logger: _logger,
    );
    _vrcClient = VrcExchangeClient(coreSDK: coreSDK, logger: _logger);
    _vrcProtocolHandler = VrcProtocolHandler(
      client: _vrcClient,
      parser: _vrcParser,
      logger: _logger,
    );

    _vrcPersistenceSubscription = _vrcVdipStreamManager.receivedVrcs.listen(
      (receivedVrc) => unawaited(_persistReceivedVrc(receivedVrc)),
    );
  }

  static const _className = 'MeetingPlaceRelationshipSDK';

  final MeetingPlaceCoreSDK _coreSDK;
  final RCardRepository _rCardRepository;
  final VrcRepository _vrcRepository;
  final MeetingPlaceCoreSDKLogger _logger;
  late final RCardParser _rCardParser;
  late final VrcParser _vrcParser;
  late final RCardChannelStreamManager _attachmentManager;
  late final RelationshipVdipStreamManager _relationshipVdipStreamManager;
  late final RCardVdipStreamManager _rCardVdipStreamManager;
  late final StreamController<RCard> _receivedRCardsController;
  late final Stream<RCard> _receivedRCardsStream;
  late final StreamSubscription<ChannelRCardEvent> _attachmentSubscription;
  late final StreamSubscription<RCard> _rCardVdipSubscription;
  late final StreamSubscription<void> _persistenceSubscription;

  late final VrcVdipStreamManager _vrcVdipStreamManager;
  late final VrcExchangeClient _vrcClient;
  late final VrcProtocolHandler _vrcProtocolHandler;
  StreamSubscription<VrcIssuance>? _vrcPersistenceSubscription;

  // ---------------------------------------------------------------------------
  // Streams
  // ---------------------------------------------------------------------------

  /// A broadcast stream that emits a [RCard] whenever a valid,
  /// signature-verified R-Card is received over any channel — either via
  /// the DIDComm attachment path (OOB / inauguration) or the VDIP
  /// issued-credential path (chat-time update).
  Stream<RCard> get receivedRCards => _receivedRCardsStream;

  /// A broadcast stream that emits a [ChannelRCardEvent] for every R-Card
  /// received via the connection establishment (channel inauguration /
  /// OOB acceptance) path.
  ///
  /// Callers can use [ChannelRCardEvent.channel] to access
  /// [Channel.permanentChannelDid] and
  /// [Channel.otherPartyPermanentChannelDid] to correlate the R-Card to the
  /// originating conversation (e.g. to create an auto-exchange chat message).
  ///
  /// VDIP-path R-Cards are NOT emitted on this stream; use [receivedRCards]
  /// for those.
  Stream<ChannelRCardEvent> get receivedRCardsOnChannel =>
      _attachmentManager.stream;

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
  Future<void> deleteReceivedRCard(String subjectDid) =>
      _rCardRepository.deleteBySubjectDid(subjectDid);

  /// A broadcast stream that emits a [VrcRequest] for each incoming
  /// VDIP request-issuance message.
  Stream<VrcRequest> get receivedVrcRequests => _vrcVdipStreamManager.requests;

  /// A broadcast stream that emits a [VrcIssuance] for each incoming,
  /// signature-verified issued VRC received over VDIP.
  Stream<VrcIssuance> get receivedVrcs => _vrcVdipStreamManager.receivedVrcs;

  /// Returns and removes the last [VrcRequest] from [senderDid] that
  /// arrived while no listener was attached.
  VrcRequest? consumePendingVrcRequest(String senderDid) =>
      _vrcVdipStreamManager.consumePendingRequest(senderDid);

  /// Returns and removes the last [VrcIssuance] from [senderDid] that arrived
  /// while no listener was attached.
  VrcIssuance? consumePendingVrc(String senderDid) =>
      _vrcVdipStreamManager.consumePendingVrc(senderDid);

  /// Returns a live stream of all persisted VRCs.
  Stream<List<Vrc>> watchVrcs() => _vrcRepository.watchAll();

  /// Returns a snapshot of all persisted VRCs.
  Future<List<Vrc>> listVrcs() => _vrcRepository.listAll();

  /// Returns the persisted VRC identified by [id].
  Future<Vrc?> getVrcById(String id) => _vrcRepository.getById(id);

  /// Returns the persisted VRCs where the holder DID matches [holderDid].
  Future<List<Vrc>> listVrcsByHolderDid(String holderDid) =>
      _vrcRepository.listByHolderDid(holderDid);

  /// Returns the number of persisted VRCs where the holder DID matches
  /// [holderDid].
  Future<int> countVrcsByHolderDid(String holderDid) =>
      _vrcRepository.countByHolderDid(holderDid);

  /// Removes the persisted VRC identified by [id].
  Future<void> deleteVrc(String id) => _vrcRepository.deleteById(id);

  /// Cancels all internal stream subscriptions.
  Future<void> closeRelationshipStreams() async {
    if (!_receivedRCardsController.isClosed) {
      await _persistenceSubscription.cancel();
      await _rCardVdipSubscription.cancel();
      await _attachmentSubscription.cancel();
      await _vrcPersistenceSubscription?.cancel();
      await _rCardVdipStreamManager.close();
      await _vrcVdipStreamManager.close();
      await _attachmentManager.close();
      await _relationshipVdipStreamManager.close();
      await _receivedRCardsController.close();
      await _coreSDK.closeVdipStream();
      return;
    }

    await _vrcPersistenceSubscription?.cancel();
    await _vrcVdipStreamManager.close();
    await _relationshipVdipStreamManager.close();
  }

  // ---------------------------------------------------------------------------
  // R-Card operations
  // ---------------------------------------------------------------------------

  /// Builds, signs, and delivers an R-Card to the other party in [channel]
  /// via VDIP.
  ///
  /// Returns the sent [RCard] so callers can display or store the issued card.
  ///
  /// - [channel] — the established channel to the contact.
  /// - [card] — contact fields to embed in the R-Card VC.
  /// - [issuerDidManager] — [DidManager] used to sign the credential.
  Future<RCard> sendRCard({
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
    final vcBlob = jsonEncode(vc.toJson());
    return RCard(
      subjectDid: subjectDid,
      vcBlob: vcBlob,
      issuerDid: issuerDid,
      version: RCardConstants.receivedRCardVersion,
      issuanceDate: vc.validFrom?.toUtc() ?? DateTime.now().toUtc(),
      receivedAt: DateTime.now().toUtc(),
    );
  }

  // ---------------------------------------------------------------------------
  // Parsing
  // ---------------------------------------------------------------------------

  /// Parses and verifies a raw R-Card VC blob.
  ///
  /// Returns `null` if the blob is not a valid, signature-verified R-Card.
  ///
  /// - [vcBlob] — the raw serialised VC JSON string.
  Future<RCard?> parseRCard({required String vcBlob}) {
    return _rCardParser.parse(vcBlob: vcBlob);
  }

  /// Parses and validates a VRC from a raw VC blob string.
  Future<ParsedVerifiableCredential?> parseVrc({required String vcBlob}) {
    return _vrcParser.parse(vcBlob: vcBlob);
  }

  /// Parses and stores a VRC for the given [referenceId].
  ///
  /// Throws [MeetingPlaceRelationshipSDKException] with
  /// [MeetingPlaceRelationshipSDKErrorCode.vrcInvalidCredential] if [vcBlob]
  /// cannot be parsed as a valid VRC.
  Future<Vrc> storeVrc({
    required String vcBlob,
    required String referenceId,
    DateTime? verifiedAt,
    DateTime? receivedAt,
    String? credentialFormat,
  }) async {
    final parsed = await parseVrc(vcBlob: vcBlob);
    if (parsed == null) {
      throw MeetingPlaceRelationshipSDKException.vrcInvalidCredential();
    }

    final vrc = parsed.toVrc(
      referenceId: referenceId,
      verifiedAt: verifiedAt,
      receivedAt: receivedAt,
      credentialFormat: credentialFormat,
    );
    await _vrcRepository.upsert(vrc);
    return vrc;
  }

  // ---------------------------------------------------------------------------
  // Outbound VRC operations
  // ---------------------------------------------------------------------------

  /// Requests a VRC exchange over VDIP for the given [channelDid].
  Future<void> requestVrcExchange({
    required String channelDid,
    required String identityDid,
    required String identityName,
  }) => _vrcClient.requestExchange(
    channelDid: channelDid,
    identityDid: identityDid,
    identityName: identityName,
  );

  /// Builds and sends a VRC over VDIP for the given [channelDid].
  Future<String> sendVrc({
    required String channelDid,
    required String issuerDid,
    required String issuerName,
    required String peerDid,
    required String peerName,
  }) => _vrcClient.sendVrc(
    channelDid: channelDid,
    issuerDid: issuerDid,
    issuerName: issuerName,
    peerDid: peerDid,
    peerName: peerName,
  );

  // ---------------------------------------------------------------------------
  // VRC protocol decisions
  // ---------------------------------------------------------------------------

  /// Handles the relationship-protocol outcome of receiving a VRC request.
  Future<VrcRequestProcessingResult> handleReceivedVrcRequest({
    required String permanentChannelDid,
    required VrcRequest request,
    required bool hasVrcExchangeInitiated,
    required bool isConnectionInitiator,
    String? issuerDid,
    String? issuerName,
  }) => _vrcProtocolHandler.handleReceivedVrcRequest(
    permanentChannelDid: permanentChannelDid,
    request: request,
    hasVrcExchangeInitiated: hasVrcExchangeInitiated,
    isConnectionInitiator: isConnectionInitiator,
    issuerDid: issuerDid,
    issuerName: issuerName,
  );

  /// Handles the relationship-protocol outcome of receiving a VRC.
  ///
  /// Returns [VrcProcessingResultIgnored] when the exchange is already
  /// completed, so callers do not need a pre-guard.
  Future<VrcProcessingResult> handleReceivedVrc({
    required String permanentChannelDid,
    required String vcBlob,
    required VrcExchangeState exchangeState,
    String? issuerDid,
    String? issuerName,
  }) => _vrcProtocolHandler.handleReceivedVrc(
    permanentChannelDid: permanentChannelDid,
    vcBlob: vcBlob,
    exchangeState: exchangeState,
    issuerDid: issuerDid,
    issuerName: issuerName,
  );

  Future<void> _persistReceivedVrc(VrcIssuance vrcIssuance) async {
    final channel = await _coreSDK.getChannelByOtherPartyPermanentDid(
      vrcIssuance.senderDid,
    );
    if (channel == null) {
      _logger.warning(
        'Skipping VRC persistence: no channel found for sender '
        '${vrcIssuance.senderDid}',
      );
      return;
    }

    final vrc = vrcIssuance.parsedCredential.toVrc(
      referenceId: channel.id,
      receivedAt: DateTime.now().toUtc(),
      credentialFormat: vrcIssuance.credentialFormat,
    );
    await _vrcRepository.upsert(vrc);
  }
}
