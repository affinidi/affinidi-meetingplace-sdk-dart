// ignore_for_file: unused_element
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'notify_channel_group_input.g.dart';

/// NotifyChannelGroupInput
///
/// Properties:
/// * [groupId] - The group ID to notify members of.
/// * [type] - The type of activity.
@BuiltValue()
abstract class NotifyChannelGroupInput
    implements Built<NotifyChannelGroupInput, NotifyChannelGroupInputBuilder> {
  /// The group ID to notify members of.
  @BuiltValueField(wireName: r'groupId')
  String get groupId;

  /// The type of activity.
  @BuiltValueField(wireName: r'type')
  String get type;

  NotifyChannelGroupInput._();

  factory NotifyChannelGroupInput([
    void updates(NotifyChannelGroupInputBuilder b),
  ]) = _$NotifyChannelGroupInput;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(NotifyChannelGroupInputBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<NotifyChannelGroupInput> get serializer =>
      _$NotifyChannelGroupInputSerializer();
}

class _$NotifyChannelGroupInputSerializer
    implements PrimitiveSerializer<NotifyChannelGroupInput> {
  @override
  final Iterable<Type> types = const [
    NotifyChannelGroupInput,
    _$NotifyChannelGroupInput,
  ];

  @override
  final String wireName = r'NotifyChannelGroupInput';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    NotifyChannelGroupInput object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    yield r'groupId';
    yield serializers.serialize(
      object.groupId,
      specifiedType: const FullType(String),
    );
    yield r'type';
    yield serializers.serialize(
      object.type,
      specifiedType: const FullType(String),
    );
  }

  @override
  Object serialize(
    Serializers serializers,
    NotifyChannelGroupInput object, {
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
    required NotifyChannelGroupInputBuilder result,
    required List<Object?> unhandled,
  }) {
    for (var i = 0; i < serializedList.length; i += 2) {
      final key = serializedList[i] as String;
      final value = serializedList[i + 1];
      switch (key) {
        case r'groupId':
          final valueDes =
              serializers.deserialize(
                    value,
                    specifiedType: const FullType(String),
                  )
                  as String;
          result.groupId = valueDes;
          break;
        case r'type':
          final valueDes =
              serializers.deserialize(
                    value,
                    specifiedType: const FullType(String),
                  )
                  as String;
          result.type = valueDes;
          break;
        default:
          unhandled.add(key);
          unhandled.add(value);
          break;
      }
    }
  }

  @override
  NotifyChannelGroupInput deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = NotifyChannelGroupInputBuilder();
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
