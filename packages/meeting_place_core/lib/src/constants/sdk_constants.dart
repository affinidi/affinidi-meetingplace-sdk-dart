const String coreSDKName = 'CORE_SDK';
const String mediatorSDKName = 'MED_SDK';
const String controlPlaneSDKName = 'CPLANE_SDK';

/// Checks if the provided [loggerName] matches any MPX-related SDK logger name.
///
/// Returns `true` if [loggerName] is associated with MPX, Discovery, or Mediator SDK.
bool isSdkLogger(String loggerName) {
  const sdkLoggerNames = {coreSDKName, controlPlaneSDKName, mediatorSDKName};
  return sdkLoggerNames.any((sdkName) => loggerName.contains(sdkName));
}
