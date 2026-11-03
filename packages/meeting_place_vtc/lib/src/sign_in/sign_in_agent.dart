import 'package:collection/collection.dart';

import '../meeting_place_vtc_sdk_exception.dart';

/// The member's VTA, as a sign-in uses it: it signs the `identify` and
/// `grant` documents as the persona, whose key never leaves the VTA.
abstract interface class SignInAgent {
  /// DID of the VTA. The approval decision is addressed to it.
  String get vtaDid;

  /// Has the VTA sign [unsignedEnvelope] as the persona of vault entry
  /// [entryId] (`vault/sign-trust-task/0.2`), with optional extensions such
  /// as the person's approval.
  ///
  /// Throws a `MeetingPlaceVtcSDKException` when the VTA refuses or cannot be
  /// reached.
  Future<Map<String, dynamic>> signTrustTask({
    required String entryId,
    required Map<String, dynamic> unsignedEnvelope,
    Map<String, dynamic>? ext,
  });
}

/// The member's VTA, as membership needs it: besides Trust Task documents,
/// it signs JSON documents that name the persona, such as the credential
/// confirming a membership, with the persona's key.
abstract interface class PersonaSigningAgent implements SignInAgent {
  /// Has the VTA sign [document], which names its signer as `issuer`, with
  /// the key [keyId] for [purpose] (`keys/sign-document/0.1`), and returns
  /// the document with its proof.
  ///
  /// Throws a `MeetingPlaceVtcSDKException` when the VTA refuses, e.g. when
  /// this client may not sign documents, or cannot be reached.
  Future<Map<String, dynamic>> signDocument({
    required String keyId,
    required Map<String, dynamic> document,
    required String purpose,
  });
}

/// The persona a member signs in as, and the VTA vault entry that lets the
/// VTA sign as it.
class SignInPersona {
  /// Creates a [SignInPersona].
  const SignInPersona({required this.did, required this.entryId});

  /// The persona's DID, the member's identity in the community.
  final String did;

  /// Id of the persona's `did-self-issued` vault entry.
  final String entryId;
}

/// Has [agent] sign [unsigned] as [persona] and checks that it signed
/// exactly that document. The caller verifies the proof.
///
/// Throws [MeetingPlaceVtcSDKException]: as [SignInAgent.signTrustTask]
/// does, and `invalidDocument` when the agent changed the document.
Future<Map<String, dynamic>> signAsPersona(
  SignInAgent agent,
  SignInPersona persona,
  Map<String, dynamic> unsigned, {
  Map<String, dynamic>? ext,
}) async {
  final signed = await agent.signTrustTask(
    entryId: persona.entryId,
    unsignedEnvelope: unsigned,
    ext: ext,
  );

  final signedWithoutProof = Map<String, dynamic>.of(signed)..remove('proof');
  if (!const DeepCollectionEquality().equals(signedWithoutProof, unsigned)) {
    throw MeetingPlaceVtcSDKException.invalidDocument(
      'the agent changed the document it signed',
    );
  }
  return signed;
}
