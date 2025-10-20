import '../../exception/mpx_exception.dart';

enum ConnectionOfferExceptionCodes {
  connectionOfferOwnedByClaimingParty(
    'connection_offer_owned_by_claiming_party',
  ),
  connectionOfferAlreadyClaimedByClaimingParty(
    'connection_offer_already_claimed_by_claiming_party',
  ),
  publishOfferError('connection_offer_publish_offer_error'),
  offerNotFoundError('connection_offer_not_found_error'),
  permanentChannelDidError('connection_offer_permanent_channel_did_error'),
  notAcceptedError('connection_offer_not_accepted_error'),
  alreadyFinalised('connection_offer_already_finalised'),
  offerDoesNotExistError('connection_offer_does_not_exist');

  const ConnectionOfferExceptionCodes(this.code);

  final String code;
}

class ConnectionOfferException implements MpxException {
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
      code: ConnectionOfferExceptionCodes.connectionOfferOwnedByClaimingParty,
      innerException: innerException,
    );
  }

  factory ConnectionOfferException.alreadyClaimedByClaimingPartyError({
    Object? innerException,
  }) {
    return ConnectionOfferException(
      message: 'Offer already claimed by claiming party.',
      code: ConnectionOfferExceptionCodes
          .connectionOfferAlreadyClaimedByClaimingParty,
      innerException: innerException,
    );
  }

  factory ConnectionOfferException.offerNotFoundError({
    Object? innerException,
  }) {
    return ConnectionOfferException(
      message: 'Offer not found.',
      code: ConnectionOfferExceptionCodes.offerNotFoundError,
      innerException: innerException,
    );
  }

  factory ConnectionOfferException.publishOfferError({Object? innerException}) {
    return ConnectionOfferException(
      message: 'Publishing offer failed: ${innerException.toString()}',
      code: ConnectionOfferExceptionCodes.publishOfferError,
      innerException: innerException,
    );
  }

  factory ConnectionOfferException.permanentChannelDidError({
    Object? innerException,
  }) {
    return ConnectionOfferException(
      message: 'Permanent channel did is expected to be present',
      code: ConnectionOfferExceptionCodes.permanentChannelDidError,
      innerException: innerException,
    );
  }

  factory ConnectionOfferException.notAcceptedError({Object? innerException}) {
    return ConnectionOfferException(
      message: 'Connection offer must be accepted',
      code: ConnectionOfferExceptionCodes.notAcceptedError,
      innerException: innerException,
    );
  }

  factory ConnectionOfferException.alreadyFinalised({Object? innerException}) {
    return ConnectionOfferException(
      message: 'Connection offer is already finalised',
      code: ConnectionOfferExceptionCodes.alreadyFinalised,
      innerException: innerException,
    );
  }

  factory ConnectionOfferException.offerDoesNotExistError({
    Object? innerException,
  }) {
    return ConnectionOfferException(
      message: 'Offer does not exist.',
      code: ConnectionOfferExceptionCodes.offerDoesNotExistError,
      innerException: innerException,
    );
  }
  @override
  final String message;

  final ConnectionOfferExceptionCodes code;

  @override
  final Object? innerException;

  @override
  String get errorCode => code.code;
}
