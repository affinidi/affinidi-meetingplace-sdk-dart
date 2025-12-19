//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'deregister_offer_ok.g.dart';

/// DeregisterOfferOK
///
/// Properties:
/// * [status]
/// * [message]
@BuiltValue()
abstract class DeregisterOfferOK
    implements Built<DeregisterOfferOK, DeregisterOfferOKBuilder> {
  @BuiltValueField(wireName: r'status')
  String? get status;

  @BuiltValueField(wireName: r'message')
  String? get message;

  DeregisterOfferOK._();

  factory DeregisterOfferOK([void updates(DeregisterOfferOKBuilder b)]) =
      _$DeregisterOfferOK;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(DeregisterOfferOKBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<DeregisterOfferOK> get serializer =>
      _$DeregisterOfferOKSerializer();
}

class _$DeregisterOfferOKSerializer
    implements PrimitiveSerializer<DeregisterOfferOK> {
  @override
  final Iterable<Type> types = const [DeregisterOfferOK, _$DeregisterOfferOK];

  @override
  final String wireName = r'DeregisterOfferOK';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    DeregisterOfferOK object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    if (object.status != null) {
      yield r'status';
      yield serializers.serialize(
        object.status,
        specifiedType: const FullType(String),
      );
    }
    if (object.message != null) {
      yield r'message';
      yield serializers.serialize(
        object.message,
        specifiedType: const FullType(String),
      );
    }
  }

  @override
  Object serialize(
    Serializers serializers,
    DeregisterOfferOK object, {
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
    required DeregisterOfferOKBuilder result,
    required List<Object?> unhandled,
  }) {
    for (var i = 0; i < serializedList.length; i += 2) {
      final key = serializedList[i] as String;
      final value = serializedList[i + 1];
      switch (key) {
        case r'status':
          final valueDes =
              serializers.deserialize(
                    value,
                    specifiedType: const FullType(String),
                  )
                  as String;
          result.status = valueDes;
          break;
        case r'message':
          final valueDes =
              serializers.deserialize(
                    value,
                    specifiedType: const FullType(String),
                  )
                  as String;
          result.message = valueDes;
          break;
        default:
          unhandled.add(key);
          unhandled.add(value);
          break;
      }
    }
  }

  @override
  DeregisterOfferOK deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = DeregisterOfferOKBuilder();
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
