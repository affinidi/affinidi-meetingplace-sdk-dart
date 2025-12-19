//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_collection/built_collection.dart';
import '../model/delete_pending_notifications_ok_notifications_inner.dart';
import 'package:built_value/json_object.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'delete_pending_notifications_ok.g.dart';

/// DeletePendingNotificationsOK
///
/// Properties:
/// * [deletedIds]
/// * [notifications]
/// * [examples]
@BuiltValue()
abstract class DeletePendingNotificationsOK
    implements
        Built<
          DeletePendingNotificationsOK,
          DeletePendingNotificationsOKBuilder
        > {
  @BuiltValueField(wireName: r'deletedIds')
  BuiltList<String>? get deletedIds;

  @BuiltValueField(wireName: r'notifications')
  BuiltList<DeletePendingNotificationsOKNotificationsInner>? get notifications;

  @BuiltValueField(wireName: r'examples')
  JsonObject? get examples;

  DeletePendingNotificationsOK._();

  factory DeletePendingNotificationsOK([
    void updates(DeletePendingNotificationsOKBuilder b),
  ]) = _$DeletePendingNotificationsOK;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(DeletePendingNotificationsOKBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<DeletePendingNotificationsOK> get serializer =>
      _$DeletePendingNotificationsOKSerializer();
}

class _$DeletePendingNotificationsOKSerializer
    implements PrimitiveSerializer<DeletePendingNotificationsOK> {
  @override
  final Iterable<Type> types = const [
    DeletePendingNotificationsOK,
    _$DeletePendingNotificationsOK,
  ];

  @override
  final String wireName = r'DeletePendingNotificationsOK';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    DeletePendingNotificationsOK object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    if (object.deletedIds != null) {
      yield r'deletedIds';
      yield serializers.serialize(
        object.deletedIds,
        specifiedType: const FullType(BuiltList, [FullType(String)]),
      );
    }
    if (object.notifications != null) {
      yield r'notifications';
      yield serializers.serialize(
        object.notifications,
        specifiedType: const FullType(BuiltList, [
          FullType(DeletePendingNotificationsOKNotificationsInner),
        ]),
      );
    }
    if (object.examples != null) {
      yield r'examples';
      yield serializers.serialize(
        object.examples,
        specifiedType: const FullType.nullable(JsonObject),
      );
    }
  }

  @override
  Object serialize(
    Serializers serializers,
    DeletePendingNotificationsOK object, {
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
    required DeletePendingNotificationsOKBuilder result,
    required List<Object?> unhandled,
  }) {
    for (var i = 0; i < serializedList.length; i += 2) {
      final key = serializedList[i] as String;
      final value = serializedList[i + 1];
      switch (key) {
        case r'deletedIds':
          final valueDes =
              serializers.deserialize(
                    value,
                    specifiedType: const FullType(BuiltList, [
                      FullType(String),
                    ]),
                  )
                  as BuiltList<String>;
          result.deletedIds.replace(valueDes);
          break;
        case r'notifications':
          final valueDes =
              serializers.deserialize(
                    value,
                    specifiedType: const FullType(BuiltList, [
                      FullType(DeletePendingNotificationsOKNotificationsInner),
                    ]),
                  )
                  as BuiltList<DeletePendingNotificationsOKNotificationsInner>;
          result.notifications.replace(valueDes);
          break;
        case r'examples':
          final valueDes =
              serializers.deserialize(
                    value,
                    specifiedType: const FullType.nullable(JsonObject),
                  )
                  as JsonObject?;
          if (valueDes == null) continue;
          result.examples = valueDes;
          break;
        default:
          unhandled.add(key);
          unhandled.add(value);
          break;
      }
    }
  }

  @override
  DeletePendingNotificationsOK deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = DeletePendingNotificationsOKBuilder();
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
