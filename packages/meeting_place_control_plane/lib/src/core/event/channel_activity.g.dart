// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'channel_activity.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ChannelActivity _$ChannelActivityFromJson(Map<String, dynamic> json) =>
    ChannelActivity(
      id: json['id'] as String,
      did: json['did'] as String,
      type: json['type'] as String,
      pendingCount: (json['pendingCount'] as num?)?.toInt() ?? 0,
      isEmpty: json['isEmpty'] as bool? ?? false,
    );
