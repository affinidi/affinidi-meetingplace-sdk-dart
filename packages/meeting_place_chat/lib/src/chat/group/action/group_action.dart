import '../../../../meeting_place_chat.dart';

/// Common shape for all group chat side-effects that are extracted from
/// [GroupChatSDK]. Each action wraps a single SDK-bound operation, performs its
/// side effects, and returns a result of type [R] (use `void` when no result is
/// needed).
///
/// Implementations should:
/// - Take a [GroupChatSDK] via constructor.
/// - Carry any per-call parameters as constructor args or `execute` args.
/// - Perform their own preconditions (e.g. `_chatSDK.isGroupOwner`).
abstract interface class GroupAction<R> {
  Future<R> execute();
}
