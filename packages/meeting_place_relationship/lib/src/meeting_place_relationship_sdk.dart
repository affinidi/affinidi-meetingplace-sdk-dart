import 'package:meeting_place_core/meeting_place_core.dart';
import 'package:ssi/ssi.dart';

import 'models/r_card/received_r_card.dart';
import 'parsers/r_card_parser.dart';
import 'parsers/vrc_parser.dart';
import 'r_card_channel_stream_manager.dart';

/// The Meeting Place Relationship SDK.
///
/// Provides typed, high-level access to R-Card and VRC exchange flows on
/// top of `MeetingPlaceCoreSDK`. Constructed once per session and
/// injected wherever relationship features are needed.
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
  }) : _logger =
           logger ?? DefaultMeetingPlaceCoreSDKLogger(className: _className) {
    _rCardParser = RCardParser(logger: _logger);
    _vrcParser = VrcParser(logger: _logger);
    _streamManager = RCardChannelStreamManager(
      channelAttachments: coreSDK.channelAttachments,
      parser: _rCardParser,
      logger: _logger,
    );
  }

  static const _className = 'MeetingPlaceRelationshipSDK';

  late final RCardParser _rCardParser;
  late final VrcParser _vrcParser;
  late final RCardChannelStreamManager _streamManager;
  final MeetingPlaceCoreSDKLogger _logger;

  /// A broadcast stream that emits a [ReceivedRCard] whenever a valid,
  /// signature-verified R-Card is received over any channel.
  Stream<ReceivedRCard> get receivedRCards => _streamManager.stream;

  /// Cancels the internal subscription and closes [receivedRCards].
  ///
  /// Call this when the SDK is no longer needed (e.g. on sign-out).
  Future<void> closeRelationshipStreams() => _streamManager.close();

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
