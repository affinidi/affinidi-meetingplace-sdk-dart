//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'register_notification_ok.g.dart';

/// RegisterNotificationOK
///
/// Properties:
/// * [notificationToken] - The token for the notification
@BuiltValue()
abstract class RegisterNotificationOK
    implements Built<RegisterNotificationOK, RegisterNotificationOKBuilder> {
  /// The token for the notification
  @BuiltValueField(wireName: r'notificationToken')
  String get notificationToken;

  RegisterNotificationOK._();

  factory RegisterNotificationOK([
    void updates(RegisterNotificationOKBuilder b),
  ]) = _$RegisterNotificationOK;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(RegisterNotificationOKBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<RegisterNotificationOK> get serializer =>
      _$RegisterNotificationOKSerializer();
}

class _$RegisterNotificationOKSerializer
    implements PrimitiveSerializer<RegisterNotificationOK> {
  @override
  final Iterable<Type> types = const [
    RegisterNotificationOK,
    _$RegisterNotificationOK,
  ];

  @override
  final String wireName = r'RegisterNotificationOK';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    RegisterNotificationOK object, {
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
    RegisterNotificationOK object, {
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
    required RegisterNotificationOKBuilder result,
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
  RegisterNotificationOK deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = RegisterNotificationOKBuilder();
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
