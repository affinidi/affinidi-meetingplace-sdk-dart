// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'did_document_hosting_record.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

DidDocumentHostingRecord _$DidDocumentHostingRecordFromJson(
  Map<String, dynamic> json,
) => DidDocumentHostingRecord(
  did: json['did'] as String,
  segment: json['segment'] as String,
  didDocUrl: json['didDocUrl'] as String,
);

Map<String, dynamic> _$DidDocumentHostingRecordToJson(
  DidDocumentHostingRecord instance,
) => <String, dynamic>{
  'did': instance.did,
  'segment': instance.segment,
  'didDocUrl': instance.didDocUrl,
};
