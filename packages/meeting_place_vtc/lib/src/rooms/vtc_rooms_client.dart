import 'dart:convert';

import 'package:collection/collection.dart';
import 'package:ssi/ssi.dart';

import '../meeting_place_vtc_sdk_exception.dart';
import '../proof/eddsa_jcs_2022.dart';
import '../transport/trust_task_http_transport.dart';
import '../trust_task/trust_task_document.dart';
import '../vta/vta_models.dart';
import '../vtc/community_exchange.dart';
import '../vtc/vtc_resolver.dart';
import 'room_key_holder.dart';
import 'room_models.dart';

/// A community's data rooms, as one of its members uses them.
///
/// The member's VTA does every part that needs the member's keys: it signs
/// the member's requests to the community (`rooms/keys/act`), holds their
/// place in each room's group, and reads and opens records from the room's
/// host. This client holds no room key, and checks each record's author
/// signature itself, since the VTA opens a record without checking it.
///
/// Never logs a room, a record or a DID.
class VtcRoomsClient {
  /// Creates a [VtcRoomsClient].
  VtcRoomsClient({DidResolver? didResolver, TrustTaskHttpTransport? transport})
    : _transport = transport ?? TrustTaskHttpTransport(),
      _didResolver = didResolver ?? UniversalDIDResolver.defaultResolver,
      _vtcResolver = VtcResolver(didResolver: didResolver);

  /// Most pages read for one list, so a community answering a cursor
  /// forever cannot keep the phone asking.
  static const maxPages = 50;

  /// Extension namespace the member's VTA reports room details under.
  static const memberExt = 'org.openvtc.rooms';

  /// The members a signed record body may carry, and nothing else.
  static const _bodyMembers = {
    'roomId',
    'key',
    'version',
    'author',
    'title',
    'description',
    'body',
    'tags',
    'basis',
    'confidence',
    'evidence',
    'validFor',
    'validUntil',
    'file',
    'proof',
  };

  final TrustTaskHttpTransport _transport;
  final DidResolver _didResolver;
  final VtcResolver _vtcResolver;

  /// The community [communityDid]'s offers of a place in its rooms to
  /// [memberDid], and the renewals of the rooms they are in.
  ///
  /// Throws [MeetingPlaceVtcSDKException] when the VTA or the community
  /// refuses or cannot be reached, or the answer cannot be read.
  Future<RoomOffers> offers(
    String communityDid, {
    required RoomKeyHolder holder,
    required String memberDid,
  }) async {
    final community = await _vtcResolver.resolveCommunity(communityDid);
    final offers = <RoomOffer>[];
    final renewals = <RoomRenewal>[];
    String? cursor;
    for (var page = 0; page < maxPages; page++) {
      final answer = await _asMember(
        community,
        holder: holder,
        memberDid: memberDid,
        type: RoomTask.offersList,
        payload: {'cursor': ?cursor},
      );
      offers.addAll(_items(answer).map(_offer));
      // Listed in full on the first page only.
      if (cursor == null) {
        renewals.addAll(_maps(answer['renewals']).map(_renewal));
      }
      cursor = RoomJson.optionalString(answer['nextCursor']);
      if (cursor == null) {
        return RoomOffers(
          offers: List.unmodifiable(offers),
          renewals: List.unmodifiable(renewals),
        );
      }
    }
    throw MeetingPlaceVtcSDKException.invalidDocument('too many pages');
  }

  /// The community [communityDid]'s record of [memberDid]'s admissions to
  /// its rooms, in every state.
  ///
  /// Throws [MeetingPlaceVtcSDKException] as [offers] does.
  Future<List<RoomMembership>> memberships(
    String communityDid, {
    required RoomKeyHolder holder,
    required String memberDid,
  }) async {
    final community = await _vtcResolver.resolveCommunity(communityDid);
    final memberships = <RoomMembership>[];
    String? cursor;
    for (var page = 0; page < maxPages; page++) {
      final answer = await _asMember(
        community,
        holder: holder,
        memberDid: memberDid,
        type: RoomTask.membershipsList,
        payload: {'cursor': ?cursor},
      );
      memberships.addAll(_items(answer).map(_membership));
      cursor = RoomJson.optionalString(answer['nextCursor']);
      if (cursor == null) return List.unmodifiable(memberships);
    }
    throw MeetingPlaceVtcSDKException.invalidDocument('too many pages');
  }

