import 'dart:convert';

import 'package:didcomm/didcomm.dart';
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
  }) async {
    final senderDidDocument = await didManager.getDidDocument();
    final challengeResponse = await apiClient.client.didChallenge(
      didChallenge: (DidChallengeBuilder()..did = senderDidDocument.id).build(),
    );
    return _buildFromChallenge(
      senderDidDocument: senderDidDocument,
      challenge: challengeResponse.data?.challenge,
      didManager: didManager,
      didResolver: didResolver,
      recipientDid: recipientDid,
      onEmptyChallenge: onEmptyChallenge,
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
  }) async {
    final senderDidDocument = await didManager.getDidDocument();
    final challengeResponse = await apiClient.client.matrixChallenge(
      matrixChallenge: (MatrixChallengeBuilder()..did = senderDidDocument.id)
          .build(),
    );
    return _buildFromChallenge(
      senderDidDocument: senderDidDocument,
      challenge: challengeResponse.data?.challenge,
      didManager: didManager,
      didResolver: didResolver,
      recipientDid: recipientDid,
      onEmptyChallenge: onEmptyChallenge,
    );
  }

  static Future<DidCommChallengeResponse> _buildFromChallenge({
    required DidDocument senderDidDocument,
    required String? challenge,
    required DidManager didManager,
    required DidResolver didResolver,
    required String recipientDid,
    required Exception Function(String senderDid)? onEmptyChallenge,
  }) async {
    if (challenge == null || challenge.trim().isEmpty) {
      if (onEmptyChallenge != null) {
        throw onEmptyChallenge(senderDidDocument.id);
      }
      throw StateError('Empty challenge returned from challenge endpoint');
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
