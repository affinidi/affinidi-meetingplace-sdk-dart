part of 'chat_event.dart';

/// A canonical call outcome was received for a call in this chat.
///
/// Emitted when any participant leaves a call and posts the shared outcome
/// record. Consumers reconcile the existing call chat item by [callId] and
/// converge on the full call duration ([endedAt] minus [startedAt]).
///
/// [endedAt] is the authoritative homeserver timestamp of the outcome event,
/// never a client clock. When multiple participants post an outcome, the
/// event carrying the latest [endedAt] is the truly-last leaver and wins.
final class CallOutcomeChatEvent extends ChatEvent {
  const CallOutcomeChatEvent({
    required this.callId,
    required this.outcome,
    required this.endedAt,
    this.startedAt,
  });

  /// Identifier of the call this outcome reconciles.
  final String callId;

  /// Canonical outcome name (matches `CallOutcome.name`).
  final String outcome;

  /// Authoritative call end time from the homeserver.
  final DateTime endedAt;

  /// Call connect time carried in the outcome record, if known.
  final DateTime? startedAt;
}
