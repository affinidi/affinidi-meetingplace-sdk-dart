//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'check_offer_phrase_ok.g.dart';

/// CheckOfferPhraseOK
///
/// Properties:
/// * [isInUse] - Whether the offer phrase is already in use
@BuiltValue()
abstract class CheckOfferPhraseOK
    implements Built<CheckOfferPhraseOK, CheckOfferPhraseOKBuilder> {
  /// Whether the offer phrase is already in use
  @BuiltValueField(wireName: r'isInUse')
  bool get isInUse;

  CheckOfferPhraseOK._();

  factory CheckOfferPhraseOK([void updates(CheckOfferPhraseOKBuilder b)]) =
      _$CheckOfferPhraseOK;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(CheckOfferPhraseOKBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<CheckOfferPhraseOK> get serializer =>
      _$CheckOfferPhraseOKSerializer();
}

class _$CheckOfferPhraseOKSerializer
    implements PrimitiveSerializer<CheckOfferPhraseOK> {
  @override
  final Iterable<Type> types = const [CheckOfferPhraseOK, _$CheckOfferPhraseOK];

  @override
  final String wireName = r'CheckOfferPhraseOK';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    CheckOfferPhraseOK object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    yield r'isInUse';
    yield serializers.serialize(
      object.isInUse,
      specifiedType: const FullType(bool),
    );
  }

  @override
  Object serialize(
    Serializers serializers,
    CheckOfferPhraseOK object, {
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
    required CheckOfferPhraseOKBuilder result,
    required List<Object?> unhandled,
  }) {
    for (var i = 0; i < serializedList.length; i += 2) {
      final key = serializedList[i] as String;
      final value = serializedList[i + 1];
      switch (key) {
        case r'isInUse':
          final valueDes =
              serializers.deserialize(
                    value,
                    specifiedType: const FullType(bool),
                  )
                  as bool;
          result.isInUse = valueDes;
          break;
        default:
          unhandled.add(key);
          unhandled.add(value);
          break;
      }
    }
  }

  @override
  CheckOfferPhraseOK deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = CheckOfferPhraseOKBuilder();
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
