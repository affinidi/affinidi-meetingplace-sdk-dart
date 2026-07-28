// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'vta_authenticate_result.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

VtaAuthenticateResult _$VtaAuthenticateResultFromJson(
  Map<String, dynamic> json,
) => VtaAuthenticateResult(
  tokens: AuthTokens.fromJson(json['tokens'] as Map<String, dynamic>),
  session: SessionInfo.fromJson(json['session'] as Map<String, dynamic>),
);

Map<String, dynamic> _$VtaAuthenticateResultToJson(
  VtaAuthenticateResult instance,
) => <String, dynamic>{
  'tokens': instance.tokens.toJson(),
  'session': instance.session.toJson(),
};
