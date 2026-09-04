import 'package:didcomm/didcomm.dart';

import '../../../entity/channel.dart';

/// Represents the type of event that can occur during a direct connection.
/// Used by [DirectConnectionStreamData] to indicate the reason why the event
/// was emitted to the direct connection stream.
enum EventType { connectionSetup, connectionAccepted }

/// Defines an event emitted to the direct connection stream.
/// A [DirectConnectionStreamData] instance is created whenever a direct
/// connection trigger occurs, such as a connection setup or connection
/// acceptance. It encapsulates the type of event, the associated message, and
/// the channel where the event originated.
class DirectConnectionStreamData {
  /// Creates a new direct connection stream event.
  ///
  /// [eventType] describes the kind of event that occurred,
  /// [message] carries DIDComm message associated to the event, and
  /// [channel] represents the channel entity associated to the direct
  /// connection.
  DirectConnectionStreamData({
    required this.eventType,
    required this.message,
    required this.channel,
  });

  /// The type of event that occurred.
  final EventType eventType;

  /// The DIDComm message associated with the event.
  final PlainTextMessage message;

  /// The channel associated to the direct connection.
  final Channel channel;
}
