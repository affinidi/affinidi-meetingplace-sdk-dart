import 'package:didcomm/didcomm.dart';

import '../../entity/channel.dart';

/// Represents the type of OOB event that can occur.
/// Used by [OobStreamData] to indicate the reason why the event
/// was emitted to the OOB stream.
enum EventType { connectionSetup, connectionAccepted }

/// Defines an event emitted to the (OOB) stream.
/// An [OobStreamData] instance is created whenever an OOB trigger occurs, such
/// as a connection setup or connection acceptance. It encapsulates the type of
/// event, the associated message, and the channel where the event originated.
class OobStreamData {
  /// Creates a new OOB stream event.
  ///
  /// [eventType] describes the kind of OOB event that occurred,
  /// [message] carries DIDComm message associated to the event, and
  /// [channel] represents the channel entity associated to the OOB flow.
  OobStreamData({
    required this.eventType,
    required this.message,
    required this.channel,
  });

  /// The type of event that occurred.
  final EventType eventType;

  /// The DIDComm message associated with the event.
  final PlainTextMessage message;

  /// The channel associated to the OOB flow.
  final Channel channel;
}
