const String sdkName = 'CHAT_SDK';

/// Checks if the provided [loggerName] matches the ChatSDK logger name.
///
/// Returns `true` if [loggerName] is associated
/// with ChatSDK, otherwise `false`.
bool isSdkLogger(String loggerName) => loggerName.contains(sdkName);
