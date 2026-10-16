import 'package:didcomm/didcomm.dart';
import 'package:ssi/ssi.dart';

import '../../loggers/meeting_place_mediator_sdk_logger.dart';
import '../mediator/message_hash.dart';
import 'mediator_protocol_message_detector.dart';

/// Fetched messages split into those for the app and the unpacked Trust Task
/// responses removed from them.
typedef FilteredMessages = ({
  List<Map<String, dynamic>> appMessages,
  List<PlainTextMessage> responses,
});

/// Removes the Trust Task responses a mediator stores in the inbox from
/// fetched messages, so they never reach the app.
class TrustTaskResponseFilter {
  /// Creates a [TrustTaskResponseFilter] for the inbox of [didManager] on the
  /// mediator [client] is connected to.
  TrustTaskResponseFilter({
    required MediatorClient client,
    required DidManager didManager,
    required MeetingPlaceMediatorSDKLogger logger,
  }) : _client = client,
       _didManager = didManager,
       _logger = logger;

  final MediatorClient _client;
  final DidManager _didManager;
  final MeetingPlaceMediatorSDKLogger _logger;

  /// Splits the Trust Task responses off [messages] and deletes them from the
  /// mediator, unless [deletedOnMediator] says the mediator already
  /// deleted them on retrieval.
  ///
  /// A failed delete is logged instead of thrown, so the app still gets its
  /// messages; the responses are deleted on a later fetch.
  Future<FilteredMessages> removeResponses(
    List<Map<String, dynamic>> messages, {
    bool deletedOnMediator = false,
  }) async {
    final classifiedMessages = await Future.wait(
      messages.map(
        (message) async => (
          message: message,
          response: await MediatorProtocolMessageDetector.unpackProtocolMessage(
            message,
            recipientDidManager: _didManager,
            mediatorDid: _client.mediatorDidDocument.id,
            logger: _logger,
          ),
        ),
      ),
    );

    final responses = [
      for (final classified in classifiedMessages)
        if (classified.response != null) classified,
    ];
    final appMessages = [
      for (final classified in classifiedMessages)
        if (classified.response == null) classified.message,
    ];

    if (responses.isNotEmpty && !deletedOnMediator) {
      await _deleteResponses(
        responses.map((response) => hashMessage(response.message)).toList(),
      );
    }

    return (
      appMessages: appMessages,
      responses: [for (final response in responses) response.response!],
    );
  }

  Future<void> _deleteResponses(List<String> responseHashes) async {
    final methodName = '_deleteResponses';

    try {
      await _client.deleteMessages(messageIds: responseHashes);
      _logger.info(
        'Removed ${responseHashes.length} mediator Trust Task response(s)',
        name: methodName,
      );
    } catch (e, stackTrace) {
      _logger.error(
        'Failed to delete ${responseHashes.length} mediator Trust Task '
        'response(s); skipping them',
        error: e,
        stackTrace: stackTrace,
        name: methodName,
      );
    }
  }
}
