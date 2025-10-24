//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import '../model/get_pending_notifications_ok_notifications_inner.dart';
import 'package:built_collection/built_collection.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'get_pending_notifications_ok.g.dart';

/// GetPendingNotificationsOK
///
/// Properties:
/// * [notifications]
@BuiltValue()
abstract class GetPendingNotificationsOK
    implements
        Built<GetPendingNotificationsOK, GetPendingNotificationsOKBuilder> {
  @BuiltValueField(wireName: r'notifications')
  BuiltList<GetPendingNotificationsOKNotificationsInner>? get notifications;

  GetPendingNotificationsOK._();

  factory GetPendingNotificationsOK([
    void updates(GetPendingNotificationsOKBuilder b),
  ]) = _$GetPendingNotificationsOK;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(GetPendingNotificationsOKBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<GetPendingNotificationsOK> get serializer =>
      _$GetPendingNotificationsOKSerializer();
}

class _$GetPendingNotificationsOKSerializer
    implements PrimitiveSerializer<GetPendingNotificationsOK> {
  @override
  final Iterable<Type> types = const [
    GetPendingNotificationsOK,
    _$GetPendingNotificationsOK,
  ];

  @override
  final String wireName = r'GetPendingNotificationsOK';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    GetPendingNotificationsOK object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    if (object.notifications != null) {
      yield r'notifications';
      yield serializers.serialize(
        object.notifications,
        specifiedType: const FullType(BuiltList, [
          FullType(GetPendingNotificationsOKNotificationsInner),
        ]),
      );
    }
  }

  @override
  Object serialize(
    Serializers serializers,
    GetPendingNotificationsOK object, {
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
    required GetPendingNotificationsOKBuilder result,
    required List<Object?> unhandled,
  }) {
    for (var i = 0; i < serializedList.length; i += 2) {
      final key = serializedList[i] as String;
      final value = serializedList[i + 1];
      switch (key) {
        case r'notifications':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(BuiltList, [
              FullType(GetPendingNotificationsOKNotificationsInner),
            ]),
          ) as BuiltList<GetPendingNotificationsOKNotificationsInner>;
          result.notifications.replace(valueDes);
          break;
        default:
          unhandled.add(key);
          unhandled.add(value);
          break;
      }
    }
  }

  @override
  GetPendingNotificationsOK deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = GetPendingNotificationsOKBuilder();
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
