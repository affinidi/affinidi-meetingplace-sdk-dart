//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_collection/built_collection.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'register_notification_input.g.dart';

/// RegisterNotificationInput
///
/// Properties:
/// * [myDid] - Current user's DID for the channel.
/// * [theirDid] - Other user's DID for the channel.
/// * [deviceToken] - The device token for push notification when the offer is accessed.  Maximum length of 2048 characters.
/// * [platformType] - Platform type for sending notification.
@BuiltValue()
abstract class RegisterNotificationInput
    implements
        Built<RegisterNotificationInput, RegisterNotificationInputBuilder> {
  /// Current user's DID for the channel.
  @BuiltValueField(wireName: r'myDid')
  String get myDid;

  /// Other user's DID for the channel.
  @BuiltValueField(wireName: r'theirDid')
  String get theirDid;

  /// The device token for push notification when the offer is accessed.  Maximum length of 2048 characters.
  @BuiltValueField(wireName: r'deviceToken')
  String get deviceToken;

  /// Platform type for sending notification.
  @BuiltValueField(wireName: r'platformType')
  RegisterNotificationInputPlatformTypeEnum get platformType;
  // enum platformTypeEnum {  DIDCOMM,  PUSH_NOTIFICATION,  NONE,  };

  RegisterNotificationInput._();

  factory RegisterNotificationInput([
    void updates(RegisterNotificationInputBuilder b),
  ]) = _$RegisterNotificationInput;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(RegisterNotificationInputBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<RegisterNotificationInput> get serializer =>
      _$RegisterNotificationInputSerializer();
}

class _$RegisterNotificationInputSerializer
    implements PrimitiveSerializer<RegisterNotificationInput> {
  @override
  final Iterable<Type> types = const [
    RegisterNotificationInput,
    _$RegisterNotificationInput,
  ];

  @override
  final String wireName = r'RegisterNotificationInput';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    RegisterNotificationInput object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    yield r'myDid';
    yield serializers.serialize(
      object.myDid,
      specifiedType: const FullType(String),
    );
    yield r'theirDid';
    yield serializers.serialize(
      object.theirDid,
      specifiedType: const FullType(String),
    );
    yield r'deviceToken';
    yield serializers.serialize(
      object.deviceToken,
      specifiedType: const FullType(String),
    );
    yield r'platformType';
    yield serializers.serialize(
      object.platformType,
      specifiedType: const FullType(RegisterNotificationInputPlatformTypeEnum),
    );
  }

  @override
  Object serialize(
    Serializers serializers,
    RegisterNotificationInput object, {
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
    required RegisterNotificationInputBuilder result,
    required List<Object?> unhandled,
  }) {
    for (var i = 0; i < serializedList.length; i += 2) {
      final key = serializedList[i] as String;
      final value = serializedList[i + 1];
      switch (key) {
        case r'myDid':
          final valueDes =
              serializers.deserialize(
                    value,
                    specifiedType: const FullType(String),
                  )
                  as String;
          result.myDid = valueDes;
          break;
        case r'theirDid':
          final valueDes =
              serializers.deserialize(
                    value,
                    specifiedType: const FullType(String),
                  )
                  as String;
          result.theirDid = valueDes;
          break;
        case r'deviceToken':
          final valueDes =
              serializers.deserialize(
                    value,
                    specifiedType: const FullType(String),
                  )
                  as String;
          result.deviceToken = valueDes;
          break;
        case r'platformType':
          final valueDes =
              serializers.deserialize(
                    value,
                    specifiedType: const FullType(
                      RegisterNotificationInputPlatformTypeEnum,
                    ),
                  )
                  as RegisterNotificationInputPlatformTypeEnum;
          result.platformType = valueDes;
          break;
        default:
          unhandled.add(key);
          unhandled.add(value);
          break;
      }
    }
  }

  @override
  RegisterNotificationInput deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = RegisterNotificationInputBuilder();
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

class RegisterNotificationInputPlatformTypeEnum extends EnumClass {
  /// Platform type for sending notification.
  @BuiltValueEnumConst(wireName: r'DIDCOMM')
  static const RegisterNotificationInputPlatformTypeEnum DIDCOMM =
      _$registerNotificationInputPlatformTypeEnum_DIDCOMM;

  /// Platform type for sending notification.
  @BuiltValueEnumConst(wireName: r'PUSH_NOTIFICATION')
  static const RegisterNotificationInputPlatformTypeEnum PUSH_NOTIFICATION =
      _$registerNotificationInputPlatformTypeEnum_PUSH_NOTIFICATION;

  /// Platform type for sending notification.
  @BuiltValueEnumConst(wireName: r'NONE')
  static const RegisterNotificationInputPlatformTypeEnum NONE =
      _$registerNotificationInputPlatformTypeEnum_NONE;

  static Serializer<RegisterNotificationInputPlatformTypeEnum> get serializer =>
      _$registerNotificationInputPlatformTypeEnumSerializer;

  const RegisterNotificationInputPlatformTypeEnum._(String name) : super(name);

  static BuiltSet<RegisterNotificationInputPlatformTypeEnum> get values =>
      _$registerNotificationInputPlatformTypeEnumValues;
  static RegisterNotificationInputPlatformTypeEnum valueOf(String name) =>
      _$registerNotificationInputPlatformTypeEnumValueOf(name);
}
