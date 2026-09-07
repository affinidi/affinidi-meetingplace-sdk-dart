import 'dart:async';
import 'dart:convert';

import 'package:meeting_place_core/meeting_place_core.dart';
import 'package:ssi/ssi.dart';

import 'meeting_place_credentials_sdk_error_code.dart';
import 'meeting_place_credentials_sdk_exception.dart';
import 'rcard/builder/r_card_builder.dart';
import 'rcard/model/channel_r_card_event.dart';
import 'rcard/model/r_card.dart';
import 'rcard/model/r_card_constants.dart';
import 'rcard/model/r_card_rejection.dart';
import 'rcard/parser/r_card_parser.dart';
import 'rcard/r_card_channel_stream_manager.dart';
import 'rcard/r_card_vdip_stream_manager.dart';
import 'rcard/repository/r_card_repository.dart';
import 'rcard/requests/send_r_card_request.dart';
import 'shared/credentials_vdip_stream_manager.dart';
import 'vrc/model/vrc.dart';
import 'vrc/model/vrc_issuance.dart';
import 'vrc/model/vrc_processing_result.dart';
import 'vrc/model/vrc_request.dart';
import 'vrc/model/vrc_request_processing_result.dart';
import 'vrc/params/received_vrc_params.dart';
import 'vrc/params/received_vrc_request_params.dart';
import 'vrc/params/request_vrc_exchange_params.dart';
import 'vrc/params/send_vrc_request.dart';
import 'vrc/params/store_vrc_request.dart';
import 'vrc/parser/vrc_parser.dart';
import 'vrc/repository/vrc_repository.dart';
import 'vrc/vrc_exchange_client.dart';
import 'vrc/vrc_protocol_handler.dart';
import 'vrc/vrc_vdip_stream_manager.dart';

