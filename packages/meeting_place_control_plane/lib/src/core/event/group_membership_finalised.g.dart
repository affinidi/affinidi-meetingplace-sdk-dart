// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'group_membership_finalised.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

GroupMembershipFinalised _$GroupMembershipFinalisedFromJson(
  Map<String, dynamic> json,
) => GroupMembershipFinalised(
  id: json['id'] as String,
  offerLink: json['offerLink'] as String,
  pendingCount: (json['pendingCount'] as num?)?.toInt() ?? 0,
  startSeqNo: (json['startSeqNo'] as num?)?.toInt() ?? 0,
  isEmpty: json['isEmpty'] as bool? ?? false,
);
