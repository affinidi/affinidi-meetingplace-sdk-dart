//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'register_offer_ok.g.dart';

/// RegisterOfferOK
///
/// Properties:
/// * [message]
/// * [mnemonic]
/// * [validUntil]
/// * [maximumUsage]
/// * [offerLink]
/// * [score]
@BuiltValue()
abstract class RegisterOfferOK
    implements Built<RegisterOfferOK, RegisterOfferOKBuilder> {
  @BuiltValueField(wireName: r'message')
  String? get message;

  @BuiltValueField(wireName: r'mnemonic')
  String get mnemonic;

  @BuiltValueField(wireName: r'validUntil')
  String? get validUntil;

  @BuiltValueField(wireName: r'maximumUsage')
  num? get maximumUsage;

  @BuiltValueField(wireName: r'offerLink')
  String get offerLink;

  @BuiltValueField(wireName: r'score')
  int? get score;

  RegisterOfferOK._();

  factory RegisterOfferOK([void updates(RegisterOfferOKBuilder b)]) =
      _$RegisterOfferOK;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(RegisterOfferOKBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<RegisterOfferOK> get serializer =>
      _$RegisterOfferOKSerializer();
}

class _$RegisterOfferOKSerializer
    implements PrimitiveSerializer<RegisterOfferOK> {
  @override
  final Iterable<Type> types = const [RegisterOfferOK, _$RegisterOfferOK];

  @override
  final String wireName = r'RegisterOfferOK';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    RegisterOfferOK object, {
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
        specifiedType: const FullType(num),
      );
    }
    yield r'offerLink';
    yield serializers.serialize(
      object.offerLink,
      specifiedType: const FullType(String),
    );
    if (object.score != null) {
      yield r'score';
      yield serializers.serialize(
        object.score,
        specifiedType: const FullType(int),
      );
    }
  }

  @override
  Object serialize(
    Serializers serializers,
    RegisterOfferOK object, {
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
    required RegisterOfferOKBuilder result,
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
              serializers.deserialize(value, specifiedType: const FullType(num))
                  as num;
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
        case r'score':
          final valueDes =
              serializers.deserialize(value, specifiedType: const FullType(int))
                  as int;
          result.score = valueDes;
          break;
        default:
          unhandled.add(key);
          unhandled.add(value);
          break;
      }
    }
  }

  @override
  RegisterOfferOK deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = RegisterOfferOKBuilder();
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
