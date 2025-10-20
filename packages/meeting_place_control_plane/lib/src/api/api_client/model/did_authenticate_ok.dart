//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'did_authenticate_ok.g.dart';

/// DidAuthenticateOK
///
/// Properties:
/// * [accessToken]
/// * [accessExpiresAt] - date and time the access token expires in ISO-8601 format, e.g. 2023-09-20T07:12:13
/// * [refreshToken]
/// * [refreshExpiresAt] - date and time the refresh token expires in ISO-8601 format, e.g. 2023-09-20T07:12:13
@BuiltValue()
abstract class DidAuthenticateOK
    implements Built<DidAuthenticateOK, DidAuthenticateOKBuilder> {
  @BuiltValueField(wireName: r'access_token')
  String? get accessToken;

  /// date and time the access token expires in ISO-8601 format, e.g. 2023-09-20T07:12:13
  @BuiltValueField(wireName: r'access_expires_at')
  String? get accessExpiresAt;

  @BuiltValueField(wireName: r'refresh_token')
  String? get refreshToken;

  /// date and time the refresh token expires in ISO-8601 format, e.g. 2023-09-20T07:12:13
  @BuiltValueField(wireName: r'refresh_expires_at')
  String? get refreshExpiresAt;

  DidAuthenticateOK._();

  factory DidAuthenticateOK([void updates(DidAuthenticateOKBuilder b)]) =
      _$DidAuthenticateOK;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(DidAuthenticateOKBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<DidAuthenticateOK> get serializer =>
      _$DidAuthenticateOKSerializer();
}

class _$DidAuthenticateOKSerializer
    implements PrimitiveSerializer<DidAuthenticateOK> {
  @override
  final Iterable<Type> types = const [DidAuthenticateOK, _$DidAuthenticateOK];

  @override
  final String wireName = r'DidAuthenticateOK';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    DidAuthenticateOK object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    if (object.accessToken != null) {
      yield r'access_token';
      yield serializers.serialize(
        object.accessToken,
        specifiedType: const FullType(String),
      );
    }
    if (object.accessExpiresAt != null) {
      yield r'access_expires_at';
      yield serializers.serialize(
        object.accessExpiresAt,
        specifiedType: const FullType(String),
      );
    }
    if (object.refreshToken != null) {
      yield r'refresh_token';
      yield serializers.serialize(
        object.refreshToken,
        specifiedType: const FullType(String),
      );
    }
    if (object.refreshExpiresAt != null) {
      yield r'refresh_expires_at';
      yield serializers.serialize(
        object.refreshExpiresAt,
        specifiedType: const FullType(String),
      );
    }
  }

  @override
  Object serialize(
    Serializers serializers,
    DidAuthenticateOK object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object,
            specifiedType: specifiedType)
        .toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required DidAuthenticateOKBuilder result,
    required List<Object?> unhandled,
  }) {
    for (var i = 0; i < serializedList.length; i += 2) {
      final key = serializedList[i] as String;
      final value = serializedList[i + 1];
      switch (key) {
        case r'access_token':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.accessToken = valueDes;
          break;
        case r'access_expires_at':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.accessExpiresAt = valueDes;
          break;
        case r'refresh_token':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.refreshToken = valueDes;
          break;
        case r'refresh_expires_at':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.refreshExpiresAt = valueDes;
          break;
        default:
          unhandled.add(key);
          unhandled.add(value);
          break;
      }
    }
  }

  @override
  DidAuthenticateOK deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = DidAuthenticateOKBuilder();
    final serializedList = (serialized as Iterable<Object?>).toList();
    final unhandled = <Object?>[];
    _deserializeProperties(
      serializers,
      serialized,
      specifiedType: specifiedType,
      serializedList: serializedList,
      unhandled: unhandled,
      result: result,
    );
    return result.build();
  }
}
