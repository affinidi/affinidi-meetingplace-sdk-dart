import '../../exception/sdk_exception.dart';
import '../../meeting_place_core_sdk_error_code.dart';

class ConnectionOfferException implements SDKException {
  ConnectionOfferException({
    required this.message,
    required this.code,
    this.innerException,
  });

  factory ConnectionOfferException.ownedByClaimingPartyError({
    Object? innerException,
  }) {
    return ConnectionOfferException(
      message: 'Failed to claim offer because claiming party is the owner.',
      code: MeetingPlaceCoreSDKErrorCode.connectionOfferOwnedByClaimingParty,
      innerException: innerException,
    );
  }

  factory ConnectionOfferException.alreadyClaimedByClaimingPartyError({
    Object? innerException,
  }) {
    return ConnectionOfferException(
      message: 'Offer already claimed by claiming party.',
      code: MeetingPlaceCoreSDKErrorCode
          .connectionOfferAlreadyClaimedByClaimingParty,
      innerException: innerException,
    );
  }

  factory ConnectionOfferException.offerNotFoundError({
    Object? innerException,
  }) {
    return ConnectionOfferException(
      message: 'Offer not found.',
      code: MeetingPlaceCoreSDKErrorCode.connectionOfferNotFoundError,
      innerException: innerException,
    );
  }

  factory ConnectionOfferException.publishOfferError({Object? innerException}) {
    return ConnectionOfferException(
      message: 'Publishing offer failed: ${innerException.toString()}',
      code: MeetingPlaceCoreSDKErrorCode.connectionOfferPublishError,
      innerException: innerException,
    );
  }

  factory ConnectionOfferException.permanentChannelDidError({
    Object? innerException,
  }) {
    return ConnectionOfferException(
      message: 'Permanent channel did is expected to be present',
      code:
          MeetingPlaceCoreSDKErrorCode.connectionOfferPermanentChannelDidError,
      innerException: innerException,
    );
  }

  factory ConnectionOfferException.notAcceptedError({Object? innerException}) {
    return ConnectionOfferException(
      message: 'Connection offer must be accepted',
      code: MeetingPlaceCoreSDKErrorCode.connectionOfferNotAcceptedError,
      innerException: innerException,
    );
  }

  factory ConnectionOfferException.alreadyFinalised({Object? innerException}) {
    return ConnectionOfferException(
      message: 'Connection offer is already finalised',
      code: MeetingPlaceCoreSDKErrorCode.connectionOfferAlreadyFinalised,
      innerException: innerException,
    );
  }

  factory ConnectionOfferException.invalidConnectionOfferType({
    Object? innerException,
  }) {
    return ConnectionOfferException(
      message: 'Connection offer is of invalid type',
      code: MeetingPlaceCoreSDKErrorCode.connectionOfferInvalidType,
      innerException: innerException,
    );
  }

  factory ConnectionOfferException.limitExceeded({
    Object? innerException,
  }) {
    return ConnectionOfferException(
      message: 'Offer limit exceeded',
      code: MeetingPlaceCoreSDKErrorCode.connectionOfferLimitExceeded,
      innerException: innerException,
    );
  }

  factory ConnectionOfferException.expired({
    Object? innerException,
  }) {
    return ConnectionOfferException(
      message: 'Offer expired',
      code: MeetingPlaceCoreSDKErrorCode.connectionOfferExpired,
      innerException: innerException,
    );
  }

  @override
  final String message;

  @override
  final MeetingPlaceCoreSDKErrorCode code;

  @override
  final Object? innerException;
}
