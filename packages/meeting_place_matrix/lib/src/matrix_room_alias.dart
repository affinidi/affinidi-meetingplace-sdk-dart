import 'dart:convert';

import 'package:crypto/crypto.dart';

/// Derives the deterministic Matrix room alias localpart for a channel.
///
/// For two-party channels (individual, OOB), pass both DIDs — the result is
/// commutative (`(a, b)` and `(b, a)` yield the same localpart), so both
/// parties derive the same alias without coordination.
///
/// For group channels, pass only the group's [channelDid]; every member
/// derives the same alias from the shared group DID.
String deriveRoomAliasLocalpart({
  required String channelDid,
  String? otherPartyChannelDid,
}) {
  final parts = otherPartyChannelDid == null
      ? [channelDid]
      : ([channelDid, otherPartyChannelDid]..sort());
  final digest = sha256.convert(utf8.encode(parts.join('|')));
  return 'mp_$digest';
}

/// Derives the full Matrix room alias (`#localpart:homeserverHost`) for a
/// channel. See [deriveRoomAliasLocalpart] for the localpart semantics.
String deriveRoomAlias({
  required String channelDid,
  String? otherPartyChannelDid,
  required String homeserverHost,
}) {
  final localpart = deriveRoomAliasLocalpart(
    channelDid: channelDid,
    otherPartyChannelDid: otherPartyChannelDid,
  );
  return '#$localpart:$homeserverHost';
}
