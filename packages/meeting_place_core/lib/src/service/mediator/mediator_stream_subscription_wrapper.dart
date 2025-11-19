import 'dart:async';

import 'package:meeting_place_mediator/meeting_place_mediator.dart'
    as mediator_sdk;
import '../../loggers/meeting_place_core_sdk_logger.dart';
import '../../repository/key_repository.dart';
import 'mediator_message.dart';
import '../core_sdk_stream_subscription.dart';

/// Wrapper around MediatorStreamSubscription that provides transformed
/// mediator messages like decrypting group messages.
class MediatorStreamSubscriptionWrapper
    implements CoreSDKStreamSubscription<MediatorMessage> {
  MediatorStreamSubscriptionWrapper({
    required mediator_sdk.MediatorStreamSubscription baseSubscription,
    required KeyRepository keyRepository,
    required MeetingPlaceCoreSDKLogger logger,
  })  : _baseSubscription = baseSubscription,
        _keyRepository = keyRepository,
        _logger = logger;

  final mediator_sdk.MediatorStreamSubscription _baseSubscription;
  final KeyRepository _keyRepository;
  final MeetingPlaceCoreSDKLogger _logger;

  /// Check if the underlying subscription is closed
  @override
  bool get isClosed => _baseSubscription.isClosed;

  /// Stream of transformed mediator messages
  @override
  Stream<MediatorMessage> get stream {
    return _baseSubscription.stream.asyncMap((data) async {
      try {
        return await MediatorMessage.fromPlainTextMessage(
          data.message,
          keyRepository: _keyRepository,
        );
      } catch (e, stackTrace) {
        _logger.error(
          'Error processing mediator message',
          error: e,
          stackTrace: stackTrace,
          name: 'MediatorMessageSubscription.stream',
        );
        rethrow;
      }
    });
  }

  @override
  StreamSubscription<MediatorMessage> listen(
    void Function(MediatorMessage) onData, {
    Function? onError,
    void Function()? onDone,
    bool? cancelOnError,
  }) {
    return stream.listen(
      onData,
      onError: onError,
      onDone: onDone,
      cancelOnError: cancelOnError,
    );
  }

  @override
  StreamSubscription<MediatorMessage> timeout(
    Duration timeLimit,
    void Function()? onTimeout,
  ) {
    return stream
        .timeout(
          timeLimit,
          onTimeout: onTimeout != null
              ? (EventSink<MediatorMessage> sink) {
                  try {
                    onTimeout();
                  } catch (e, stackTrace) {
                    _logger.error(
                      'Error in timeout callback',
                      error: e,
                      stackTrace: stackTrace,
                    );
                  }
                }
              : null,
        )
        .listen(null);
  }

  /// Dispose the subscription and close the connection
  @override
  Future<void> dispose() async {
    _logger.info('Disposing mediator message subscription');
    await _baseSubscription.dispose();
  }
}