  /// Accepts [offer] from the community [communityDid] as [member]: keeps
  /// the room's credentials in the member's VTA and, on a sealed room, has
  /// the VTA mint the KeyPackage the community admits and join the room's
  /// group from the Welcome.
  ///
  /// Safe to repeat: a KeyPackage the VTA already minted for the offer is
  /// sent again, which the community answers with the same Welcome, and a
  /// group the VTA already joined is reported as
  /// [RoomAcceptance.alreadyJoined].
  ///
  /// Throws [MeetingPlaceVtcSDKException] when the VTA or the community
  /// refuses, e.g. refused with a code ending in `:offerExpired`.
  Future<RoomAcceptance> accept(
    String communityDid, {
    required RoomKeyHolder holder,
    required VtaPersona member,
    required RoomOffer offer,
  }) async {
    final community = await _vtcResolver.resolveCommunity(communityDid);
    for (final credential in [offer.membership, offer.authority]) {
      await holder.keepCredential(credential, contextId: member.contextId);
    }

    final sealed = offer.visibility.isSealed;
    if (sealed && await _holdsGroup(holder, offer.roomId, member.did)) {
      return RoomAcceptance(roomId: offer.roomId, alreadyJoined: true);
    }

    final keyPackage = sealed
        ? (await holder.roomKeyPackage(
            roomId: offer.roomId,
            invitation: offer.invitation,
          )).keyPackage
        : null;
    final answer = await _asMember(
      community,
      holder: holder,
      memberDid: member.did,
      type: RoomTask.offersAccept,
      payload: {'roomId': offer.roomId, 'keyPackage': ?keyPackage},
    );
    final epoch = answer['epoch'] is int ? answer['epoch'] as int : null;
    final welcome = RoomJson.optionalString(answer['welcome']);
    if (welcome == null) {
      if (sealed) {
        throw MeetingPlaceVtcSDKException.invalidDocument(
          'admitted to a sealed room without a Welcome',
        );
      }
      return RoomAcceptance(
        roomId: offer.roomId,
        epoch: epoch,
        alreadyJoined: false,
      );
    }

    try {
      await holder.joinRoomGroup(
        roomId: offer.roomId,
        invitation: offer.invitation,
        welcome: welcome,
        ratchetTree: RoomJson.optionalString(answer['ratchetTree']),
      );
    } on MeetingPlaceVtcSDKException catch (error) {
      // Another surface handed the VTA the same Welcome first.
      if (!_isRefusal(error, 'alreadyJoined')) rethrow;
      return RoomAcceptance(
        roomId: offer.roomId,
        epoch: epoch,
        alreadyJoined: true,
      );
    }
    return RoomAcceptance(
      roomId: offer.roomId,
      epoch: epoch,
      alreadyJoined: false,
    );
  }

  /// Keeps [renewal]'s credentials in the member's VTA in place of the ones
  /// they renew. Keeping one already kept is success, so any surface may
  /// collect it first.
  ///
  /// Throws [MeetingPlaceVtcSDKException] when the VTA refuses, or holds
  /// more than one credential the renewal could replace.
  Future<void> collectRenewal(
    RoomRenewal renewal, {
    required RoomKeyHolder holder,
    required VtaPersona member,
  }) async {
    for (final (type, credential) in [
      ('MembershipCredential', renewal.membership),
      ('AuthorityCredential', renewal.authority),
    ]) {
      final held = await holder.findCredentials(
        type: type,
        issuerDid: renewal.roomId,
        subjectDid: member.did,
      );
      if (held.length > 1) {
        throw MeetingPlaceVtcSDKException.invalidDocument(
          'more than one $type from the room',
        );
      }
      await holder.keepCredential(
        credential,
        contextId: member.contextId,
        replacing: held.firstOrNull?.id,
      );
    }
  }

