// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'offer_finalised.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

OfferFinalised _$OfferFinalisedFromJson(Map<String, dynamic> json) =>
    OfferFinalised(
      id: json['id'] as String,
      offerLink: json['offerLink'] as String,
      notificationToken: json['notificationToken'] as String,
      pendingCount: (json['pendingCount'] as num?)?.toInt() ?? 0,
      isEmpty: json['isEmpty'] as bool? ?? false,
    );
