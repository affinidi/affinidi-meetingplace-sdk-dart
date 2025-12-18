import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';

import '../../api/api_client.dart';
import 'package:ssi/ssi.dart';

import '../../api/control_plane_api_client.dart';
import '../../constants/sdk_constants.dart';
import '../../core/command/command_handler.dart';
import '../../control_plane_sdk_options.dart';
import '../../loggers/default_control_plane_sdk_logger.dart';
import '../../loggers/control_plane_sdk_logger.dart';
import '../../utils/base64.dart';
import '../../utils/mediator/mediator_utils.dart';
import 'register_offer_group.dart';
import 'register_offer_group_exception.dart';
import 'register_offer_group_output.dart';

/// A concreate implementation of the [CommandHandler] interface.
///
/// Handles communication with the API server, including sending requests,
/// receiving responses, and validating the returned data for Register Offer
/// Group operation.
class RegisterOfferGroupHandler
    implements
        CommandHandler<
          RegisterOfferGroupCommand,
          RegisterOfferGroupCommandOutput
        > {
  /// Returns an instance of [RegisterOfferHandler].
  ///
  /// **Parameters:**
  /// - [apiClient] - An instance of discovery api client object.
  /// - [mediatorDid] - The mediator did string.
  /// - [sdkConfig] - An instance of discovery sdk config object.
  /// - [didResolver] - An instance of did resolver object.
  RegisterOfferGroupHandler({
    required this.apiClient,
    required this.mediatorDid,
    required this.sdkConfig,
    required this.didResolver,
    ControlPlaneSDKLogger? logger,
  }) : _logger =
           logger ??
           DefaultControlPlaneSDKLogger(
             className: _className,
             sdkName: sdkName,
           );
  static const String _className = 'RegisterOfferGroupHandler';

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
  /// - [command]: Register Offer Group command object.
  ///
  /// **Returns:**
  /// - [RegisterOfferGroupCommandOutput]: The register offer group command
  /// output object.
  ///
  /// **Throws:**
  /// - [RegisterOfferGroupException]: Exception thrown by the register offer
  /// group operation.
  @override
  Future<RegisterOfferGroupCommandOutput> handle(
    RegisterOfferGroupCommand command,
  ) async {
    final methodName = 'handle';
    _logger.info(
      'Started registering offer group: ${command.offerName}',
      name: methodName,
    );

    final mediatorForOffer = await MediatorUtils.getMediatorConfig(
      didResolver: didResolver,
      defaultMediatorDid: mediatorDid,
      selectedMediatorDid: command.mediatorDid,
    );

    if (mediatorForOffer == null) {
      _logger.error(
        'Failed to register offer group "${command.offerName}": mediator configuration is missing.',
        name: methodName,
      );
      throw RegisterOfferGroupException.mediatorNotSet();
    }

    final builder = RegisterOfferGroupInputBuilder()
      ..offerName = command.offerName
      ..offerDescription = command.offerDescription
      ..didcommMessage = toBase64(command.oobInvitationMessage.toJson())
      ..contactCard = command.contactCard.toBase64()
      ..validUntil = command.validUntil?.toUtc().toIso8601String()
      ..maximumUsage = command.maximumUsage
      ..deviceToken = command.device.deviceToken
      ..platformType = RegisterOfferGroupInputPlatformTypeEnum.valueOf(
        command.device.platformType.value,
      )
      ..mediatorDid = mediatorForOffer.mediatorDid
      ..mediatorEndpoint = mediatorForOffer.mediatorEndpoint
      ..mediatorWSSEndpoint = mediatorForOffer.mediatorWSSEndpoint
      ..customPhrase = command.customPhrase
      ..metadata = command.metadata
      ..adminDid = command.adminDid
      ..adminPublicKey = command.adminPublicKey
      ..adminReencryptionKey = command.adminReencryptionKey
      ..memberContactCard = base64Url.encode(utf8.encode('{}'));

    try {
      _logger.info('[MPX API] calling /register-offer', name: methodName);
      final response = await apiClient.client.registerOfferToConnectGroup(
        registerOfferGroupInput: builder.build(),
      );

      _logger.info(
        'Completed registering offer: ${command.offerName}\n'
        'mnemonic: ${response.data!.mnemonic}\n'
        'expires At: ${response.data?.validUntil ?? "N/A"}\n'
        'maximum Usage: ${response.data!.maximumUsage}',
        name: methodName,
      );
      return RegisterOfferGroupCommandOutput(
        groupId: response.data!.groupId,
        groupDid: response.data!.groupDid,
        offerLink: response.data!.offerLink,
        mnemonic: response.data!.mnemonic,
        expiresAt: response.data?.validUntil != null
            ? DateTime.parse(response.data!.validUntil!)
            : null,
        maximumUsage: response.data!.maximumUsage,
        mediatorDid: mediatorForOffer.mediatorDid,
        oobInvitationMessage: command.oobInvitationMessage,
      );
    } catch (e, stackTrace) {
      if (e is DioException && e.response?.statusCode == HttpStatus.conflict) {
        _logger.error(
          'Offer group with the same mnemonic already exists: ${command.customPhrase}',
          error: e,
          stackTrace: stackTrace,
        );
        throw RegisterOfferGroupException.mnemonicInUse();
      }

      _logger.error(
        'Failed to register offer group: ${command.offerName}',
        error: e,
        stackTrace: stackTrace,
        name: methodName,
      );

      Error.throwWithStackTrace(
        RegisterOfferGroupException.generic(innerException: e),
        stackTrace,
      );
    }
  }
}
