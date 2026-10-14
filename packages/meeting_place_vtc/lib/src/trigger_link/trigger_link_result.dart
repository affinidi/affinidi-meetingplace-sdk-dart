import 'trigger_link_config.dart';

/// What a person is told about a trigger link they cannot use.
enum TriggerLinkUi {
  /// "This code needs a newer version of the app."
  update,

  /// "This code has expired. Get a new one."
  expired,

  /// "This service can't be reached from your wallet."
  unreachable,

  /// "This code can't be used."
  invalid,

  /// Not a trigger link: hand it to the scanner's other handlers unchanged.
  passOn,
}

/// The outcome of reading a trigger link.
sealed class TriggerLinkResult {
  const TriggerLinkResult();

  /// What the app does with this result for [config]: carry an implemented
  /// flow through, or tell the person one of the [TriggerLinkUi] outcomes.
  ///
  /// A link with no flow, or a known flow the app does not implement, is
  /// [TriggerLinkUi.update].
  TriggerLinkUi? uiFor(TriggerLinkConfig config) {
    return switch (this) {
      TriggerLinkRejected(:final ui) => ui,
      TriggerLinkAccepted(:final flow) =>
        config.flows.any((f) => f.flow == flow && f.implemented)
            ? null
            : TriggerLinkUi.update,
    };
  }
}

/// The versioned flow type a link names.
class TriggerTask {
  /// Creates a [TriggerTask].
  const TriggerTask({
    required this.uri,
    required this.major,
    required this.minor,
  });

  /// Absolute type URI, including the version.
  final String uri;

  /// Major version.
  final int major;

  /// Minor version.
  final int minor;
}

/// A link that reads: who sent it, its handle, its expiry and its flow.
class TriggerLinkAccepted extends TriggerLinkResult {
  /// Creates a [TriggerLinkAccepted].
  const TriggerLinkAccepted({
    required this.from,
    required this.id,
    required this.exp,
    required this.flow,
    required this.task,
    required this.ignored,
  });

  /// DID of the sender, e.g. the VTC.
  final String from;

  /// Request handle, e.g. the sign-in request id.
  final String id;

  /// Expiry in seconds since the epoch, if the link carries one.
  final int? exp;

  /// Label of the flow, if the link names a known one.
  final String? flow;

  /// Versioned flow type, if the link names one.
  final TriggerTask? task;

  /// `fragment.<name>` for each unknown name beginning with `_`, in order.
  final List<String> ignored;
}

/// A link that cannot be used.
class TriggerLinkRejected extends TriggerLinkResult {
  /// Creates a [TriggerLinkRejected].
  const TriggerLinkRejected({required this.reason, required this.ui});

  /// Rejects for [reason], with the words the spec assigns to it.
  factory TriggerLinkRejected.because(String reason) {
    return TriggerLinkRejected(
      reason: reason,
      ui: _uiForReason[reason] ?? TriggerLinkUi.invalid,
    );
  }

  static const _uiForReason = {
    'unsupported-vid': TriggerLinkUi.update,
    'unknown-flow': TriggerLinkUi.update,
    'unsupported-version': TriggerLinkUi.update,
    'expired': TriggerLinkUi.expired,
    'no-common-transport': TriggerLinkUi.unreachable,
    'not-ours': TriggerLinkUi.passOn,
  };

  /// Spec reason code, e.g. `bad-id`. Never contains link text.
  final String reason;

  /// Class of words to show.
  final TriggerLinkUi ui;
}
