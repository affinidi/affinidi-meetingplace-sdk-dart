import 'package:ssi/ssi.dart';

import '../meeting_place_vtc_sdk_exception.dart';
import '../sign_in/sign_in_agent.dart';
import '../transport/trust_task_http_transport.dart';
import '../vtc/community_exchange.dart';
import '../vtc/vtc_resolver.dart';
import 'vtc_group.dart';

/// Trust Task types of a community's groups.
abstract final class GroupTask {
  static const _base = 'https://trusttasks.org/spec/vtc/groups';

  /// Lists the groups the caller may see.
  static const list = '$_base/list/0.2';

  /// Shows one group.
  static const show = '$_base/show/0.1';

  /// Lists a group's members.
  static const membersList = '$_base/members/list/0.2';
}

/// Reads a community's groups as a member's persona, each request signed by
/// the member's VTA.
///
/// The community decides what the persona may see: groups by their
/// visibility, members by the group's `showMembers`, managers and member
/// credentials to the group's managers only. Never logs a group, a member
/// or a DID.
class VtcGroupsClient {
  /// Creates a [VtcGroupsClient].
  VtcGroupsClient({DidResolver? didResolver, TrustTaskHttpTransport? transport})
    : _transport = transport ?? TrustTaskHttpTransport(),
      _vtcResolver = VtcResolver(didResolver: didResolver);

  /// Most pages read for one list, so a community answering a cursor
  /// forever cannot keep the phone asking.
  static const maxPages = 50;

  final TrustTaskHttpTransport _transport;
  final VtcResolver _vtcResolver;

  /// The groups of the community [communityDid] that [persona] may see;
  /// only those [persona] belongs to when [mine].
  ///
  /// Throws [MeetingPlaceVtcSDKException] when the VTA or the community
  /// refuses or cannot be reached, or the answer cannot be read.
  Future<List<VtcGroupListing>> list(
    String communityDid, {
    required SignInAgent agent,
    required SignInPersona persona,
    bool mine = false,
  }) async {
    final items = await _pages(
      communityDid,
      agent: agent,
      persona: persona,
      type: GroupTask.list,
      payload: {if (mine) 'mine': true},
    );
    return [for (final item in items) _listing(item)];
  }

  /// The group [groupId] of the community [communityDid], as [persona] may
  /// see it.
  ///
  /// Throws [MeetingPlaceVtcSDKException] as [list] does; refused with a code
  /// ending in `:notFound` when [persona] may not see the group.
  Future<VtcGroupListing> show(
    String communityDid, {
    required String groupId,
    required SignInAgent agent,
    required SignInPersona persona,
  }) async {
    final community = await _vtcResolver.resolveCommunity(communityDid);
    final request = await signedByPersona(
      agent,
      persona,
      community,
      type: GroupTask.show,
      payload: {'groupId': groupId},
    );
    final answer = await exchangeWithCommunity(_transport, community, request);
    return _listing(answer.payload);
  }

  /// The members of the group [groupId] that [persona] may see: active
  /// members, and pending ones to the group's managers.
  ///
  /// Throws [MeetingPlaceVtcSDKException] as [list] does; refused when the
  /// group does not show its members to [persona].
  Future<List<VtcGroupMember>> members(
    String communityDid, {
    required String groupId,
    required SignInAgent agent,
    required SignInPersona persona,
  }) async {
    final items = await _pages(
      communityDid,
      agent: agent,
      persona: persona,
      type: GroupTask.membersList,
      payload: {'groupId': groupId},
    );
    return [for (final item in items) _member(item)];
  }

  /// Every item of a paged answer to [type], following `nextCursor`.
  Future<List<Map<String, dynamic>>> _pages(
    String communityDid, {
    required SignInAgent agent,
    required SignInPersona persona,
    required String type,
    required Map<String, dynamic> payload,
  }) async {
    final community = await _vtcResolver.resolveCommunity(communityDid);
    final items = <Map<String, dynamic>>[];
    String? cursor;
    for (var page = 0; page < maxPages; page++) {
      final request = await signedByPersona(
        agent,
        persona,
        community,
        type: type,
        payload: {...payload, 'cursor': ?cursor},
      );
      final answer = (await exchangeWithCommunity(
        _transport,
        community,
        request,
      )).payload;
      final pageItems = answer['items'];
      if (pageItems is! List) {
        throw MeetingPlaceVtcSDKException.invalidDocument('no items');
      }
      items.addAll(pageItems.whereType<Map<String, dynamic>>());
      cursor = answer['nextCursor'] is String
          ? answer['nextCursor'] as String
          : null;
      if (cursor == null) return items;
    }
    throw MeetingPlaceVtcSDKException.invalidDocument('too many pages');
  }

  static VtcGroupListing _listing(Map<String, dynamic> item) {
    final group = item['group'];
    if (group is! Map<String, dynamic>) {
      throw MeetingPlaceVtcSDKException.invalidDocument('no group');
    }
    return VtcGroupListing(
      group: _group(group),
      standing: GroupStanding.parse(item['myMembership']),
    );
  }

  static VtcGroup _group(Map<String, dynamic> group) {
    final groupId = group['groupId'];
    final groupDid = group['groupDid'];
    final name = group['name'];
    final visibility = GroupAudience.parse(group['visibility']);
    final showMembers = GroupAudience.parse(group['showMembers']);
    final managers = group['managers'];
    if (groupId is! String ||
        groupDid is! String ||
        name is! String ||
        visibility == null ||
        showMembers == null) {
      throw MeetingPlaceVtcSDKException.invalidDocument('malformed group');
    }
    return VtcGroup(
      groupId: groupId,
      groupDid: groupDid,
      name: name,
      description: group['description'] is String
          ? group['description'] as String
          : null,
      isDynamic: group['kind'] == 'dynamic',
      visibility: visibility,
      showMembers: showMembers,
      managers: managers is List
          ? List.unmodifiable(managers.whereType<String>())
          : null,
    );
  }

  static VtcGroupMember _member(Map<String, dynamic> item) {
    final entryId = item['entryId'];
    final state = item['state'];
    if (entryId is! String || state is! String) {
      throw MeetingPlaceVtcSDKException.invalidDocument('malformed member');
    }
    return VtcGroupMember(
      entryId: entryId,
      state: state,
      credentialId: item['credentialId'] is String
          ? item['credentialId'] as String
          : null,
    );
  }
}
