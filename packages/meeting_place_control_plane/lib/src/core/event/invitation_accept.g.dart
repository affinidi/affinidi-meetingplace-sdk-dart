// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'invitation_accept.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

InvitationAccept _$InvitationAcceptFromJson(Map<String, dynamic> json) =>
    InvitationAccept(
      id: json['id'] as String,
      acceptOfferAsDid: json['did'] as String,
      offerLink: json['offerLink'] as String,
      pendingCount: (json['pendingCount'] as num?)?.toInt() ?? 0,
      isEmpty: json['isEmpty'] as bool? ?? false,
    );
