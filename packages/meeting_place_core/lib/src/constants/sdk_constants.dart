import 'package:meeting_place_mediator/meeting_place_mediator.dart'
    as media_const;
import 'package:meeting_place_control_plane/meeting_place_control_plane.dart'
    as control_plane_const;

const String coreSDKName = 'CORE_SDK';
const String controlPlaneSDKName = control_plane_const.sdkName;
const String mediatorSDKName = media_const.sdkName;

/// Checks if the provided [loggerName] matches any MPX-related SDK logger name.
///
/// Returns `true` if [loggerName] is associated with MPX, Discovery, or Mediator SDK.
bool isSdkLogger(String loggerName) {
  const sdkLoggerNames = {coreSDKName, controlPlaneSDKName, mediatorSDKName};
  return sdkLoggerNames.any((sdkName) => loggerName.contains(sdkName));
}
