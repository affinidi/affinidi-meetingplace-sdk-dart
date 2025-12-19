//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'notify_accept_offer_ok.g.dart';

/// NotifyAcceptOfferOK
///
/// Properties:
/// * [status]
/// * [message]
@BuiltValue()
abstract class NotifyAcceptOfferOK
    implements Built<NotifyAcceptOfferOK, NotifyAcceptOfferOKBuilder> {
  @BuiltValueField(wireName: r'status')
  String? get status;

  @BuiltValueField(wireName: r'message')
  String? get message;

  NotifyAcceptOfferOK._();

  factory NotifyAcceptOfferOK([void updates(NotifyAcceptOfferOKBuilder b)]) =
      _$NotifyAcceptOfferOK;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(NotifyAcceptOfferOKBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<NotifyAcceptOfferOK> get serializer =>
      _$NotifyAcceptOfferOKSerializer();
}

class _$NotifyAcceptOfferOKSerializer
    implements PrimitiveSerializer<NotifyAcceptOfferOK> {
  @override
  final Iterable<Type> types = const [
    NotifyAcceptOfferOK,
    _$NotifyAcceptOfferOK,
  ];

  @override
  final String wireName = r'NotifyAcceptOfferOK';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    NotifyAcceptOfferOK object, {
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
    NotifyAcceptOfferOK object, {
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
    required NotifyAcceptOfferOKBuilder result,
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
  NotifyAcceptOfferOK deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = NotifyAcceptOfferOKBuilder();
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
