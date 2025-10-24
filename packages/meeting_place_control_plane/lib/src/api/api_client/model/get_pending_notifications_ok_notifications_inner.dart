//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'get_pending_notifications_ok_notifications_inner.g.dart';

/// GetPendingNotificationsOKNotificationsInner
///
/// Properties:
/// * [id] - The notification identifier
/// * [type] - The type of notification
/// * [payload] - The raw payload that was sent via push notification
/// * [notificationDate] - date and time the refresh token expires in ISO-8601 format
@BuiltValue()
abstract class GetPendingNotificationsOKNotificationsInner
    implements
        Built<GetPendingNotificationsOKNotificationsInner,
            GetPendingNotificationsOKNotificationsInnerBuilder> {
  /// The notification identifier
  @BuiltValueField(wireName: r'id')
  String? get id;

  /// The type of notification
  @BuiltValueField(wireName: r'type')
  String? get type;

  /// The raw payload that was sent via push notification
  @BuiltValueField(wireName: r'payload')
  String? get payload;

  /// date and time the refresh token expires in ISO-8601 format
  @BuiltValueField(wireName: r'notificationDate')
  String? get notificationDate;

  GetPendingNotificationsOKNotificationsInner._();

  factory GetPendingNotificationsOKNotificationsInner(
          [void updates(
              GetPendingNotificationsOKNotificationsInnerBuilder b)]) =
      _$GetPendingNotificationsOKNotificationsInner;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(GetPendingNotificationsOKNotificationsInnerBuilder b) =>
      b;

  @BuiltValueSerializer(custom: true)
  static Serializer<GetPendingNotificationsOKNotificationsInner>
      get serializer =>
          _$GetPendingNotificationsOKNotificationsInnerSerializer();
}

class _$GetPendingNotificationsOKNotificationsInnerSerializer
    implements
        PrimitiveSerializer<GetPendingNotificationsOKNotificationsInner> {
  @override
  final Iterable<Type> types = const [
    GetPendingNotificationsOKNotificationsInner,
    _$GetPendingNotificationsOKNotificationsInner
  ];

  @override
  final String wireName = r'GetPendingNotificationsOKNotificationsInner';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    GetPendingNotificationsOKNotificationsInner object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    if (object.id != null) {
      yield r'id';
      yield serializers.serialize(
        object.id,
        specifiedType: const FullType(String),
      );
    }
    if (object.type != null) {
      yield r'type';
      yield serializers.serialize(
        object.type,
        specifiedType: const FullType(String),
      );
    }
    if (object.payload != null) {
      yield r'payload';
      yield serializers.serialize(
        object.payload,
        specifiedType: const FullType(String),
      );
    }
    if (object.notificationDate != null) {
      yield r'notificationDate';
      yield serializers.serialize(
        object.notificationDate,
        specifiedType: const FullType(String),
      );
    }
  }

  @override
  Object serialize(
    Serializers serializers,
    GetPendingNotificationsOKNotificationsInner object, {
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
    required GetPendingNotificationsOKNotificationsInnerBuilder result,
    required List<Object?> unhandled,
  }) {
    for (var i = 0; i < serializedList.length; i += 2) {
      final key = serializedList[i] as String;
      final value = serializedList[i + 1];
      switch (key) {
        case r'id':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.id = valueDes;
          break;
        case r'type':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.type = valueDes;
          break;
        case r'payload':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.payload = valueDes;
          break;
        case r'notificationDate':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.notificationDate = valueDes;
          break;
        default:
          unhandled.add(key);
          unhandled.add(value);
          break;
      }
    }
  }

  @override
  GetPendingNotificationsOKNotificationsInner deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = GetPendingNotificationsOKNotificationsInnerBuilder();
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