/// The Meeting Place Credentials SDK.
///
/// A thin facade that wires R-Card and VRC exchange flows on top of
/// `MeetingPlaceCoreSDK`. All stateful stream management is delegated to
/// [RCardChannelStreamManager] (OOB / inauguration path),
/// [CredentialsVdipStreamManager] (VDIP routing),
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
/// final credentialsSDK = MeetingPlaceCredentialsSDK(
///   coreSDK: coreSDK,
///   rCardRepository: RCardRepositoryDrift(database: rCardDb),
///   vrcRepository: VrcRepositoryDrift(database: vrcDb),
/// );
///
/// credentialsSDK.watchReceivedRCards().listen((cards) {
///   // driven directly from the local DB — always up to date
/// });
/// ```
class MeetingPlaceCredentialsSDK {
  /// Creates a `MeetingPlaceCredentialsSDK` backed by the given [coreSDK].
  ///
  /// - [rCardRepository]: Repository used to persist every incoming R-Card.
  ///   Construct one with `RCardRepositoryDrift` from
  ///   `meeting_place_drift_repository`.
  /// - [vrcRepository]: Repository used to persist every received VRC.
  ///   Construct one with `VrcRepositoryDrift` from
  ///   `meeting_place_drift_repository`.
  MeetingPlaceCredentialsSDK({
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
    _credentialsVdipStreamManager = CredentialsVdipStreamManager(
      incomingVdipMessages: coreSDK.vdip.incomingMessages,
      logger: _logger,
    );
    _rCardVdipStreamManager = RCardVdipStreamManager(
      incomingVdipMessages: _credentialsVdipStreamManager.rCardMessages,
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
    _rCardRejectionsController = StreamController<RCardRejection>.broadcast();
    _rCardRejectionsStream = _rCardRejectionsController.stream;
    _attachmentRejectionSubscription = _attachmentManager.rejections.listen(
      _rCardRejectionsController.add,
    );
    _rCardVdipRejectionSubscription = _rCardVdipStreamManager.rejections.listen(
      _rCardRejectionsController.add,
    );
    // Secondary path: processor registered on VdipClient so R-Cards are
    // persisted before the mediator message is deleted — guarantees
    // persistence even if this SDK was constructed after the message
    // arrived (lazy Riverpod initialisation). Upserts directly to the
    // repository rather than re-emitting on the stream to avoid the
    // duplicate-event that would otherwise result from the primary
    // _rCardVdipSubscription path also forwarding the same message.
    coreSDK.vdip.registerMessageProcessor((message) async {
      if (!_credentialsVdipStreamManager.isRCardIssuedCredentialMessage(
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
      incomingVdipMessages: _credentialsVdipStreamManager.vrcMessages,
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

  static const _className = 'MeetingPlaceCredentialsSDK';

  final MeetingPlaceCoreSDK _coreSDK;
  final RCardRepository _rCardRepository;
  final VrcRepository _vrcRepository;
  final MeetingPlaceCoreSDKLogger _logger;
  late final RCardParser _rCardParser;
  late final VrcParser _vrcParser;
  late final RCardChannelStreamManager _attachmentManager;
  late final CredentialsVdipStreamManager _credentialsVdipStreamManager;
  late final RCardVdipStreamManager _rCardVdipStreamManager;
  late final StreamController<RCard> _receivedRCardsController;
  late final Stream<RCard> _receivedRCardsStream;
  late final StreamSubscription<ChannelRCardEvent> _attachmentSubscription;
  late final StreamSubscription<RCard> _rCardVdipSubscription;
  late final StreamSubscription<void> _persistenceSubscription;
  late final StreamController<RCardRejection> _rCardRejectionsController;
  late final Stream<RCardRejection> _rCardRejectionsStream;
  late final StreamSubscription<RCardRejection>
  _attachmentRejectionSubscription;
  late final StreamSubscription<RCardRejection> _rCardVdipRejectionSubscription;

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
  ///
  /// Every [RCard] emitted here has passed full proof verification
  /// (signature, expiry, revocation) and issuer/counterparty binding — see
  /// the guarantee documented on [RCard]. Anything that failed those checks
  /// is surfaced on [rCardRejections] instead of on this stream.
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
  /// Carries the same verification guarantee as [receivedRCards] (see
  /// [RCard]). VDIP-path R-Cards are NOT emitted on this stream; use
  /// [receivedRCards] for those.
  Stream<ChannelRCardEvent> get receivedRCardsOnChannel =>
      _attachmentManager.stream;

  /// A broadcast stream that emits an [RCardRejection] for every R-Card
  /// (from either delivery path) that was received but rejected — malformed
  /// payload, failed signature/expiry/revocation verification, or an issuer
  /// that did not match the expected counterparty.
  ///
  /// Every such rejection is already logged internally; this stream lets
  /// callers additionally observe and react to them (e.g. surface a warning
  /// in their own logs or UI).
  Stream<RCardRejection> get rCardRejections => _rCardRejectionsStream;

  /// Returns a live stream of all persisted R-Cards, ordered by
  /// [RCard.receivedAt] descending.
  ///
  /// Backed by [RCardRepository.watchAll] — emits a new list
  /// whenever any record is added, updated, or removed from local storage.
  Stream<List<RCard>> watchReceivedRCards() =>
      _withSdkStreamExceptionHandling(_rCardRepository.watchAll);

  /// Returns a snapshot of all persisted R-Cards, ordered by
  /// [RCard.receivedAt] descending.
  Future<List<RCard>> listReceivedRCards() =>
      _withSdkExceptionHandling(_rCardRepository.listAll);

  /// Returns the persisted R-Card whose sender DID matches [subjectDid],
  /// or `null` if no such record exists.
  Future<RCard?> findReceivedRCardBySubjectDid(String subjectDid) =>
      _withSdkExceptionHandling(
        () => _rCardRepository.getBySubjectDid(subjectDid),
      );

  /// Updates the [RCard.notes] field for the R-Card identified by
  /// [subjectDid]. Pass `null` to clear the notes.
  ///
  /// Does nothing if no record with [subjectDid] exists.
  Future<void> updateReceivedRCardNotes(String subjectDid, String? notes) =>
      _withSdkExceptionHandling(
        () => _rCardRepository.updateNotes(subjectDid, notes),
      );

  /// Removes the persisted R-Card identified by [subjectDid].
  Future<void> deleteReceivedRCard(String subjectDid) =>
      _withSdkExceptionHandling(
        () => _rCardRepository.deleteBySubjectDid(subjectDid),
      );

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

  /// Returns and removes the last [RCard] from [senderDid] that arrived
  /// while no listener was attached.
  ///
  /// Carries the same verification guarantee as [receivedRCards] (see
  /// [RCard]).
  RCard? consumePendingRCard(String senderDid) =>
      _rCardVdipStreamManager.consumePendingRCard(senderDid);

  /// Returns a live stream of all persisted VRCs.
  Stream<List<Vrc>> watchVrcs() =>
      _withSdkStreamExceptionHandling(_vrcRepository.watchAll);

  /// Returns a snapshot of all persisted VRCs.
  Future<List<Vrc>> listVrcs() =>
      _withSdkExceptionHandling(_vrcRepository.listAll);

  /// Returns the persisted VRC identified by [id].
  Future<Vrc?> findVrcById(String id) =>
      _withSdkExceptionHandling(() => _vrcRepository.getById(id));

  /// Returns the persisted VRCs where the holder DID matches [holderDid].
  Future<List<Vrc>> listVrcsByHolderDid(String holderDid) =>
      _withSdkExceptionHandling(
        () => _vrcRepository.listByHolderDid(holderDid),
      );

  /// Returns the number of persisted VRCs where the holder DID matches
  /// [holderDid].
  Future<int> countVrcsByHolderDid(String holderDid) =>
      _withSdkExceptionHandling(
        () => _vrcRepository.countByHolderDid(holderDid),
      );

  /// Removes the persisted VRC identified by [id].
  Future<void> deleteVrc(String id) =>
      _withSdkExceptionHandling(() => _vrcRepository.deleteById(id));

  /// Releases resources held by this SDK instance: cancels all internal
  /// stream subscriptions and closes their controllers.
  Future<void> dispose() async {
    if (!_receivedRCardsController.isClosed) {
      await _persistenceSubscription.cancel();
      await _rCardVdipSubscription.cancel();
      await _attachmentSubscription.cancel();
      await _attachmentRejectionSubscription.cancel();
      await _rCardVdipRejectionSubscription.cancel();
      await _vrcPersistenceSubscription?.cancel();
      await _rCardVdipStreamManager.close();
      await _vrcVdipStreamManager.close();
      await _attachmentManager.close();
      await _credentialsVdipStreamManager.close();
      await _receivedRCardsController.close();
      await _rCardRejectionsController.close();
      await _coreSDK.disposeVdipStream();
      return;
    }

    await _vrcPersistenceSubscription?.cancel();
    await _vrcVdipStreamManager.close();
    await _credentialsVdipStreamManager.close();
  }

  /// Runs [operation], converting any error it throws that is not already a
  /// [MeetingPlaceCredentialsSDKException] into one with
  /// [MeetingPlaceCredentialsSDKErrorCode.generic], so every method on this
  /// SDK throws the same unified exception type.
  Future<T> _withSdkExceptionHandling<T>(Future<T> Function() operation) async {
    try {
      return await operation();
    } on MeetingPlaceCredentialsSDKException {
      rethrow;
    } catch (e, stackTrace) {
      Error.throwWithStackTrace(
        MeetingPlaceCredentialsSDKException(
          message: 'Failure on Credentials SDK exception',
          code: MeetingPlaceCredentialsSDKErrorCode.generic,
          innerException: e,
        ),
        stackTrace,
      );
    }
  }

  /// Stream counterpart of [_withSdkExceptionHandling]: returns
  /// [operation]'s stream, converting any error it throws while being built
  /// or emits once subscribed to that is not already a
  /// [MeetingPlaceCredentialsSDKException] into one with
  /// [MeetingPlaceCredentialsSDKErrorCode.generic].
  Stream<T> _withSdkStreamExceptionHandling<T>(Stream<T> Function() operation) {
    try {
      return operation().handleError((Object error, StackTrace stackTrace) {
        if (error is MeetingPlaceCredentialsSDKException) {
          Error.throwWithStackTrace(error, stackTrace);
        }
        Error.throwWithStackTrace(
          MeetingPlaceCredentialsSDKException(
            message: 'Failure on Credentials SDK exception',
            code: MeetingPlaceCredentialsSDKErrorCode.generic,
            innerException: error,
          ),
          stackTrace,
        );
      });
    } on MeetingPlaceCredentialsSDKException {
      rethrow;
    } catch (e, stackTrace) {
      Error.throwWithStackTrace(
        MeetingPlaceCredentialsSDKException(
          message: 'Failure on Credentials SDK exception',
          code: MeetingPlaceCredentialsSDKErrorCode.generic,
          innerException: e,
        ),
        stackTrace,
      );
    }
  }

  // ---------------------------------------------------------------------------
  // R-Card operations
  // ---------------------------------------------------------------------------

  /// Builds, signs, and delivers an R-Card to the other party in
  /// [SendRCardRequest.channel] via VDIP.
  ///
  /// Returns the sent [RCard] so callers can display or store the issued card.
  Future<RCard> sendRCard(
    SendRCardRequest request,
  ) => _withSdkExceptionHandling(() async {
    final channel = request.channel;
    final subjectDid = request.subjectDid;
    final issuerDid = channel.permanentChannelDid;
    if (issuerDid == null || issuerDid.isEmpty) {
      throw MeetingPlaceCredentialsSDKException.sendRCardMissingChannelDid();
    }
    final vc = await RCardBuilder.build(
      issuerDid: issuerDid,
      subjectDid: subjectDid,
      subject: request.card,
      issuerDidManager: request.issuerDidManager,
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
  });

  // ---------------------------------------------------------------------------
  // Parsing
  // ---------------------------------------------------------------------------

  /// Parses and verifies a raw R-Card VC blob.
  ///
  /// Returns `null` if the blob is not a valid, signature-verified R-Card.
  ///
  /// - [vcBlob] — the raw serialised VC JSON string.
  Future<RCard?> parseRCard({required String vcBlob}) =>
      _withSdkExceptionHandling(() async {
        final result = await _rCardParser.parse(vcBlob: vcBlob);
        return result is RCardParseSuccess ? result.rCard : null;
      });

  /// Parses and validates a VRC from a raw VC blob string.
  Future<ParsedVerifiableCredential?> parseVrc({required String vcBlob}) {
    return _withSdkExceptionHandling(() => _vrcParser.parse(vcBlob: vcBlob));
  }

  /// Parses and stores a VRC for the given [StoreVrcRequest.referenceId].
  ///
  /// Throws [MeetingPlaceCredentialsSDKException] with
  /// [MeetingPlaceCredentialsSDKErrorCode.vrcInvalidCredential] if
  /// [StoreVrcRequest.vcBlob] cannot be parsed as a valid VRC.
  Future<Vrc> storeVrc(StoreVrcRequest params) =>
      _withSdkExceptionHandling(() async {
        final parsed = await parseVrc(vcBlob: params.vcBlob);
        if (parsed == null) {
          throw MeetingPlaceCredentialsSDKException.vrcInvalidCredential();
        }

        final vrc = parsed.toVrc(
          referenceId: params.referenceId,
          verifiedAt: params.verifiedAt,
          receivedAt: params.receivedAt,
          credentialFormat: params.credentialFormat,
        );
        await _vrcRepository.upsert(vrc);
        return vrc;
      });

  // ---------------------------------------------------------------------------
  // Outbound VRC operations
  // ---------------------------------------------------------------------------

  /// Requests a VRC exchange over VDIP for the given
  /// [RequestVrcExchangeParams.channelDid].
  ///
  /// [RequestVrcExchangeParams.requesterDid] and
  /// [RequestVrcExchangeParams.requesterName] identify the caller — the
  /// party asking to be named as the counterpart when the other side issues
  /// a VRC in response, not the party issuing a credential right now.
  Future<void> requestVrcExchange(RequestVrcExchangeParams params) =>
      _withSdkExceptionHandling(
        () => _vrcClient.requestExchange(
          channelDid: params.channelDid,
          requesterDid: params.requesterDid,
          requesterName: params.requesterName,
        ),
      );

  /// Builds and sends a VRC over VDIP for the given
  /// [SendVrcRequest.channelDid].
  Future<String> sendVrc(SendVrcRequest params) => _withSdkExceptionHandling(
    () => _vrcClient.sendVrc(
      channelDid: params.channelDid,
      issuerDid: params.issuerDid,
      issuerName: params.issuerName,
      peerDid: params.peerDid,
      peerName: params.peerName,
    ),
  );

  // ---------------------------------------------------------------------------
  // VRC protocol decisions
  // ---------------------------------------------------------------------------

  /// Handles the credentials-protocol outcome of receiving a VRC request.
  Future<VrcRequestProcessingResult> handleReceivedVrcRequest(
    ReceivedVrcRequestParams params,
  ) => _withSdkExceptionHandling(
    () => _vrcProtocolHandler.handleReceivedVrcRequest(
      permanentChannelDid: params.permanentChannelDid,
      request: params.request,
      hasVrcExchangeInitiated: params.hasVrcExchangeInitiated,
      isConnectionInitiator: params.isConnectionInitiator,
      issuerDid: params.issuerDid,
      issuerName: params.issuerName,
    ),
  );

  /// Handles the credentials-protocol outcome of receiving a VRC.
  ///
  /// Returns [VrcProcessingResultIgnored] when the exchange is already
  /// completed, so callers do not need a pre-guard.
  Future<VrcProcessingResult> handleReceivedVrc(ReceivedVrcParams params) =>
      _withSdkExceptionHandling(
        () => _vrcProtocolHandler.handleReceivedVrc(
          permanentChannelDid: params.permanentChannelDid,
          vcBlob: params.vcBlob,
          exchangeState: params.exchangeState,
          issuerDid: params.issuerDid,
          issuerName: params.issuerName,
        ),
      );

  Future<void> _persistReceivedVrc(VrcIssuance vrcIssuance) async {
    final channel = await _coreSDK.findChannelByOtherPartyPermanentDid(
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
