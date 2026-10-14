import 'package:dio/dio.dart';
import 'package:ssi/ssi.dart';

import 'community/community_import.dart';
import 'meeting_place_vtc_sdk_exception.dart';
import 'proof/trust_task_signer.dart';
import 'sign_in/oob_sign_in_client.dart';
import 'sign_in/sign_in_agent.dart';
import 'sign_in/sign_in_failure.dart';
import 'transport/trust_task_http_transport.dart';
import 'trigger_link/trigger_link.dart';
import 'trigger_link/trigger_link_config.dart';
import 'trigger_link/trigger_link_result.dart';
import 'vta/vta_client.dart';
import 'vta/vta_link.dart';

/// Entry point to Verifiable Trust Community (VTC) support.
///
/// Shares one DID resolver and one HTTPS transport across the clients it
/// creates. A typical Key Grant sign-in:
///
/// 1. [readTriggerLink] on the scanned text;
/// 2. [OobSignInClient.claim], then show the community and ask for the
///    number;
/// 3. [prepareSignIn] for the persona, then [OobSignInClient.prove];
/// 4. show the requester, then [OobSignInClient.approve] or
///    [OobSignInClient.cancel].
class MeetingPlaceVtcSDK {
  /// Creates a [MeetingPlaceVtcSDK].
  ///
  /// [didResolver] defaults to a resolver that verifies `did:webvh` logs.
  MeetingPlaceVtcSDK({DidResolver? didResolver, Dio? dio})
    : _didResolver = didResolver ?? UniversalDIDResolver.defaultResolver,
      _transport = TrustTaskHttpTransport(dio: dio);

  final DidResolver _didResolver;
  final TrustTaskHttpTransport _transport;

  /// Reads scanned or pasted [text] as a trigger link, offline.
  TriggerLinkResult readTriggerLink(String text) =>
      TriggerLink.read(text, config: TriggerLinkConfig.meetingPlace);

  /// Mints a manager key for linking a VTA; see [VtaLink].
  Ed25519DidKeySigner newManagerKey() => VtaLink.newManagerKey();

  /// A client for the VTA [vtaDid], acting as [manager].
  VtaClient vtaClient({
    required String vtaDid,
    required Ed25519DidKeySigner manager,
  }) {
    return VtaClient(
      vtaDid: vtaDid,
      manager: manager,
      didResolver: _didResolver,
      transport: _transport,
    );
  }

  /// A sign-in client. [isKnownCommunity] says whether this phone holds a
  /// membership of a community; it is asked before any network call.
  OobSignInClient signInClient({
    required Future<bool> Function(String vtcDid) isKnownCommunity,
  }) {
    return OobSignInClient(
      isKnownCommunity: isKnownCommunity,
      didResolver: _didResolver,
      transport: _transport,
    );
  }

  /// Finds memberships backed up to [vta].
  CommunityImport communityImport(VtaClient vta) => CommunityImport(vta);

  /// Readies [membership]'s persona to sign in to its community: ensures
  /// the persona's sign-in vault entry and enrols the phone's approval key
  /// [userVerificationDid] with the VTA, registering the phone if needed.
  ///
  /// Run it before each approval: enrolling the same key again changes
  /// nothing. Throws [SignInException] when the VTA refuses or cannot be
  /// reached.
  Future<SignInPersona> prepareSignIn({
    required VtaClient vta,
    required CommunityMembership membership,
    required String userVerificationDid,
    required String deviceName,
    required String platform,
  }) async {
    try {
      await vta.enrolUserVerificationKey(
        uvDid: userVerificationDid,
        displayName: deviceName,
        platform: platform,
      );
      final entryId = await vta.ensureSignInVaultEntry(
        vtcDid: membership.communityDid,
        persona: membership.persona,
      );
      return SignInPersona(did: membership.persona.did, entryId: entryId);
    } on MeetingPlaceVtcSDKException catch (error) {
      throw SignInException.fromAgent(error);
    }
  }
}
