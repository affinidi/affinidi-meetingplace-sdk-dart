import 'package:dio/dio.dart';
import 'package:ssi/ssi.dart';

import 'community/community_import.dart';
import 'join/vtc_join_client.dart';
import 'meeting_place_vtc_sdk_exception.dart';
import 'persona/persona_did_manager.dart';
import 'persona/persona_inbox.dart';
import 'proof/trust_task_signer.dart';
import 'sign_in/oob_sign_in_client.dart';
import 'sign_in/sign_in_agent.dart';
import 'sign_in/sign_in_failure.dart';
import 'status/status_list_client.dart';
import 'transport/didcomm_vta_transport.dart';
import 'transport/trust_task_http_transport.dart';
import 'trigger_link/trigger_link.dart';
import 'trigger_link/trigger_link_config.dart';
import 'trigger_link/trigger_link_result.dart';
import 'vta/vta_client.dart';
import 'vta/vta_link.dart';
import 'vta/vta_models.dart';

/// Entry point to Verifiable Trust Community (VTC) support.
///
/// Shares one DID resolver and one HTTPS transport across the clients it
/// creates; VTA clients talk to the VTA over DIDComm, through its
/// mediator. A typical Key Grant sign-in:
///
/// 1. [readTriggerLink] on the scanned text;
/// 2. [OobSignInClient.claim], then show the community and ask for the
///    number;
/// 3. [prepareSignIn] for the persona, then [OobSignInClient.prove];
/// 4. show the requester, then [OobSignInClient.approve] or
///    [OobSignInClient.cancel].
///
/// Joining a community: [VtcJoinClient.readManifest] on the scanned
/// community DID, [VtaClient.createPersona] and [personaSigner], then
/// [VtcJoinClient.apply].
class MeetingPlaceVtcSDK {
  /// Creates a [MeetingPlaceVtcSDK].
  ///
  /// [didResolver] defaults to a resolver that verifies `did:webvh` logs.
  /// [openVtaMailbox] opens a manager key's inbox on the VTA's mediator, and
  /// [openMediatorInbox] a persona's inbox on its mediator; by default,
  /// through the mediator's own API.
  MeetingPlaceVtcSDK({
    DidResolver? didResolver,
    Dio? dio,
    VtaMailboxOpener? openVtaMailbox,
    MediatorInboxOpener? openMediatorInbox,
  }) : _didResolver = didResolver ?? UniversalDIDResolver.defaultResolver,
       _dio = dio,
       _transport = TrustTaskHttpTransport(dio: dio),
       _openVtaMailbox = openVtaMailbox,
       _openMediatorInbox = openMediatorInbox;

  final DidResolver _didResolver;
  final Dio? _dio;
  final TrustTaskHttpTransport _transport;
  final VtaMailboxOpener? _openVtaMailbox;
  final MediatorInboxOpener? _openMediatorInbox;

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
      transport: DidcommVtaTransport(
        vtaDid: vtaDid,
        manager: manager,
        didResolver: _didResolver,
        openMailbox: _openVtaMailbox,
      ),
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

  /// The inbox of [persona], whose keys its VTA lent
  /// ([VtaClient.borrowPersonaKeys]), on the persona's mediator.
  PersonaInbox personaInbox(PersonaDidManager persona) => PersonaInbox(
    persona: persona,
    didResolver: _didResolver,
    openInbox: _openMediatorInbox,
  );

  /// A client that reads whether a credential's issuer revoked it.
  StatusListClient statusListClient() =>
      StatusListClient(didResolver: _didResolver, dio: _dio);

  /// A client to join communities.
  VtcJoinClient joinClient() =>
      VtcJoinClient(didResolver: _didResolver, transport: _transport);

  /// Readies [vta] to sign as [persona] in the community [communityDid]:
  /// ensures the persona's vault entry for that community.
  Future<SignInPersona> personaSigner({
    required VtaClient vta,
    required String communityDid,
    required VtaPersona persona,
  }) async {
    final entryId = await vta.ensureSignInVaultEntry(
      vtcDid: communityDid,
      persona: persona,
    );
    return SignInPersona(did: persona.did, entryId: entryId);
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
      return await personaSigner(
        vta: vta,
        communityDid: membership.communityDid,
        persona: membership.persona,
      );
    } on MeetingPlaceVtcSDKException catch (error) {
      throw SignInException.fromAgent(error);
    }
  }
}
