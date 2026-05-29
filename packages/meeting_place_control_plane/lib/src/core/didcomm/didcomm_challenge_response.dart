import 'dart:convert';

import 'package:didcomm/didcomm.dart';
import 'package:dio/dio.dart';
import 'package:ssi/ssi.dart';

import '../../api/api_client.dart';
import '../../api/control_plane_api_client.dart';
import '../protocol/protocol.dart';

/// Encoded DIDComm challenge-response payload together with the authenticated
/// sender DID that produced it.
class DidCommChallengeResponse {
  /// Creates a new instance of [DidCommChallengeResponse].
  DidCommChallengeResponse({
    required this.senderDid,
    required this.challengeResponse,
  });

  /// DID of the sender that answered the DID challenge.
  final String senderDid;

  /// Base64-encoded DIDComm packed challenge response payload.
  final String challengeResponse;

  /// Creates a `challengeProvider` callback that requests a challenge from
  /// the `/v1/matrix/challenge` endpoint via the given [dio] instance.
  static Future<String?> Function(String did) matrixChallengeProvider(Dio dio) {
    return (String did) async {
      final response = await dio.post<Map<String, dynamic>>(
        '/v1/matrix/challenge',
        data: {'did': did},
        options: Options(
          headers: {Headers.contentTypeHeader: Headers.jsonContentType},
          contentType: Headers.jsonContentType,
        ),
      );
      return response.data?['challenge'] as String?;
    };
  }

  /// Builds a base64-encoded DIDComm challenge-response payload that can be
  /// sent to Control Plane endpoints requiring DID-based authentication.
  ///
  /// The helper requests a challenge from [apiClient], resolves the recipient
  /// DID document via [didResolver], constructs a `MeetingplaceAuthChallenge`,
  /// signs and encrypts it with [didManager], and finally returns the encoded
  /// payload together with the sender DID.
  ///
  /// If the challenge endpoint returns an empty challenge and
  /// [onEmptyChallenge] is provided, the callback is used to create the thrown
  /// exception.
  static Future<DidCommChallengeResponse> build({
    required ControlPlaneApiClient apiClient,
    required DidManager didManager,
    required DidResolver didResolver,
    required String recipientDid,
    Exception Function(String senderDid)? onEmptyChallenge,
    Future<String?> Function(String did)? challengeProvider,
  }) async {
    final senderDidDocument = await didManager.getDidDocument();

    String? challenge;
    if (challengeProvider != null) {
      challenge = await challengeProvider(senderDidDocument.id);
    } else {
      final challengeBuilder = DidChallengeBuilder()
        ..did = senderDidDocument.id;
      final challengeResponse = await apiClient.client.didChallenge(
        didChallenge: challengeBuilder.build(),
      );
      challenge = challengeResponse.data?.challenge;
    }
    if (challenge == null || challenge.trim().isEmpty) {
      if (onEmptyChallenge != null) {
        throw onEmptyChallenge(senderDidDocument.id);
      }
      throw StateError('Empty challenge returned from didChallenge');
    }

    final recipientDidDocument = await didResolver.resolveDid(recipientDid);

    final plaintextAuth = MeetingplaceAuthChallenge.create(
      from: senderDidDocument.id,
      to: [recipientDidDocument.id],
      challenge: challenge,
    );

    final encryptedMessageAuth = await _signAndEncryptMessage(
      plaintextAuth,
      senderDidManager: didManager,
      recipientDidDocument: recipientDidDocument,
    );

    return DidCommChallengeResponse(
      senderDid: senderDidDocument.id,
      challengeResponse: base64Encode(
        utf8.encode(jsonEncode(encryptedMessageAuth)),
      ),
    );
  }

  /// Variant of [build] that fetches the challenge from the Matrix challenge
  /// endpoint (`/v1/matrix/challenge`) instead of the DID authenticate
  /// challenge endpoint.
  static Future<DidCommChallengeResponse> buildForMatrix({
    required ControlPlaneApiClient apiClient,
    required DidManager didManager,
    required DidResolver didResolver,
    required String recipientDid,
    Exception Function(String senderDid)? onEmptyChallenge,
  }) {
    return build(
      apiClient: apiClient,
      didManager: didManager,
      didResolver: didResolver,
      recipientDid: recipientDid,
      onEmptyChallenge: onEmptyChallenge,
      challengeProvider: (String did) async {
        final response = await apiClient.client.matrixChallenge(
          matrixChallenge: (MatrixChallengeBuilder()..did = did).build(),
        );
        return response.data?.challenge;
      },
    );
  }

  /// Signs the provided plaintext DIDComm [message] and encrypts it for the
  /// [recipientDidDocument] using the sender's available authentication and key
  /// agreement material from [senderDidManager].
  static Future<EncryptedMessage> _signAndEncryptMessage(
    PlainTextMessage message, {
    required DidManager senderDidManager,
    required DidDocument recipientDidDocument,
  }) async {
    final senderDidDocument = await senderDidManager.getDidDocument();
    final authenticationKeyId = senderDidDocument.authentication.first.id;

    final keyAgreementKeyId = senderDidDocument
        .matchKeysInKeyAgreement(otherDidDocuments: [recipientDidDocument])
        .first;

    final signedMessage = await SignedMessage.pack(
      message,
      signer: await senderDidManager.getSigner(authenticationKeyId),
    );

    return EncryptedMessage.packWithAuthentication(
      signedMessage,
      didKeyId: keyAgreementKeyId,
      keyPair: await senderDidManager.getKeyPairByDidKeyId(keyAgreementKeyId),
      recipientDidDocuments: [recipientDidDocument],
    );
  }
}
