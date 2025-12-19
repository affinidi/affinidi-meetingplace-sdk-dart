//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'notify_channel_input.g.dart';

/// NotifyChannelInput
///
/// Properties:
/// * [notificationChannelId] - The channel ID to send the notification.
/// * [did] - The DID for identifying the activity.
/// * [type] - The type of activity.
@BuiltValue()
abstract class NotifyChannelInput
    implements Built<NotifyChannelInput, NotifyChannelInputBuilder> {
  /// The channel ID to send the notification.
  @BuiltValueField(wireName: r'notificationChannelId')
  String get notificationChannelId;

  /// The DID for identifying the activity.
  @BuiltValueField(wireName: r'did')
  String get did;

  /// The type of activity.
  @BuiltValueField(wireName: r'type')
  String get type;

  NotifyChannelInput._();

  factory NotifyChannelInput([void updates(NotifyChannelInputBuilder b)]) =
      _$NotifyChannelInput;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(NotifyChannelInputBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<NotifyChannelInput> get serializer =>
      _$NotifyChannelInputSerializer();
}

class _$NotifyChannelInputSerializer
    implements PrimitiveSerializer<NotifyChannelInput> {
  @override
  final Iterable<Type> types = const [NotifyChannelInput, _$NotifyChannelInput];

  @override
  final String wireName = r'NotifyChannelInput';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    NotifyChannelInput object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    yield r'notificationChannelId';
    yield serializers.serialize(
      object.notificationChannelId,
      specifiedType: const FullType(String),
    );
    yield r'did';
    yield serializers.serialize(
      object.did,
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
    NotifyChannelInput object, {
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
    required NotifyChannelInputBuilder result,
    required List<Object?> unhandled,
  }) {
    for (var i = 0; i < serializedList.length; i += 2) {
      final key = serializedList[i] as String;
      final value = serializedList[i + 1];
      switch (key) {
        case r'notificationChannelId':
          final valueDes =
              serializers.deserialize(
                    value,
                    specifiedType: const FullType(String),
                  )
                  as String;
          result.notificationChannelId = valueDes;
          break;
        case r'did':
          final valueDes =
              serializers.deserialize(
                    value,
                    specifiedType: const FullType(String),
                  )
                  as String;
          result.did = valueDes;
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
  NotifyChannelInput deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = NotifyChannelInputBuilder();
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