  /// The records of [roomId], which the member's VTA lists from the room's
  /// [host]. Never their content: [record] reads one.
  ///
  /// Throws [MeetingPlaceVtcSDKException] when the VTA refuses, e.g. when it
  /// holds no place in the room for the member, or the host cannot be
  /// reached.
  Future<RoomRecords> records({
    required RoomKeyHolder holder,
    required String roomId,
    required String host,
  }) async {
    final answer = await holder.browseRoom(roomId: roomId, host: host);
    final records = answer['records'];
    if (records is! List) {
      throw MeetingPlaceVtcSDKException.invalidDocument('no records');
    }
    return RoomRecords(
      roomId: roomId,
      records: List.unmodifiable(
        records.whereType<Map<String, dynamic>>().map(_recordSummary),
      ),
      complete: answer['complete'] != false,
    );
  }

  /// The record [key] of [roomId], which the member's VTA reads from the
  /// room's [host] and opens, checked against its author's signature.
  ///
  /// Returns null for the room's own profile, which is not a member's
  /// record.
  ///
  /// Throws [MeetingPlaceVtcSDKException] when the VTA refuses, e.g. refused
  /// with `cannotOpen` when the member's VTA cannot open it yet, and with
  /// `invalidProof` or `invalidDocument` when its body does not hold.
  Future<RoomRecord?> record({
    required RoomKeyHolder holder,
    required String roomId,
    required String host,
    required String key,
  }) async {
    final answer = await holder.readRoomRecord(
      roomId: roomId,
      host: host,
      key: key,
    );
    final ext = answer['ext'];
    final details = ext is Map<String, dynamic> ? ext[memberExt] : null;
    if (details is Map<String, dynamic> && details['roomProfile'] == true) {
      return null;
    }

    final version = answer['version'];
    final status = RoomRecordStatus.parse(answer['status']);
    if (answer['roomId'] != roomId ||
        answer['key'] != key ||
        version is! int ||
        status == null) {
      throw MeetingPlaceVtcSDKException.invalidDocument('malformed record');
    }
    final hostAuthor = RoomJson.optionalString(answer['author']);
    final updatedAt = RoomJson.optionalInstant(answer['updatedAt']);

    if (answer['plaintext'] case final String plaintext) {
      final sealedAt = details is Map<String, dynamic>
          ? details['sealedAt']
          : null;
      if (sealedAt != null && (sealedAt is! int || sealedAt > version)) {
        throw MeetingPlaceVtcSDKException.invalidDocument(
          'opened past the record',
        );
      }
      final body = await _verifiedBody(
        plaintext,
        roomId: roomId,
        key: key,
        version: sealedAt is int ? sealedAt : version,
        hostAuthor: hostAuthor,
      );
      return RoomRecord(
        roomId: roomId,
        key: key,
        version: version,
        status: status,
        updatedAt: updatedAt,
        author: body['author'] as String,
        title: RoomJson.optionalString(body['title']),
        description: RoomJson.optionalString(body['description']),
        body: RoomJson.optionalString(body['body']),
        tags: _strings(body['tags']),
        file: RoomFile.tryParse(body['file']),
        validUntil: RoomJson.optionalInstant(body['validUntil']),
      );
    }

    // An open room's record, carried as itself, or a retracted record with
    // no content.
    final cleartext = answer['cleartext'];
    if (cleartext is! Map<String, dynamic> &&
        status != RoomRecordStatus.retracted) {
      throw MeetingPlaceVtcSDKException.invalidDocument('no record content');
    }
    final content = cleartext is Map<String, dynamic>
        ? cleartext
        : const <String, dynamic>{};
    return RoomRecord(
      roomId: roomId,
      key: key,
      version: version,
      status: status,
      updatedAt: updatedAt,
      author: hostAuthor,
      title: RoomJson.optionalString(content['title']),
      description: RoomJson.optionalString(content['description']),
      body: RoomJson.optionalString(content['body']),
      tags: _strings(content['tags']),
      file: RoomFile.tryParse(content['file']),
      validUntil: RoomJson.optionalInstant(content['validUntil']),
    );
  }

