//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_collection/built_collection.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'register_device_input.g.dart';

/// RegisterDeviceInput
///
/// Properties:
/// * [platformType] - Platform type for sending notification.
/// * [deviceToken] - A unique, platform-specific device token used to register the device. Maximum length of 2048 characters.
@BuiltValue()
abstract class RegisterDeviceInput
    implements Built<RegisterDeviceInput, RegisterDeviceInputBuilder> {
  /// Platform type for sending notification.
  @BuiltValueField(wireName: r'platformType')
  RegisterDeviceInputPlatformTypeEnum get platformType;
  // enum platformTypeEnum {  DIDCOMM,  PUSH_NOTIFICATION,  NONE,  };

  /// A unique, platform-specific device token used to register the device. Maximum length of 2048 characters.
  @BuiltValueField(wireName: r'deviceToken')
  String get deviceToken;

  RegisterDeviceInput._();

  factory RegisterDeviceInput([void updates(RegisterDeviceInputBuilder b)]) =
      _$RegisterDeviceInput;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(RegisterDeviceInputBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<RegisterDeviceInput> get serializer =>
      _$RegisterDeviceInputSerializer();
}

class _$RegisterDeviceInputSerializer
    implements PrimitiveSerializer<RegisterDeviceInput> {
  @override
  final Iterable<Type> types = const [
    RegisterDeviceInput,
    _$RegisterDeviceInput,
  ];

  @override
  final String wireName = r'RegisterDeviceInput';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    RegisterDeviceInput object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    yield r'platformType';
    yield serializers.serialize(
      object.platformType,
      specifiedType: const FullType(RegisterDeviceInputPlatformTypeEnum),
    );
    yield r'deviceToken';
    yield serializers.serialize(
      object.deviceToken,
      specifiedType: const FullType(String),
    );
  }

  @override
  Object serialize(
    Serializers serializers,
    RegisterDeviceInput object, {
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
    required RegisterDeviceInputBuilder result,
    required List<Object?> unhandled,
  }) {
    for (var i = 0; i < serializedList.length; i += 2) {
      final key = serializedList[i] as String;
      final value = serializedList[i + 1];
      switch (key) {
        case r'platformType':
          final valueDes =
              serializers.deserialize(
                    value,
                    specifiedType: const FullType(
                      RegisterDeviceInputPlatformTypeEnum,
                    ),
                  )
                  as RegisterDeviceInputPlatformTypeEnum;
          result.platformType = valueDes;
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
        default:
          unhandled.add(key);
          unhandled.add(value);
          break;
      }
    }
  }

  @override
  RegisterDeviceInput deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = RegisterDeviceInputBuilder();
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

class RegisterDeviceInputPlatformTypeEnum extends EnumClass {
  /// Platform type for sending notification.
  @BuiltValueEnumConst(wireName: r'DIDCOMM')
  static const RegisterDeviceInputPlatformTypeEnum DIDCOMM =
      _$registerDeviceInputPlatformTypeEnum_DIDCOMM;

  /// Platform type for sending notification.
  @BuiltValueEnumConst(wireName: r'PUSH_NOTIFICATION')
  static const RegisterDeviceInputPlatformTypeEnum PUSH_NOTIFICATION =
      _$registerDeviceInputPlatformTypeEnum_PUSH_NOTIFICATION;

  /// Platform type for sending notification.
  @BuiltValueEnumConst(wireName: r'NONE')
  static const RegisterDeviceInputPlatformTypeEnum NONE =
      _$registerDeviceInputPlatformTypeEnum_NONE;

  static Serializer<RegisterDeviceInputPlatformTypeEnum> get serializer =>
      _$registerDeviceInputPlatformTypeEnumSerializer;

  const RegisterDeviceInputPlatformTypeEnum._(String name) : super(name);

  static BuiltSet<RegisterDeviceInputPlatformTypeEnum> get values =>
      _$registerDeviceInputPlatformTypeEnumValues;
  static RegisterDeviceInputPlatformTypeEnum valueOf(String name) =>
      _$registerDeviceInputPlatformTypeEnumValueOf(name);
}
