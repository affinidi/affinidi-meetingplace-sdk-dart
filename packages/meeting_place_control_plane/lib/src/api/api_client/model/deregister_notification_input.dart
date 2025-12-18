//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'deregister_notification_input.g.dart';

/// DeregisterNotificationInput
///
/// Properties:
/// * [notificationToken] - Notification token to deregister the target device.
@BuiltValue()
abstract class DeregisterNotificationInput
    implements
        Built<DeregisterNotificationInput, DeregisterNotificationInputBuilder> {
  /// Notification token to deregister the target device.
  @BuiltValueField(wireName: r'notificationToken')
  String get notificationToken;

  DeregisterNotificationInput._();

  factory DeregisterNotificationInput([
    void updates(DeregisterNotificationInputBuilder b),
  ]) = _$DeregisterNotificationInput;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(DeregisterNotificationInputBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<DeregisterNotificationInput> get serializer =>
      _$DeregisterNotificationInputSerializer();
}

class _$DeregisterNotificationInputSerializer
    implements PrimitiveSerializer<DeregisterNotificationInput> {
  @override
  final Iterable<Type> types = const [
    DeregisterNotificationInput,
    _$DeregisterNotificationInput,
  ];

  @override
  final String wireName = r'DeregisterNotificationInput';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    DeregisterNotificationInput object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    yield r'notificationToken';
    yield serializers.serialize(
      object.notificationToken,
      specifiedType: const FullType(String),
    );
  }

  @override
  Object serialize(
    Serializers serializers,
    DeregisterNotificationInput object, {
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
    required DeregisterNotificationInputBuilder result,
    required List<Object?> unhandled,
  }) {
    for (var i = 0; i < serializedList.length; i += 2) {
      final key = serializedList[i] as String;
      final value = serializedList[i + 1];
      switch (key) {
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
  DeregisterNotificationInput deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = DeregisterNotificationInputBuilder();
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