  /// Has [holder] complete a [type] request to [community] as [memberDid]
  /// and sends it, returning the community's answer.
  Future<Map<String, dynamic>> _asMember(
    VtcCommunityEndpoint community, {
    required RoomKeyHolder holder,
    required String memberDid,
    required String type,
    required Map<String, dynamic> payload,
  }) async {
    final unsigned = TrustTaskDocument.create(
      type: type,
      issuer: memberDid,
      recipient: community.did,
      payload: payload,
    ).toJson();
    final completed = await holder.actAsMember(unsigned);
    // The community's types take no presentation: the VTA adds its proof
    // and changes nothing else.
    final withoutProof = Map<String, dynamic>.of(completed)..remove('proof');
    if (!const DeepCollectionEquality().equals(withoutProof, unsigned)) {
      throw MeetingPlaceVtcSDKException.invalidDocument(
        'the VTA changed the document it completed',
      );
    }
    final answer = await exchangeWithCommunity(
      _transport,
      community,
      TrustTaskDocument.fromJson(completed),
    );
    return answer.payload;
  }

  /// The signed body in [plaintext], once its signature, location and
  /// author all hold.
  Future<Map<String, dynamic>> _verifiedBody(
    String plaintext, {
    required String roomId,
    required String key,
    required int version,
    required String? hostAuthor,
  }) async {
    final Object? signed;
    try {
      signed = jsonDecode(
        utf8.decode(base64Url.decode(base64Url.normalize(plaintext))),
      );
    } on FormatException {
      throw MeetingPlaceVtcSDKException.invalidDocument('record body not JSON');
    }
    if (signed is! Map<String, dynamic>) {
      throw MeetingPlaceVtcSDKException.invalidDocument('record body not JSON');
    }
    final author = signed['author'];
    if (author is! String || !author.startsWith('did:')) {
      throw MeetingPlaceVtcSDKException.invalidDocument('record body author');
    }
    if (signed.keys.any((member) => !_bodyMembers.contains(member))) {
      throw MeetingPlaceVtcSDKException.invalidDocument(
        'unknown record body member',
      );
    }
    await EddsaJcs2022.verify(
      signed,
      purpose: ProofPurpose.assertionMethod,
      resolver: _didResolver,
      expectedSigner: author,
    );
    // Signed for where it was read, so a body moved to another record or
    // version is refused.
    if (signed['roomId'] != roomId ||
        signed['key'] != key ||
        signed['version'] != version) {
      throw MeetingPlaceVtcSDKException.invalidDocument(
        'record body signed for another place',
      );
    }
    if (hostAuthor != null && hostAuthor != author) {
      throw MeetingPlaceVtcSDKException.invalidDocument(
        'record body signed by another member than its author',
      );
    }
    return signed;
  }

  static Future<bool> _holdsGroup(
    RoomKeyHolder holder,
    String roomId,
    String memberDid,
  ) async => (await holder.heldRooms()).any(
    (room) => room.roomId == roomId && room.member == memberDid,
  );

  static bool _isRefusal(MeetingPlaceVtcSDKException error, String code) {
    final refusal = error.refusalCode;
    return refusal == code || (refusal?.endsWith(':$code') ?? false);
  }

  static Iterable<Map<String, dynamic>> _items(Map<String, dynamic> answer) {
    final items = answer['items'];
    if (items is! List) {
      throw MeetingPlaceVtcSDKException.invalidDocument('no items');
    }
    return items.whereType<Map<String, dynamic>>();
  }

