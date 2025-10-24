//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'notify_outreach_ok.g.dart';

/// NotifyOutreachOK
///
/// Properties:
/// * [status]
/// * [message]
@BuiltValue()
abstract class NotifyOutreachOK
    implements Built<NotifyOutreachOK, NotifyOutreachOKBuilder> {
  @BuiltValueField(wireName: r'status')
  String? get status;

  @BuiltValueField(wireName: r'message')
  String? get message;

  NotifyOutreachOK._();

  factory NotifyOutreachOK([void updates(NotifyOutreachOKBuilder b)]) =
      _$NotifyOutreachOK;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(NotifyOutreachOKBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<NotifyOutreachOK> get serializer =>
      _$NotifyOutreachOKSerializer();
}

class _$NotifyOutreachOKSerializer
    implements PrimitiveSerializer<NotifyOutreachOK> {
  @override
  final Iterable<Type> types = const [NotifyOutreachOK, _$NotifyOutreachOK];

  @override
  final String wireName = r'NotifyOutreachOK';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    NotifyOutreachOK object, {
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
    NotifyOutreachOK object, {
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
    required NotifyOutreachOKBuilder result,
    required List<Object?> unhandled,
  }) {
    for (var i = 0; i < serializedList.length; i += 2) {
      final key = serializedList[i] as String;
      final value = serializedList[i + 1];
      switch (key) {
        case r'status':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.status = valueDes;
          break;
        case r'message':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
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
  NotifyOutreachOK deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = NotifyOutreachOKBuilder();
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
