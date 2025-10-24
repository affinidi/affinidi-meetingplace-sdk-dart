//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_collection/built_collection.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'delete_pending_notifications_input.g.dart';

/// DeletePendingNotificationsInput
///
/// Properties:
/// * [notificationIds]
/// * [deviceToken] - The device token for push notification when the offer is processed.  Maximum length of 2048 characters.
/// * [platformType] - Platform type for sending notification.
@BuiltValue()
abstract class DeletePendingNotificationsInput
    implements
        Built<DeletePendingNotificationsInput,
            DeletePendingNotificationsInputBuilder> {
  @BuiltValueField(wireName: r'notificationIds')
  BuiltList<String> get notificationIds;

  /// The device token for push notification when the offer is processed.  Maximum length of 2048 characters.
  @BuiltValueField(wireName: r'deviceToken')
  String get deviceToken;

  /// Platform type for sending notification.
  @BuiltValueField(wireName: r'platformType')
  DeletePendingNotificationsInputPlatformTypeEnum get platformType;
  // enum platformTypeEnum {  DIDCOMM,  PUSH_NOTIFICATION,  NONE,  };

  DeletePendingNotificationsInput._();

  factory DeletePendingNotificationsInput(
          [void updates(DeletePendingNotificationsInputBuilder b)]) =
      _$DeletePendingNotificationsInput;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(DeletePendingNotificationsInputBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<DeletePendingNotificationsInput> get serializer =>
      _$DeletePendingNotificationsInputSerializer();
}

class _$DeletePendingNotificationsInputSerializer
    implements PrimitiveSerializer<DeletePendingNotificationsInput> {
  @override
  final Iterable<Type> types = const [
    DeletePendingNotificationsInput,
    _$DeletePendingNotificationsInput
  ];

  @override
  final String wireName = r'DeletePendingNotificationsInput';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    DeletePendingNotificationsInput object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    yield r'notificationIds';
    yield serializers.serialize(
      object.notificationIds,
      specifiedType: const FullType(BuiltList, [FullType(String)]),
    );
    yield r'deviceToken';
    yield serializers.serialize(
      object.deviceToken,
      specifiedType: const FullType(String),
    );
    yield r'platformType';
    yield serializers.serialize(
      object.platformType,
      specifiedType:
          const FullType(DeletePendingNotificationsInputPlatformTypeEnum),
    );
  }

  @override
  Object serialize(
    Serializers serializers,
    DeletePendingNotificationsInput object, {
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
    required DeletePendingNotificationsInputBuilder result,
    required List<Object?> unhandled,
  }) {
    for (var i = 0; i < serializedList.length; i += 2) {
      final key = serializedList[i] as String;
      final value = serializedList[i + 1];
      switch (key) {
        case r'notificationIds':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(BuiltList, [FullType(String)]),
          ) as BuiltList<String>;
          result.notificationIds.replace(valueDes);
          break;
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
                const FullType(DeletePendingNotificationsInputPlatformTypeEnum),
          ) as DeletePendingNotificationsInputPlatformTypeEnum;
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
  DeletePendingNotificationsInput deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = DeletePendingNotificationsInputBuilder();
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

class DeletePendingNotificationsInputPlatformTypeEnum extends EnumClass {
  /// Platform type for sending notification.
  @BuiltValueEnumConst(wireName: r'DIDCOMM')
  static const DeletePendingNotificationsInputPlatformTypeEnum DIDCOMM =
      _$deletePendingNotificationsInputPlatformTypeEnum_DIDCOMM;

  /// Platform type for sending notification.
  @BuiltValueEnumConst(wireName: r'PUSH_NOTIFICATION')
  static const DeletePendingNotificationsInputPlatformTypeEnum
      PUSH_NOTIFICATION =
      _$deletePendingNotificationsInputPlatformTypeEnum_PUSH_NOTIFICATION;

  /// Platform type for sending notification.
  @BuiltValueEnumConst(wireName: r'NONE')
  static const DeletePendingNotificationsInputPlatformTypeEnum NONE =
      _$deletePendingNotificationsInputPlatformTypeEnum_NONE;

  static Serializer<DeletePendingNotificationsInputPlatformTypeEnum>
      get serializer =>
          _$deletePendingNotificationsInputPlatformTypeEnumSerializer;

  const DeletePendingNotificationsInputPlatformTypeEnum._(String name)
      : super(name);

  static BuiltSet<DeletePendingNotificationsInputPlatformTypeEnum> get values =>
      _$deletePendingNotificationsInputPlatformTypeEnumValues;
  static DeletePendingNotificationsInputPlatformTypeEnum valueOf(String name) =>
      _$deletePendingNotificationsInputPlatformTypeEnumValueOf(name);
}
