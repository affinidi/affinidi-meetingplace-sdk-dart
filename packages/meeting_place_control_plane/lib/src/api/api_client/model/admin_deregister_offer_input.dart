//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'admin_deregister_offer_input.g.dart';

/// AdminDeregisterOfferInput
///
/// Properties:
/// * [mnemonic] - A unique phrase used to publish and identify the offer.
@BuiltValue()
abstract class AdminDeregisterOfferInput implements Built<AdminDeregisterOfferInput, AdminDeregisterOfferInputBuilder> {
  /// A unique phrase used to publish and identify the offer.
  @BuiltValueField(wireName: r'mnemonic')
  String get mnemonic;

  AdminDeregisterOfferInput._();

  factory AdminDeregisterOfferInput([void updates(AdminDeregisterOfferInputBuilder b)]) = _$AdminDeregisterOfferInput;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(AdminDeregisterOfferInputBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<AdminDeregisterOfferInput> get serializer => _$AdminDeregisterOfferInputSerializer();
}

class _$AdminDeregisterOfferInputSerializer implements PrimitiveSerializer<AdminDeregisterOfferInput> {
  @override
  final Iterable<Type> types = const [AdminDeregisterOfferInput, _$AdminDeregisterOfferInput];

  @override
  final String wireName = r'AdminDeregisterOfferInput';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    AdminDeregisterOfferInput object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    yield r'mnemonic';
    yield serializers.serialize(
      object.mnemonic,
      specifiedType: const FullType(String),
    );
  }

  @override
  Object serialize(
    Serializers serializers,
    AdminDeregisterOfferInput object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required AdminDeregisterOfferInputBuilder result,
    required List<Object?> unhandled,
  }) {
    for (var i = 0; i < serializedList.length; i += 2) {
      final key = serializedList[i] as String;
      final value = serializedList[i + 1];
      switch (key) {
        case r'mnemonic':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.mnemonic = valueDes;
          break;
        default:
          unhandled.add(key);
          unhandled.add(value);
          break;
      }
    }
  }

  @override
  AdminDeregisterOfferInput deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = AdminDeregisterOfferInputBuilder();
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

