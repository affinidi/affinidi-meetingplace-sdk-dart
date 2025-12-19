//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'check_offer_phrase_input.g.dart';

/// CheckOfferPhraseInput
///
/// Properties:
/// * [offerPhrase] - The offer phrase for checking the availability.
@BuiltValue()
abstract class CheckOfferPhraseInput
    implements Built<CheckOfferPhraseInput, CheckOfferPhraseInputBuilder> {
  /// The offer phrase for checking the availability.
  @BuiltValueField(wireName: r'offerPhrase')
  String get offerPhrase;

  CheckOfferPhraseInput._();

  factory CheckOfferPhraseInput([
    void updates(CheckOfferPhraseInputBuilder b),
  ]) = _$CheckOfferPhraseInput;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(CheckOfferPhraseInputBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<CheckOfferPhraseInput> get serializer =>
      _$CheckOfferPhraseInputSerializer();
}

class _$CheckOfferPhraseInputSerializer
    implements PrimitiveSerializer<CheckOfferPhraseInput> {
  @override
  final Iterable<Type> types = const [
    CheckOfferPhraseInput,
    _$CheckOfferPhraseInput,
  ];

  @override
  final String wireName = r'CheckOfferPhraseInput';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    CheckOfferPhraseInput object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    yield r'offerPhrase';
    yield serializers.serialize(
      object.offerPhrase,
      specifiedType: const FullType(String),
    );
  }

  @override
  Object serialize(
    Serializers serializers,
    CheckOfferPhraseInput object, {
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
    required CheckOfferPhraseInputBuilder result,
    required List<Object?> unhandled,
  }) {
    for (var i = 0; i < serializedList.length; i += 2) {
      final key = serializedList[i] as String;
      final value = serializedList[i + 1];
      switch (key) {
        case r'offerPhrase':
          final valueDes =
              serializers.deserialize(
                    value,
                    specifiedType: const FullType(String),
                  )
                  as String;
          result.offerPhrase = valueDes;
          break;
        default:
          unhandled.add(key);
          unhandled.add(value);
          break;
      }
    }
  }

  @override
  CheckOfferPhraseInput deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = CheckOfferPhraseInputBuilder();
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
