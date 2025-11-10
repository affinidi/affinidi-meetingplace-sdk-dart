import 'dart:convert';

import 'package:ssi/ssi.dart';
import '../../api/api_client.dart';

import '../../api/control_plane_api_client.dart';
import '../../api/auth_credentials.dart';
import '../../constants/sdk_constants.dart';
import '../../core/command/command_handler.dart';
import '../../loggers/default_control_plane_sdk_logger.dart';
import '../../loggers/control_plane_sdk_logger.dart';
import '../../core/protocol/message/auth_challenge.dart';
import '../../utils/didcomm.dart';
import '../../utils/string.dart';
import 'authenticate.dart';
import 'authenticate_exception.dart';
import 'authenticate_output.dart';

/// A concreate implementation of the [CommandHandler] interface.
///
/// Handles communication with the API server, including sending requests,
/// receiving responses, and validating the returned data for Authenticate
/// operation.
class AuthenticateHandler
    implements CommandHandler<AuthenticateCommand, AuthenticateCommandOutput> {
  /// Returns an instance of [AuthenticateHandler].
  ///
  /// **Parameters:**
  /// - [discoveryApiClient] - An instance of discovery api client object.
  /// - [didManager]: The did manager object.
  /// - [didResolver]: The did resolver object.
  AuthenticateHandler({
    required ControlPlaneApiClient apiClient,
    required DidManager didManager,
    required DidResolver didResolver,
    ControlPlaneSDKLogger? logger,
  })  : _apiClient = apiClient,
        _didManager = didManager,
        _didResolver = didResolver,
        _logger = logger ??
            DefaultControlPlaneSDKLogger(
              className: _className,
              sdkName: sdkName,
            );

  static const String _className = 'AuthenticateHandler';

  final ControlPlaneApiClient _apiClient;
  final DidManager _didManager;
  final DidResolver _didResolver;

  final ControlPlaneSDKLogger _logger;

  /// Fetch the Auth Credentials from the provided did document.
  ///
  /// **Parameters:**
  /// - [authServiceDidDocument]: The DID Document object.
  ///
  /// **Returns:**
  /// - [AuthCredentials]: Object that contains the accessToken, refreshToken
  /// along with its expiration.
  Future<AuthCredentials> _getCredentials({
    required DidDocument authServiceDidDocument,
  }) async {
    final methodName = '_getCredentials';
    _logger.info('Starting getting credentials', name: methodName);

    final senderDidDocument = await _didManager.getDidDocument();
    final challengeBuilder = DidChallengeBuilder()..did = senderDidDocument.id;

    final challengeResponse = await _apiClient.client.didChallenge(
      didChallenge: challengeBuilder.build(),
    );

    final challenge = challengeResponse.data?.challenge;
    if (challenge == null) {
      _logger.error(
        'Empty challenge returned from didChallenge',
        name: methodName,
      );
      throw AuthenticateException.emptyChallengeReturned(
        did: senderDidDocument.id,
      );
    }

    /// Construct a plain text message that we will
    /// later encrypt before sending. Note that the
    /// [type] must be the known verb for the mediator
    /// to initiate an auth challenge
    final plaintextAuth = MeetingplaceAuthChallenge.create(
      from: senderDidDocument.id,
      to: [authServiceDidDocument.id],
      challenge: challenge,
    );

    final encryptedMessageAuth = await signAndEncryptMessage(
      plaintextAuth,
      senderDidManager: _didManager,
      recipientDidDocument: authServiceDidDocument,
    );

    final didAuthenticateBuilder = DidAuthenticateBuilder()
      ..challengeResponse = base64Encode(
        utf8.encode(jsonEncode(encryptedMessageAuth)),
      );

    _logger.info(
      '[MPX API] Sending authentication request to /did-authenticate for DID: ${senderDidDocument.id.topAndTail()}',
      name: methodName,
    );
    final response = await _apiClient.client.didAuthenticate(
      didAuthenticate: didAuthenticateBuilder.build(),
    );

    final authCredentials = parseAthenticationResponse(response.data);

    _logger.info(
      'Completed getting authentication credentials. Access token expires at ${authCredentials.accessExpiresAt.toIso8601String()}',
    );

    return authCredentials;
  }

  /// Parses the authentication response to derive the [AuthCredentials].
  ///
  /// **Parameters:**
  /// - [data]: The DID Authentication response data.
  ///
  /// **Returns:**
  /// - [authCredentials]: The auth credentials data.
  AuthCredentials parseAthenticationResponse(DidAuthenticateOK? data) {
    final methodName = 'parseAuthenticationResponse';
    if (data == null) {
      final message = 'Response data is null';
      _logger.error(message, name: methodName);
      throw AuthenticateException.invalidResponseData(message: message);
    }

    String requireField(String? value, String fieldName) {
      if (value == null || value.trim().isEmpty) {
        final message = "Missing or empty '$fieldName' in response data.";
        _logger.error(message, name: methodName);
        throw AuthenticateException.invalidResponseData(message: message);
      }
      _logger.info(
        'Successfully validated field: $fieldName',
        name: methodName,
      );
      return value;
    }

    DateTime parseDateField(String? value, String fieldName) {
      final stringValue = requireField(value, fieldName);
      final parsed = DateTime.tryParse(stringValue);
      if (parsed == null) {
        final message = "Invalid date format for '$fieldName': $stringValue";
        _logger.error(message, name: methodName);
        throw AuthenticateException.invalidResponseData(message: message);
      }
      _logger.info(
        'Successfully parsed date field: $fieldName',
        name: methodName,
      );
      return parsed;
    }

    _logger.info(
      'Completed validating authentication response fields',
      name: methodName,
    );
    return AuthCredentials(
      accessToken: requireField(data.accessToken, 'accessToken'),
      refreshToken: requireField(data.refreshToken, 'refreshToken'),
      accessExpiresAt: parseDateField(data.accessExpiresAt, 'accessExpiresAt'),
      refreshExpiresAt: parseDateField(
        data.refreshExpiresAt,
        'refreshExpiresAt',
      ),
    );
  }

  /// Overrides the method [CommandHandler.handle].
  ///
  /// This prepares the request that will be sent to the API server and
  /// validates the response. This also handles the exception that are returned
  /// by the API server.
  ///
  /// **Parameters:**
  /// - [command]: Authenticate command object.
  ///
  /// **Returns:**
  /// - [AuthenticateCommandOutput]: The authenticate command output object.
  @override
  Future<AuthenticateCommandOutput> handle(AuthenticateCommand command) async {
    final methodName = 'handle';
    _logger.info(
      'Started authentication for service DID: ${command.controlPlaneDid.topAndTail()}',
      name: methodName,
    );

    final meetingplaceDidDoc = await _didResolver.resolveDid(
      command.controlPlaneDid,
    );

    final authCredentials = await _getCredentials(
      authServiceDidDocument: meetingplaceDidDoc,
    );

    _apiClient.setApiKey(authCredentials.accessToken);
    _logger.info(
      'Completed authentication for service DID: ${command.controlPlaneDid.topAndTail()}',
      name: methodName,
    );
    return AuthenticateCommandOutput(credentials: authCredentials);
  }
}
