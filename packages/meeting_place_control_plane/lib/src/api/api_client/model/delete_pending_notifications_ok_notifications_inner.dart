//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'delete_pending_notifications_ok_notifications_inner.g.dart';

/// DeletePendingNotificationsOKNotificationsInner
///
/// Properties:
/// * [id] - The notification identifier
/// * [offerLink] - offer link for the notification
/// * [deviceHash] - Hash of the device identifier/owner
/// * [did] - The consumer did that registered the device, and confirms ownership of the deviceId
/// * [payload] - The raw payload that was sent via push notification
@BuiltValue()
abstract class DeletePendingNotificationsOKNotificationsInner
    implements
        Built<
          DeletePendingNotificationsOKNotificationsInner,
          DeletePendingNotificationsOKNotificationsInnerBuilder
        > {
  /// The notification identifier
  @BuiltValueField(wireName: r'id')
  String? get id;

  /// offer link for the notification
  @BuiltValueField(wireName: r'offerLink')
  String? get offerLink;

  /// Hash of the device identifier/owner
  @BuiltValueField(wireName: r'deviceHash')
  String? get deviceHash;

  /// The consumer did that registered the device, and confirms ownership of the deviceId
  @BuiltValueField(wireName: r'did')
  String? get did;

  /// The raw payload that was sent via push notification
  @BuiltValueField(wireName: r'payload')
  String? get payload;

  DeletePendingNotificationsOKNotificationsInner._();

  factory DeletePendingNotificationsOKNotificationsInner([
    void updates(DeletePendingNotificationsOKNotificationsInnerBuilder b),
  ]) = _$DeletePendingNotificationsOKNotificationsInner;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(
    DeletePendingNotificationsOKNotificationsInnerBuilder b,
  ) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<DeletePendingNotificationsOKNotificationsInner>
  get serializer =>
      _$DeletePendingNotificationsOKNotificationsInnerSerializer();
}

class _$DeletePendingNotificationsOKNotificationsInnerSerializer
    implements
        PrimitiveSerializer<DeletePendingNotificationsOKNotificationsInner> {
  @override
  final Iterable<Type> types = const [
    DeletePendingNotificationsOKNotificationsInner,
    _$DeletePendingNotificationsOKNotificationsInner,
  ];

  @override
  final String wireName = r'DeletePendingNotificationsOKNotificationsInner';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    DeletePendingNotificationsOKNotificationsInner object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    if (object.id != null) {
      yield r'id';
      yield serializers.serialize(
        object.id,
        specifiedType: const FullType(String),
      );
    }
    if (object.offerLink != null) {
      yield r'offerLink';
      yield serializers.serialize(
        object.offerLink,
        specifiedType: const FullType(String),
      );
    }
    if (object.deviceHash != null) {
      yield r'deviceHash';
      yield serializers.serialize(
        object.deviceHash,
        specifiedType: const FullType(String),
      );
    }
    if (object.did != null) {
      yield r'did';
      yield serializers.serialize(
        object.did,
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
  }

  @override
  Object serialize(
    Serializers serializers,
    DeletePendingNotificationsOKNotificationsInner object, {
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
    required DeletePendingNotificationsOKNotificationsInnerBuilder result,
    required List<Object?> unhandled,
  }) {
    for (var i = 0; i < serializedList.length; i += 2) {
      final key = serializedList[i] as String;
      final value = serializedList[i + 1];
      switch (key) {
        case r'id':
          final valueDes =
              serializers.deserialize(
                    value,
                    specifiedType: const FullType(String),
                  )
                  as String;
          result.id = valueDes;
          break;
        case r'offerLink':
          final valueDes =
              serializers.deserialize(
                    value,
                    specifiedType: const FullType(String),
                  )
                  as String;
          result.offerLink = valueDes;
          break;
        case r'deviceHash':
          final valueDes =
              serializers.deserialize(
                    value,
                    specifiedType: const FullType(String),
                  )
                  as String;
          result.deviceHash = valueDes;
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
        case r'payload':
          final valueDes =
              serializers.deserialize(
                    value,
                    specifiedType: const FullType(String),
                  )
                  as String;
          result.payload = valueDes;
          break;
        default:
          unhandled.add(key);
          unhandled.add(value);
          break;
      }
    }
  }

  @override
  DeletePendingNotificationsOKNotificationsInner deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = DeletePendingNotificationsOKNotificationsInnerBuilder();
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
