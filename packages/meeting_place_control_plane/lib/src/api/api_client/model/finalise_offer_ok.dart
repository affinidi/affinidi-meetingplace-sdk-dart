//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'finalise_offer_ok.g.dart';

/// FinaliseOfferOK
///
/// Properties:
/// * [status]
/// * [message]
/// * [notificationToken]
@BuiltValue()
abstract class FinaliseOfferOK
    implements Built<FinaliseOfferOK, FinaliseOfferOKBuilder> {
  @BuiltValueField(wireName: r'status')
  String? get status;

  @BuiltValueField(wireName: r'message')
  String? get message;

  @BuiltValueField(wireName: r'notificationToken')
  String get notificationToken;

  FinaliseOfferOK._();

  factory FinaliseOfferOK([void updates(FinaliseOfferOKBuilder b)]) =
      _$FinaliseOfferOK;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(FinaliseOfferOKBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<FinaliseOfferOK> get serializer =>
      _$FinaliseOfferOKSerializer();
}

class _$FinaliseOfferOKSerializer
    implements PrimitiveSerializer<FinaliseOfferOK> {
  @override
  final Iterable<Type> types = const [FinaliseOfferOK, _$FinaliseOfferOK];

  @override
  final String wireName = r'FinaliseOfferOK';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    FinaliseOfferOK object, {
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
    yield r'notificationToken';
    yield serializers.serialize(
      object.notificationToken,
      specifiedType: const FullType(String),
    );
  }

  @override
  Object serialize(
    Serializers serializers,
    FinaliseOfferOK object, {
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
    required FinaliseOfferOKBuilder result,
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
        case r'notificationToken':
          final valueDes =
              serializers.deserialize(
                    value,
                    specifiedType: const FullType(String),
                  )
                  as String;
          result.notificationToken = valueDes;
          break;
        default:
          unhandled.add(key);
          unhandled.add(value);
          break;
      }
    }
  }

  @override
  FinaliseOfferOK deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = FinaliseOfferOKBuilder();
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
