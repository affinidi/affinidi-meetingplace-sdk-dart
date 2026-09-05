// Most SDK-method-argument classes here use the `Request` suffix, matching
// the convention used elsewhere in the SDK (e.g. `PublishOfferRequest`).
//
// RequestVrcExchangeParams and ReceivedVrcRequestParams keep the `Params`
// suffix instead: this package already has a `VrcRequest` protocol-model
// class, and a mechanical `*Request` rename would double up with a
// method name that already contains the word "Request" —
// `requestVrcExchange` -> `RequestVrcExchangeRequest`, and
// `handleReceivedVrcRequest` -> `ReceivedVrcRequestRequest`, the latter
// also wrapping a `request: VrcRequest` field. `Params` sidesteps both.

export 'received_vrc_params.dart';
export 'received_vrc_request_params.dart';
export 'request_vrc_exchange_params.dart';
export 'send_vrc_request.dart';
export 'store_vrc_request.dart';
