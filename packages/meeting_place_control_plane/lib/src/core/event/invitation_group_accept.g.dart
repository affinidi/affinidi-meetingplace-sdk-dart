// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'invitation_group_accept.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

InvitationGroupAccept _$InvitationGroupAcceptFromJson(
  Map<String, dynamic> json,
) => InvitationGroupAccept(
  id: json['id'] as String,
  acceptOfferAsDid: json['did'] as String,
  offerLink: json['offerLink'] as String,
  isEmpty: json['isEmpty'] as bool? ?? false,
  pendingCount: (json['pendingCount'] as num?)?.toInt() ?? 0,
);
