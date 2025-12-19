//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'register_offer_group_ok.g.dart';

/// RegisterOfferGroupOK
///
/// Properties:
/// * [message]
/// * [mnemonic]
/// * [validUntil]
/// * [maximumUsage]
/// * [offerLink]
/// * [groupId]
/// * [groupDid]
@BuiltValue()
abstract class RegisterOfferGroupOK
    implements Built<RegisterOfferGroupOK, RegisterOfferGroupOKBuilder> {
  @BuiltValueField(wireName: r'message')
  String? get message;

  @BuiltValueField(wireName: r'mnemonic')
  String get mnemonic;

  @BuiltValueField(wireName: r'validUntil')
  String? get validUntil;

  @BuiltValueField(wireName: r'maximumUsage')
  int? get maximumUsage;

  @BuiltValueField(wireName: r'offerLink')
  String get offerLink;

  @BuiltValueField(wireName: r'groupId')
  String get groupId;

  @BuiltValueField(wireName: r'groupDid')
  String get groupDid;

  RegisterOfferGroupOK._();

  factory RegisterOfferGroupOK([void updates(RegisterOfferGroupOKBuilder b)]) =
      _$RegisterOfferGroupOK;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(RegisterOfferGroupOKBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<RegisterOfferGroupOK> get serializer =>
      _$RegisterOfferGroupOKSerializer();
}

class _$RegisterOfferGroupOKSerializer
    implements PrimitiveSerializer<RegisterOfferGroupOK> {
  @override
  final Iterable<Type> types = const [
    RegisterOfferGroupOK,
    _$RegisterOfferGroupOK,
  ];

  @override
  final String wireName = r'RegisterOfferGroupOK';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    RegisterOfferGroupOK object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    if (object.message != null) {
      yield r'message';
      yield serializers.serialize(
        object.message,
        specifiedType: const FullType(String),
      );
    }
    yield r'mnemonic';
    yield serializers.serialize(
      object.mnemonic,
      specifiedType: const FullType(String),
    );
    if (object.validUntil != null) {
      yield r'validUntil';
      yield serializers.serialize(
        object.validUntil,
        specifiedType: const FullType(String),
      );
    }
    if (object.maximumUsage != null) {
      yield r'maximumUsage';
      yield serializers.serialize(
        object.maximumUsage,
        specifiedType: const FullType(int),
      );
    }
    yield r'offerLink';
    yield serializers.serialize(
      object.offerLink,
      specifiedType: const FullType(String),
    );
    yield r'groupId';
    yield serializers.serialize(
      object.groupId,
      specifiedType: const FullType(String),
    );
    yield r'groupDid';
    yield serializers.serialize(
      object.groupDid,
      specifiedType: const FullType(String),
    );
  }

  @override
  Object serialize(
    Serializers serializers,
    RegisterOfferGroupOK object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(
      serializers,
      object,
      specifiedType: specifiedType,
    ).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required RegisterOfferGroupOKBuilder result,
    required List<Object?> unhandled,
  }) {
    for (var i = 0; i < serializedList.length; i += 2) {
      final key = serializedList[i] as String;
      final value = serializedList[i + 1];
      switch (key) {
        case r'message':
          final valueDes =
              serializers.deserialize(
                    value,
                    specifiedType: const FullType(String),
                  )
                  as String;
          result.message = valueDes;
          break;
        case r'mnemonic':
          final valueDes =
              serializers.deserialize(
                    value,
                    specifiedType: const FullType(String),
                  )
                  as String;
          result.mnemonic = valueDes;
          break;
        case r'validUntil':
          final valueDes =
              serializers.deserialize(
                    value,
                    specifiedType: const FullType(String),
                  )
                  as String;
          result.validUntil = valueDes;
          break;
        case r'maximumUsage':
          final valueDes =
              serializers.deserialize(value, specifiedType: const FullType(int))
                  as int;
          result.maximumUsage = valueDes;
          break;
        case r'offerLink':
          final valueDes =
              serializers.deserialize(
                    value,
                    specifiedType: const FullType(String),
                  )
                  as String;
          result.offerLink = valueDes;
          break;
        case r'groupId':
          final valueDes =
              serializers.deserialize(
                    value,
                    specifiedType: const FullType(String),
                  )
                  as String;
          result.groupId = valueDes;
          break;
        case r'groupDid':
          final valueDes =
              serializers.deserialize(
                    value,
                    specifiedType: const FullType(String),
                  )
                  as String;
          result.groupDid = valueDes;
          break;
        default:
          unhandled.add(key);
          unhandled.add(value);
          break;
      }
    }
  }

  @override
  RegisterOfferGroupOK deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = RegisterOfferGroupOKBuilder();
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