  static Iterable<Map<String, dynamic>> _maps(Object? list) => switch (list) {
    final List<dynamic> entries => entries.whereType<Map<String, dynamic>>(),
    _ => const [],
  };

  static List<String> _strings(Object? list) => switch (list) {
    final List<dynamic> values => List.unmodifiable(values.whereType<String>()),
    _ => const [],
  };

  static RoomOffer _offer(Map<String, dynamic> item) {
    final credentials = item['credentials'];
    if (credentials is! Map<String, dynamic>) {
      throw MeetingPlaceVtcSDKException.invalidDocument('offer credentials');
    }
    return RoomOffer(
      roomId: RoomJson.string(item['roomId'], 'roomId'),
      host: RoomJson.string(item['host'], 'host'),
      label: RoomJson.string(item['label'], 'label'),
      description: RoomJson.optionalString(item['description']),
      visibility: RoomJson.visibility(item['visibility']),
      actions: RoomJson.actions(item['actions']),
      validUntil: RoomJson.instant(item['validUntil'], 'validUntil'),
      offeredAt: RoomJson.instant(item['offeredAt'], 'offeredAt'),
      isOpen: item['state'] == 'open',
      invitation: RoomJson.string(credentials['invitation'], 'invitation'),
      membership: RoomJson.credential(credentials['membership'], 'membership'),
      authority: RoomJson.credential(credentials['authority'], 'authority'),
    );
  }

  static RoomRenewal _renewal(Map<String, dynamic> item) {
    final credentials = item['credentials'];
    if (credentials is! Map<String, dynamic>) {
      throw MeetingPlaceVtcSDKException.invalidDocument('renewal credentials');
    }
    return RoomRenewal(
      roomId: RoomJson.string(item['roomId'], 'roomId'),
      host: RoomJson.string(item['host'], 'host'),
      label: RoomJson.string(item['label'], 'label'),
      description: RoomJson.optionalString(item['description']),
      visibility: RoomJson.visibility(item['visibility']),
      actions: RoomJson.actions(item['actions']),
      validUntil: RoomJson.instant(item['validUntil'], 'validUntil'),
      renewsAt: RoomJson.instant(item['renewsAt'], 'renewsAt'),
      membership: RoomJson.credential(credentials['membership'], 'membership'),
      authority: RoomJson.credential(credentials['authority'], 'authority'),
    );
  }

  static RoomMembership _membership(Map<String, dynamic> item) {
    final state = RoomMemberState.parse(item['state']);
    final roomState = RoomState.parse(item['roomState']);
    if (state == null || roomState == null) {
      throw MeetingPlaceVtcSDKException.invalidDocument('membership state');
    }
    return RoomMembership(
      roomId: RoomJson.string(item['roomId'], 'roomId'),
      host: RoomJson.string(item['host'], 'host'),
      label: RoomJson.string(item['label'], 'label'),
      description: RoomJson.optionalString(item['description']),
      visibility: RoomJson.visibility(item['visibility']),
      actions: RoomJson.actions(item['actions']),
      validUntil: RoomJson.instant(item['validUntil'], 'validUntil'),
      state: state,
      roomState: roomState,
      offeredAt: RoomJson.instant(item['offeredAt'], 'offeredAt'),
      admittedAt: RoomJson.optionalInstant(item['admittedAt']),
      readOnly: item['roomAccess'] == 'readOnly',
    );
  }

  static RoomRecordSummary _recordSummary(Map<String, dynamic> item) {
    final version = item['version'];
    final status = RoomRecordStatus.parse(item['status']);
    if (version is! int || status == null) {
      throw MeetingPlaceVtcSDKException.invalidDocument('malformed record');
    }
    return RoomRecordSummary(
      key: RoomJson.string(item['key'], 'key'),
      version: version,
      status: status,
      updatedAt: RoomJson.instant(item['updatedAt'], 'updatedAt'),
      author: RoomJson.optionalString(item['author']),
      title: RoomJson.optionalString(item['title']),
      description: RoomJson.optionalString(item['description']),
    );
  }
}
