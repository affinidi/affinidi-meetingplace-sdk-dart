import 'dart:async';

import '../../api/api_client.dart';
import 'package:ssi/ssi.dart';

import '../../api/control_plane_api_client.dart';
import '../../constants/sdk_constants.dart';
import '../../core/command/command_handler.dart';
import '../../control_plane_sdk_options.dart';
import '../../core/offer_type.dart';
import '../../loggers/default_control_plane_sdk_logger.dart';
import '../../loggers/control_plane_sdk_logger.dart';
import '../../utils/base64.dart';
import '../../utils/mediator/mediator_utils.dart';
import 'register_offer.dart';
import 'register_offer_exception.dart';
import 'register_offer_output.dart';

/// A concreate implementation of the [CommandHandler] interface.
///
/// Handles communication with the API server, including sending requests,
/// receiving responses, and validating the returned data for Register Offer
/// operation.
class RegisterOfferHandler
    implements
        CommandHandler<RegisterOfferCommand, RegisterOfferCommandOutput> {
  /// Returns an instance of [RegisterOfferHandler].
  ///
  /// **Parameters:**
  /// - [apiClient] - An instance of discovery api client object.
  /// - [mediatorDid] - The mediator did string.
  /// - [sdkConfig] - An instance of discovery sdk config object.
  /// - [didResolver] - An instance of did resolver object.
  RegisterOfferHandler({
    required this.apiClient,
    required this.mediatorDid,
    required this.sdkConfig,
    required this.didResolver,
    ControlPlaneSDKLogger? logger,
  }) : _logger = logger ??
            DefaultControlPlaneSDKLogger(
                className: _className, sdkName: sdkName);
  static const String _className = 'RegisterOfferHandler';

  final ControlPlaneApiClient apiClient;
  final String mediatorDid;
  final ControlPlaneSDKOptions sdkConfig;
  final DidResolver didResolver;
  final ControlPlaneSDKLogger _logger;

  /// Overrides the method [CommandHandler.handle].
  ///
  /// This prepares the request that will be sent to the API server and
  /// validates the response. This also handles the exception that are returned
  /// by the API server.
  ///
  /// **Parameters:**
  /// - [command]: Register Offer command object.
  ///
  /// **Returns:**
  /// - [RegisterOfferCommandOutput]: The register offer command output
  /// object.
  ///
  /// **Throws:**
  /// - [RegisterOfferException]: Exception thrown by the register offer
  /// operation.
  @override
  Future<RegisterOfferCommandOutput> handle(
    RegisterOfferCommand command,
  ) async {
    final methodName = 'handle';
    _logger.info(
      'Started registering offer: ${command.offerName}',
      name: methodName,
    );

    final mediatorForOffer = await MediatorUtils.getMediatorConfig(
      didResolver: didResolver,
      defaultMediatorDid: mediatorDid,
      selectedMediatorDid: command.mediatorDid,
    );

    if (mediatorForOffer == null) {
      _logger.error(
        'No mediator found for offer: ${command.offerName}',
        name: methodName,
      );
      throw RegisterOfferException.mediatorNotSet();
    }

    final builder = RegisterOfferInputBuilder()
      ..offerName = command.offerName
      ..offerDescription = command.offerDescription
      ..didcommMessage = toBase64(command.oobInvitationMessage.toJson())
      ..vcard = command.vCard.toBase64()
      ..validUntil = command.validUntil?.toUtc().toIso8601String()
      ..maximumUsage = command.maximumUsage
      ..deviceToken = command.device.deviceToken
      ..platformType = RegisterOfferInputPlatformTypeEnum.valueOf(
        command.device.platformType.value,
      )
      ..contactAttributes = command.type == OfferType.outreachInvitation ? 2 : 1
      ..offerType = RegisterOfferInputOfferTypeEnum.number1
      ..mediatorDid = mediatorForOffer.mediatorDid
      ..mediatorEndpoint = mediatorForOffer.mediatorEndpoint
      ..mediatorWSSEndpoint = mediatorForOffer.mediatorWSSEndpoint
      ..customPhrase = command.customPhrase;

    try {
      _logger.info(
        '[MPX API] Sending request to /register-offer with offerName: ${builder.offerName}',
        name: methodName,
      );
      final response = await apiClient.client.registerOfferToConnect(
        registerOfferInput: builder.build(),
      );

      _logger.info(
        'Completed registering offer: ${command.offerName}\n'
        'mnemonic: ${response.data!.mnemonic}\n'
        'expires At: ${response.data?.validUntil ?? "N/A"}\n'
        'maximum Usage: ${response.data!.maximumUsage}',
        name: methodName,
      );
      return RegisterOfferCommandOutput(
        offerName: command.offerName,
        offerDescription: command.offerDescription,
        offerLink: response.data!.offerLink,
        mnemonic: response.data!.mnemonic,
        expiresAt: response.data?.validUntil != null
            ? DateTime.parse(response.data!.validUntil!)
            : null,
        didcommMessage: command.oobInvitationMessage,
        maximumUsage: response.data!.maximumUsage,
        mediatorDid: mediatorForOffer.mediatorDid,
      );
    } catch (e, stackTrace) {
      _logger.error(
        'Failed to register offer: ${command.offerName}',
        error: e,
        stackTrace: stackTrace,
        name: methodName,
      );
      Error.throwWithStackTrace(
        RegisterOfferException.generic(innerException: e),
        stackTrace,
      );
    }
  }
}
