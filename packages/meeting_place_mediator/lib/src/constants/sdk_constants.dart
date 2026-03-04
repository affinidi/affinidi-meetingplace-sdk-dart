const String sdkName = 'MED_SDK';

/// RFC 6455 Section 7.4.1 - WebSocket Close Codes
///
/// Code 1000 (Normal Closure) indicates the connection was intentionally
/// terminated and the session is complete - no reconnection needed.
///
/// Code 1001 (Going Away) indicates the server is shutting down or
/// restarting - we SHOULD reconnect to establish a fresh connection.
///
/// All other codes (including null when TCP drops without close frame)
/// indicate abnormal closure requiring automatic reconnection.
const int webSocketCloseNormal = 1000;
const int webSocketCloseGoingAway = 1001;
