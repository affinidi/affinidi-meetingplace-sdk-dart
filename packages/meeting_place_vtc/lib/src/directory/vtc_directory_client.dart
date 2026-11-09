import 'package:ssi/ssi.dart';

import '../join/vtc_join_client.dart';
import '../meeting_place_vtc_sdk_exception.dart';
import '../sign_in/sign_in_agent.dart';
import '../transport/trust_task_http_transport.dart';
import '../vtc/community_exchange.dart';
import '../vtc/vtc_resolver.dart';
import 'directory_entry.dart';

/// Trust Task types of a community's member directory, and the refusals
/// callers act on.
abstract final class DirectoryTask {
  static const _base = 'https://trusttasks.org/spec/vtc/directory';

  /// Searches the directory.
  static const entriesList = '$_base/entries/list/0.2';

  /// Shows one entry.
  static const entriesShow = '$_base/entries/show/0.1';

  /// Shows the caller's own card, whole.
  static const cardShow = '$_base/card/show/0.1';

  /// Changes the caller's own card.
  static const cardUpdate = MemberTask.directoryCardUpdate;

  /// A search shorter than the community allows.
  static const queryTooShort = 'vtc/directory/entries/list:queryTooShort';

  /// No entry the caller may see.
  static const entryNotFound = 'vtc/directory/entries/show:notFound';

  /// The community does not let members show a field that widely.
  static const aboveCeiling = 'vtc/directory/card/update:aboveCeiling';
}

/// Finds other members in a community's directory, and lets the member be
/// found, each request signed as the member's persona by their VTA.
///
/// The community projects every entry for the caller: a member's DID is
/// shown only when that member chose to show it. Never logs a DID or a
/// name.
class VtcDirectoryClient {
  /// Creates a [VtcDirectoryClient].
  VtcDirectoryClient({
    DidResolver? didResolver,
    TrustTaskHttpTransport? transport,
  }) : _transport = transport ?? TrustTaskHttpTransport(),
       _vtcResolver = VtcResolver(didResolver: didResolver);

  /// The field a member's DID is shown in.
  static const didField = 'did';

  /// The audiences that let every member see a field.
  static const _membersOrWider = {'members', 'public'};

  final TrustTaskHttpTransport _transport;
  final VtcResolver _vtcResolver;

  /// The first [limit] entries of the community [communityDid] that match
  /// [query], as [persona] may see them. One page only: a caller narrows
  /// the search instead of paging.
  ///
  /// Throws [MeetingPlaceVtcSDKException] when the VTA or the community
  /// refuses, such as with [DirectoryTask.queryTooShort], or cannot be
  /// reached, or the answer cannot be read.
  Future<List<DirectoryEntry>> search(
    String communityDid, {
    required SignInAgent agent,
    required SignInPersona persona,
    required String query,
    int limit = 25,
  }) async {
    final payload = await _ask(
      communityDid,
      agent: agent,
      persona: persona,
      type: DirectoryTask.entriesList,
      payload: {'query': query, 'limit': limit},
    );
    final items = payload['items'];
    if (items is! List) {
      throw MeetingPlaceVtcSDKException.invalidDocument('no items');
    }
    return [for (final item in items) ?DirectoryEntry.read(item)];
  }

  /// The entry [entryId] of the community [communityDid], as [persona] may
  /// see it, or null when there is none [persona] may see.
  ///
  /// Throws [MeetingPlaceVtcSDKException] as [search] does.
  Future<DirectoryEntry?> show(
    String communityDid, {
    required SignInAgent agent,
    required SignInPersona persona,
    required String entryId,
  }) async {
    final Map<String, dynamic> payload;
    try {
      payload = await _ask(
        communityDid,
        agent: agent,
        persona: persona,
        type: DirectoryTask.entriesShow,
        payload: {'entryId': entryId},
      );
    } on MeetingPlaceVtcSDKException catch (error) {
      if (error.refusalCode == DirectoryTask.entryNotFound) return null;
      rethrow;
    }
    final entry = DirectoryEntry.read(payload['entry']);
    if (entry == null || entry.entryId != entryId) {
      throw MeetingPlaceVtcSDKException.invalidDocument('not this entry');
    }
    return entry;
  }

  /// [persona]'s own card in the community [communityDid].
  ///
  /// Throws [MeetingPlaceVtcSDKException] as [search] does.
  Future<MyDirectoryCard> myCard(
    String communityDid, {
    required SignInAgent agent,
    required SignInPersona persona,
  }) async {
    final payload = await _ask(
      communityDid,
      agent: agent,
      persona: persona,
      type: DirectoryTask.cardShow,
      payload: const {},
    );
    final card = payload['card'];
    final entryId = card is Map<String, dynamic> ? card['entryId'] : null;
    if (card is! Map<String, dynamic> || entryId is! String) {
      throw MeetingPlaceVtcSDKException.invalidDocument('malformed card');
    }
    final visibility = card['visibility'];
    return MyDirectoryCard(
      entryId: entryId,
      isDidVisibleToMembers:
          visibility is Map && _membersOrWider.contains(visibility[didField]),
    );
  }

  /// Shows [persona]'s DID in the community [communityDid] to every member
  /// when [visible], so they can find [persona] to vouch for them, and
  /// returns it to the community's default, administrators only,
  /// otherwise.
  ///
  /// Throws [MeetingPlaceVtcSDKException] as [search] does, such as with
  /// [DirectoryTask.aboveCeiling] when the community does not let members
  /// show their DID.
  Future<void> setDidVisibleToMembers(
    String communityDid, {
    required SignInAgent agent,
    required SignInPersona persona,
    required bool visible,
  }) => _ask(
    communityDid,
    agent: agent,
    persona: persona,
    type: DirectoryTask.cardUpdate,
    payload: {
      'visibility': {didField: visible ? 'members' : null},
    },
  );

  Future<Map<String, dynamic>> _ask(
    String communityDid, {
    required SignInAgent agent,
    required SignInPersona persona,
    required String type,
    required Map<String, dynamic> payload,
  }) async {
    final community = await _vtcResolver.resolveCommunity(communityDid);
    final request = await signedByPersona(
      agent,
      persona,
      community,
      type: type,
      payload: payload,
    );
    return (await exchangeWithCommunity(
      _transport,
      community,
      request,
    )).payload;
  }
}
