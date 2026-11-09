import 'dart:convert';
import 'dart:typed_data';

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

  /// Reads a member's external card, as they signed it.
  static const cardPublic = '$_base/card/public/0.1';

  /// No external card published for the entry.
  static const cardPublicNotFound = 'vtc/directory/card/public:notFound';

  /// Hands the community a picture for a card.
  static const imagesUpload = '$_base/images/upload/0.1';

  /// Reads a picture's bytes, where the caller's projection shows it.
  static const imagesGet = '$_base/images/get/0.1';

  /// No picture the caller may see, or another than the one expected.
  static const imageNotFound = 'vtc/directory/images/get:notFound';

  /// Changes the caller's own card.
  static const cardUpdate = MemberTask.directoryCardUpdate;

  /// A search shorter than the community allows.
  static const queryTooShort = 'vtc/directory/entries/list:queryTooShort';

  /// No entry the caller may see.
  static const entryNotFound = 'vtc/directory/entries/show:notFound';

  /// The community does not let members show a field that widely.
  static const aboveCeiling = 'vtc/directory/card/update:aboveCeiling';

  /// A value does not fit its field.
  static const valueInvalid = 'vtc/directory/card/update:valueInvalid';

  /// The community's directory policy refused a value.
  static const valueRefused = 'vtc/directory/card/update:valueRefused';
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

  /// The field a member's name is shown in.
  static const displayNameField = 'displayName';

  /// The field a member's picture is shown in.
  static const avatarField = 'avatar';

  /// The audiences that let every member see a field.
  static const _membersOrWider = {'members', 'public'};

  /// The listing of a card no member can find.
  static const _hidden = 'hidden';

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

  /// The external card the member of entry [entryId] published in the
  /// community [communityDid], exactly as they signed it, or null when they
  /// published none.
  ///
  /// Throws [MeetingPlaceVtcSDKException] as [search] does.
  Future<Map<String, dynamic>?> publicCard(
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
        type: DirectoryTask.cardPublic,
        payload: {'entryId': entryId},
      );
    } on MeetingPlaceVtcSDKException catch (error) {
      if (error.refusalCode == DirectoryTask.cardPublicNotFound) return null;
      rethrow;
    }
    final card = payload['card'];
    if (card is! Map<String, dynamic>) {
      throw MeetingPlaceVtcSDKException.invalidDocument('no card');
    }
    return card;
  }

  /// [persona]'s own card in the community [communityDid].
  ///
  /// Throws [MeetingPlaceVtcSDKException] as [search] does.
  Future<MyDirectoryCard> myCard(
    String communityDid, {
    required SignInAgent agent,
    required SignInPersona persona,
  }) async {
    final card = await _card(communityDid, agent: agent, persona: persona);
    final visibility = card['visibility'];
    final values = card['values'];
    final name = values is Map ? values[displayNameField] : null;
    final avatar = values is Map ? values[avatarField] : null;
    return MyDirectoryCard(
      entryId: card['entryId'] as String,
      isDidVisibleToMembers:
          visibility is Map && _membersOrWider.contains(visibility[didField]),
      displayName: name is String && name.trim().isNotEmpty ? name : null,
      isHidden: _discoverability(card)['listing'] == _hidden,
      avatarSha256: avatar is Map && avatar['sha256'] is String
          ? avatar['sha256'] as String
          : null,
    );
  }

  /// Sets the name other members of the community [communityDid] see for
  /// [persona] to [name], or clears it when [name] is null or blank.
  ///
  /// Throws [MeetingPlaceVtcSDKException] as [search] does, such as with
  /// [DirectoryTask.valueInvalid] for a name the field does not take.
  Future<void> setDisplayName(
    String communityDid, {
    required SignInAgent agent,
    required SignInPersona persona,
    required String? name,
  }) {
    final trimmed = name?.trim();
    return _ask(
      communityDid,
      agent: agent,
      persona: persona,
      type: DirectoryTask.cardUpdate,
      payload: {
        'values': {
          displayNameField: trimmed == null || trimmed.isEmpty ? null : trimmed,
        },
      },
    );
  }

  /// Hands the community [communityDid] [bytes], a picture of [mediaType]
  /// (PNG, JPEG or WebP, at most 256 KiB), for [persona]'s card, and
  /// returns the reference a card holds. The community keeps its own
  /// re-encoding, and erases it within a day unless a card takes it up.
  ///
  /// Throws [MeetingPlaceVtcSDKException] as [search] does.
  Future<Map<String, dynamic>> uploadImage(
    String communityDid, {
    required SignInAgent agent,
    required SignInPersona persona,
    required Uint8List bytes,
    required String mediaType,
  }) async {
    final payload = await _ask(
      communityDid,
      agent: agent,
      persona: persona,
      type: DirectoryTask.imagesUpload,
      payload: {
        'mediaType': mediaType,
        'data': base64Url.encode(bytes).replaceAll('=', ''),
      },
    );
    final image = payload['image'];
    if (image is! Map<String, dynamic> || image['sha256'] is! String) {
      throw MeetingPlaceVtcSDKException.invalidDocument('no image');
    }
    return image;
  }

  /// Puts [image], a reference [uploadImage] answered, on [persona]'s card
  /// as the picture every member sees, or takes the picture off and returns
  /// it to the community's default, administrators only, when null.
  ///
  /// Throws [MeetingPlaceVtcSDKException] as [search] does.
  Future<void> setAvatar(
    String communityDid, {
    required SignInAgent agent,
    required SignInPersona persona,
    required Map<String, dynamic>? image,
  }) => _ask(
    communityDid,
    agent: agent,
    persona: persona,
    type: DirectoryTask.cardUpdate,
    payload: {
      'values': {avatarField: image},
      'visibility': {avatarField: image == null ? null : 'members'},
    },
  );

  /// The bytes of the picture on the entry [entryId] of the community
  /// [communityDid], where [persona] may see it, or null when there is none
  /// they may see, or another than [sha256] when given.
  ///
  /// Throws [MeetingPlaceVtcSDKException] as [search] does.
  Future<Uint8List?> avatar(
    String communityDid, {
    required SignInAgent agent,
    required SignInPersona persona,
    required String entryId,
    String? sha256,
  }) async {
    final Map<String, dynamic> payload;
    try {
      payload = await _ask(
        communityDid,
        agent: agent,
        persona: persona,
        type: DirectoryTask.imagesGet,
        payload: {'entryId': entryId, 'field': avatarField, 'sha256': ?sha256},
      );
    } on MeetingPlaceVtcSDKException catch (error) {
      if (error.refusalCode == DirectoryTask.imageNotFound) return null;
      rethrow;
    }
    final data = payload['data'];
    if (data is! String) {
      throw MeetingPlaceVtcSDKException.invalidDocument('no image data');
    }
    return base64Url.decode(base64Url.normalize(data));
  }

  /// Lets every member of the community [communityDid] find [persona] when
  /// [visible], so they can vouch for them: shows them the DID [persona]
  /// joined with and, for a card hidden from them, makes it findable by a
  /// search or a look-up, though not listed for browsing. A card already
  /// listed, its search and whether it is published outside the community
  /// stay as they are, except that a search set to nothing matches the
  /// name.
  ///
  /// When not [visible], returns the DID to the community's default,
  /// administrators only, and leaves the card where it is found.
  ///
  /// Throws [MeetingPlaceVtcSDKException] as [search] does, such as with
  /// [DirectoryTask.aboveCeiling] when the community does not let members
  /// show their DID.
  Future<void> setDidVisibleToMembers(
    String communityDid, {
    required SignInAgent agent,
    required SignInPersona persona,
    required bool visible,
  }) async {
    final Map<String, dynamic>? discoverability;
    if (visible) {
      final current = _discoverability(
        await _card(communityDid, agent: agent, persona: persona),
      );
      discoverability = {
        'listing': current['listing'] == 'listed' ? 'listed' : 'findable',
        'search': switch (current['search']) {
          final String search when search != 'off' => search,
          _ => 'byName',
        },
        'external': current['external'] == true,
      };
    } else {
      discoverability = null;
    }
    await _ask(
      communityDid,
      agent: agent,
      persona: persona,
      type: DirectoryTask.cardUpdate,
      payload: {
        'visibility': {didField: visible ? 'members' : null},
        'discoverability': ?discoverability,
      },
    );
  }

  /// [persona]'s own card, whole (`card/show`).
  Future<Map<String, dynamic>> _card(
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
    if (card is! Map<String, dynamic> || card['entryId'] is! String) {
      throw MeetingPlaceVtcSDKException.invalidDocument('malformed card');
    }
    return card;
  }

  static Map<String, dynamic> _discoverability(Map<String, dynamic> card) =>
      switch (card['discoverability']) {
        final Map<String, dynamic> discoverability => discoverability,
        _ => const {},
      };

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
