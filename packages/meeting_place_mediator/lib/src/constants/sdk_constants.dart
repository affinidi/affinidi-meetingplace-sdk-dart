const String sdkName = 'MED_SDK';

/// RFC 6455 Section 7.4.1 - WebSocket Close Codes
///
/// Normal closure codes that indicate intentional disconnection:
/// - 1000: Normal Closure - connection fulfilled its purpose
/// - 1001: Going Away - endpoint shutting down (server restart, browser tab close)
///
/// All other codes or null (TCP dropped without close frame) indicate
/// abnormal closure requiring automatic reconnection.
const int webSocketCloseNormal = 1000;
const int webSocketCloseGoingAway = 1001;
const Set<int> webSocketNormalCloseCodes = {
  webSocketCloseNormal,
  webSocketCloseGoingAway
};
