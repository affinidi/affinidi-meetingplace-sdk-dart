// ignore_for_file: unused_element
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'notify_channel_group_ok.g.dart';

/// NotifyChannelGroupOK
///
/// Properties:
/// * [notifiedCount] - The number of group members notified.
@BuiltValue()
abstract class NotifyChannelGroupOK
    implements Built<NotifyChannelGroupOK, NotifyChannelGroupOKBuilder> {
  /// The number of group members notified.
  @BuiltValueField(wireName: r'notifiedCount')
  int get notifiedCount;

  NotifyChannelGroupOK._();

  factory NotifyChannelGroupOK([void updates(NotifyChannelGroupOKBuilder b)]) =
      _$NotifyChannelGroupOK;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(NotifyChannelGroupOKBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<NotifyChannelGroupOK> get serializer =>
      _$NotifyChannelGroupOKSerializer();
}

class _$NotifyChannelGroupOKSerializer
    implements PrimitiveSerializer<NotifyChannelGroupOK> {
  @override
  final Iterable<Type> types = const [
    NotifyChannelGroupOK,
    _$NotifyChannelGroupOK,
  ];

  @override
  final String wireName = r'NotifyChannelGroupOK';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    NotifyChannelGroupOK object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    yield r'notifiedCount';
    yield serializers.serialize(
      object.notifiedCount,
      specifiedType: const FullType(int),
    );
  }

  @override
  Object serialize(
    Serializers serializers,
    NotifyChannelGroupOK object, {
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
    required NotifyChannelGroupOKBuilder result,
    required List<Object?> unhandled,
  }) {
    for (var i = 0; i < serializedList.length; i += 2) {
      final key = serializedList[i] as String;
      final value = serializedList[i + 1];
      switch (key) {
        case r'notifiedCount':
          final valueDes =
              serializers.deserialize(value, specifiedType: const FullType(int))
                  as int;
          result.notifiedCount = valueDes;
          break;
        default:
          unhandled.add(key);
          unhandled.add(value);
          break;
      }
    }
  }

  @override
  NotifyChannelGroupOK deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = NotifyChannelGroupOKBuilder();
    final serializedList = (serialized as Iterable<Object?>).toList();
    final unhandled = <Object?>[];
    _deserializeProperties(
      serializers,
      serialized,
      specifiedType: specifiedType,
      serializedList: serializedList,
      result: result,
      unhandled: unhandled,
    );
    return result.build();
  }
}
