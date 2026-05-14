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
import 'vrc/parser/vrc_parser.dart';

/// The Meeting Place Relationship SDK.
///
/// A thin facade that wires R-Card and VRC exchange flows on top of
/// `MeetingPlaceCoreSDK`. All stateful stream management is delegated to
/// [RCardChannelStreamManager] (OOB / inauguration path) and
/// [RCardVdipStreamManager] (chat-time VDIP path).
///
/// Example:
/// ```dart
/// final coreSDK = await MeetingPlaceCoreSDK.create(...);
/// final relationshipSDK = MeetingPlaceRelationshipSDK(coreSDK: coreSDK);
///
/// relationshipSDK.receivedRCards.listen((rCard) {
///   repository.upsert(rCard);
/// });
/// ```
class MeetingPlaceRelationshipSDK {
  /// Creates a `MeetingPlaceRelationshipSDK` backed by the given [coreSDK].
  MeetingPlaceRelationshipSDK({
    required MeetingPlaceCoreSDK coreSDK,
    MeetingPlaceCoreSDKLogger? logger,
  }) : _coreSDK = coreSDK {
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
    _vdipSubscription = _vdipManager.stream.listen(
      _receivedRCardsController.add,
      onError: _receivedRCardsController.addError,
    );
  }

  static const _className = 'MeetingPlaceRelationshipSDK';

  final MeetingPlaceCoreSDK _coreSDK;
  late final RCardParser _rCardParser;
  late final VrcParser _vrcParser;
  late final RCardChannelStreamManager _attachmentManager;
  late final RCardVdipStreamManager _vdipManager;
  late final StreamController<ReceivedRCard> _receivedRCardsController;
  late final Stream<ReceivedRCard> _receivedRCardsStream;
  late final StreamSubscription<ReceivedRCard> _attachmentSubscription;
  late final StreamSubscription<ReceivedRCard> _vdipSubscription;

  /// A broadcast stream that emits a [ReceivedRCard] whenever a valid,
  /// signature-verified R-Card is received over any channel — either via
  /// the DIDComm attachment path (OOB / inauguration) or the VDIP
  /// issued-credential path (chat-time update).
  Stream<ReceivedRCard> get receivedRCards => _receivedRCardsStream;

  /// Cancels all internal subscriptions and closes [receivedRCards].
  ///
  /// Safe to call more than once — subsequent calls are no-ops.
  Future<void> closeRelationshipStreams() async {
    if (_receivedRCardsController.isClosed) return;
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
