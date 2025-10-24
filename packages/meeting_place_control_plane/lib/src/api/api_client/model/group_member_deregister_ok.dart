//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'group_member_deregister_ok.g.dart';

/// GroupMemberDeregisterOK
///
/// Properties:
/// * [status]
/// * [message]
@BuiltValue()
abstract class GroupMemberDeregisterOK
    implements Built<GroupMemberDeregisterOK, GroupMemberDeregisterOKBuilder> {
  @BuiltValueField(wireName: r'status')
  String? get status;

  @BuiltValueField(wireName: r'message')
  String? get message;

  GroupMemberDeregisterOK._();

  factory GroupMemberDeregisterOK(
          [void updates(GroupMemberDeregisterOKBuilder b)]) =
      _$GroupMemberDeregisterOK;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(GroupMemberDeregisterOKBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<GroupMemberDeregisterOK> get serializer =>
      _$GroupMemberDeregisterOKSerializer();
}

class _$GroupMemberDeregisterOKSerializer
    implements PrimitiveSerializer<GroupMemberDeregisterOK> {
  @override
  final Iterable<Type> types = const [
    GroupMemberDeregisterOK,
    _$GroupMemberDeregisterOK
  ];

  @override
  final String wireName = r'GroupMemberDeregisterOK';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    GroupMemberDeregisterOK object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    if (object.status != null) {
      yield r'status';
      yield serializers.serialize(
        object.status,
        specifiedType: const FullType(String),
      );
    }
    if (object.message != null) {
      yield r'message';
      yield serializers.serialize(
        object.message,
        specifiedType: const FullType(String),
      );
    }
  }

  @override
  Object serialize(
    Serializers serializers,
    GroupMemberDeregisterOK object, {
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
    required GroupMemberDeregisterOKBuilder result,
    required List<Object?> unhandled,
  }) {
    for (var i = 0; i < serializedList.length; i += 2) {
      final key = serializedList[i] as String;
      final value = serializedList[i + 1];
      switch (key) {
        case r'status':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.status = valueDes;
          break;
        case r'message':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.message = valueDes;
          break;
        default:
          unhandled.add(key);
          unhandled.add(value);
          break;
      }
    }
  }

  @override
  GroupMemberDeregisterOK deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = GroupMemberDeregisterOKBuilder();
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
