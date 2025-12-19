//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'deregister_offer_input.g.dart';

/// DeregisterOfferInput
///
/// Properties:
/// * [mnemonic] - A unique phrase used to publish and identify the offer.
/// * [offerLink] - Offer link to deregister.
@BuiltValue()
abstract class DeregisterOfferInput
    implements Built<DeregisterOfferInput, DeregisterOfferInputBuilder> {
  /// A unique phrase used to publish and identify the offer.
  @BuiltValueField(wireName: r'mnemonic')
  String get mnemonic;

  /// Offer link to deregister.
  @BuiltValueField(wireName: r'offerLink')
  String get offerLink;

  DeregisterOfferInput._();

  factory DeregisterOfferInput([void updates(DeregisterOfferInputBuilder b)]) =
      _$DeregisterOfferInput;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(DeregisterOfferInputBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<DeregisterOfferInput> get serializer =>
      _$DeregisterOfferInputSerializer();
}

class _$DeregisterOfferInputSerializer
    implements PrimitiveSerializer<DeregisterOfferInput> {
  @override
  final Iterable<Type> types = const [
    DeregisterOfferInput,
    _$DeregisterOfferInput,
  ];

  @override
  final String wireName = r'DeregisterOfferInput';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    DeregisterOfferInput object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    yield r'mnemonic';
    yield serializers.serialize(
      object.mnemonic,
      specifiedType: const FullType(String),
    );
    yield r'offerLink';
    yield serializers.serialize(
      object.offerLink,
      specifiedType: const FullType(String),
    );
  }

  @override
  Object serialize(
    Serializers serializers,
    DeregisterOfferInput object, {
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
    required DeregisterOfferInputBuilder result,
    required List<Object?> unhandled,
  }) {
    for (var i = 0; i < serializedList.length; i += 2) {
      final key = serializedList[i] as String;
      final value = serializedList[i + 1];
      switch (key) {
        case r'mnemonic':
          final valueDes =
              serializers.deserialize(
                    value,
                    specifiedType: const FullType(String),
                  )
                  as String;
          result.mnemonic = valueDes;
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
        default:
          unhandled.add(key);
          unhandled.add(value);
          break;
      }
    }
  }

  @override
  DeregisterOfferInput deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = DeregisterOfferInputBuilder();
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
