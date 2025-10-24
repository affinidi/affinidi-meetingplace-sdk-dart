//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'notify_channel_ok.g.dart';

/// NotifyChannelOK
///
/// Properties:
/// * [notificationId] - The notification identifier
@BuiltValue()
abstract class NotifyChannelOK
    implements Built<NotifyChannelOK, NotifyChannelOKBuilder> {
  /// The notification identifier
  @BuiltValueField(wireName: r'notificationId')
  String get notificationId;

  NotifyChannelOK._();

  factory NotifyChannelOK([void updates(NotifyChannelOKBuilder b)]) =
      _$NotifyChannelOK;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(NotifyChannelOKBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<NotifyChannelOK> get serializer =>
      _$NotifyChannelOKSerializer();
}

class _$NotifyChannelOKSerializer
    implements PrimitiveSerializer<NotifyChannelOK> {
  @override
  final Iterable<Type> types = const [NotifyChannelOK, _$NotifyChannelOK];

  @override
  final String wireName = r'NotifyChannelOK';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    NotifyChannelOK object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    yield r'notificationId';
    yield serializers.serialize(
      object.notificationId,
      specifiedType: const FullType(String),
    );
  }

  @override
  Object serialize(
    Serializers serializers,
    NotifyChannelOK object, {
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
    required NotifyChannelOKBuilder result,
    required List<Object?> unhandled,
  }) {
    for (var i = 0; i < serializedList.length; i += 2) {
      final key = serializedList[i] as String;
      final value = serializedList[i + 1];
      switch (key) {
        case r'notificationId':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.notificationId = valueDes;
          break;
        default:
          unhandled.add(key);
          unhandled.add(value);
          break;
      }
    }
  }

  @override
  NotifyChannelOK deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = NotifyChannelOKBuilder();
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
