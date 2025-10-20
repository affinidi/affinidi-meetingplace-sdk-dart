//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_collection/built_collection.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'get_pending_notifications_input.g.dart';

/// GetPendingNotificationsInput
///
/// Properties:
/// * [deviceToken] - The device token for push notification when the offer is processed.  Maximum length of 2048 characters.
/// * [platformType] - Platform type for sending notification.
@BuiltValue()
abstract class GetPendingNotificationsInput
    implements
        Built<GetPendingNotificationsInput,
            GetPendingNotificationsInputBuilder> {
  /// The device token for push notification when the offer is processed.  Maximum length of 2048 characters.
  @BuiltValueField(wireName: r'deviceToken')
  String get deviceToken;

  /// Platform type for sending notification.
  @BuiltValueField(wireName: r'platformType')
  GetPendingNotificationsInputPlatformTypeEnum get platformType;
  // enum platformTypeEnum {  DIDCOMM,  PUSH_NOTIFICATION,  NONE,  };

  GetPendingNotificationsInput._();

  factory GetPendingNotificationsInput(
          [void updates(GetPendingNotificationsInputBuilder b)]) =
      _$GetPendingNotificationsInput;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(GetPendingNotificationsInputBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<GetPendingNotificationsInput> get serializer =>
      _$GetPendingNotificationsInputSerializer();
}

class _$GetPendingNotificationsInputSerializer
    implements PrimitiveSerializer<GetPendingNotificationsInput> {
  @override
  final Iterable<Type> types = const [
    GetPendingNotificationsInput,
    _$GetPendingNotificationsInput
  ];

  @override
  final String wireName = r'GetPendingNotificationsInput';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    GetPendingNotificationsInput object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    yield r'deviceToken';
    yield serializers.serialize(
      object.deviceToken,
      specifiedType: const FullType(String),
    );
    yield r'platformType';
    yield serializers.serialize(
      object.platformType,
      specifiedType:
          const FullType(GetPendingNotificationsInputPlatformTypeEnum),
    );
  }

  @override
  Object serialize(
    Serializers serializers,
    GetPendingNotificationsInput object, {
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
    required GetPendingNotificationsInputBuilder result,
    required List<Object?> unhandled,
  }) {
    for (var i = 0; i < serializedList.length; i += 2) {
      final key = serializedList[i] as String;
      final value = serializedList[i + 1];
      switch (key) {
        case r'deviceToken':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.deviceToken = valueDes;
          break;
        case r'platformType':
          final valueDes = serializers.deserialize(
            value,
            specifiedType:
                const FullType(GetPendingNotificationsInputPlatformTypeEnum),
          ) as GetPendingNotificationsInputPlatformTypeEnum;
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
  GetPendingNotificationsInput deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = GetPendingNotificationsInputBuilder();
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

class GetPendingNotificationsInputPlatformTypeEnum extends EnumClass {
  /// Platform type for sending notification.
  @BuiltValueEnumConst(wireName: r'DIDCOMM')
  static const GetPendingNotificationsInputPlatformTypeEnum DIDCOMM =
      _$getPendingNotificationsInputPlatformTypeEnum_DIDCOMM;

  /// Platform type for sending notification.
  @BuiltValueEnumConst(wireName: r'PUSH_NOTIFICATION')
  static const GetPendingNotificationsInputPlatformTypeEnum PUSH_NOTIFICATION =
      _$getPendingNotificationsInputPlatformTypeEnum_PUSH_NOTIFICATION;

  /// Platform type for sending notification.
  @BuiltValueEnumConst(wireName: r'NONE')
  static const GetPendingNotificationsInputPlatformTypeEnum NONE =
      _$getPendingNotificationsInputPlatformTypeEnum_NONE;

  static Serializer<GetPendingNotificationsInputPlatformTypeEnum>
      get serializer =>
          _$getPendingNotificationsInputPlatformTypeEnumSerializer;

  const GetPendingNotificationsInputPlatformTypeEnum._(String name)
      : super(name);

  static BuiltSet<GetPendingNotificationsInputPlatformTypeEnum> get values =>
      _$getPendingNotificationsInputPlatformTypeEnumValues;
  static GetPendingNotificationsInputPlatformTypeEnum valueOf(String name) =>
      _$getPendingNotificationsInputPlatformTypeEnumValueOf(name);
}
