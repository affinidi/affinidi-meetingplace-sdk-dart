part of 'chat_event.dart';

/// A visual effect (e.g. confetti, balloons) was received or sent.
final class ChatEffectEvent extends ChatEvent {
  const ChatEffectEvent({required this.effectName});

  /// Name of the effect (e.g. `confetti`, `balloons`).
  final String effectName;
}
