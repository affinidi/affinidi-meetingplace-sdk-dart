//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'group_add_member_ok.g.dart';

/// GroupAddMemberOK
///
/// Properties:
/// * [status]
/// * [message]
@BuiltValue()
abstract class GroupAddMemberOK
    implements Built<GroupAddMemberOK, GroupAddMemberOKBuilder> {
  @BuiltValueField(wireName: r'status')
  String? get status;

  @BuiltValueField(wireName: r'message')
  String? get message;

  GroupAddMemberOK._();

  factory GroupAddMemberOK([void updates(GroupAddMemberOKBuilder b)]) =
      _$GroupAddMemberOK;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(GroupAddMemberOKBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<GroupAddMemberOK> get serializer =>
      _$GroupAddMemberOKSerializer();
}

class _$GroupAddMemberOKSerializer
    implements PrimitiveSerializer<GroupAddMemberOK> {
  @override
  final Iterable<Type> types = const [GroupAddMemberOK, _$GroupAddMemberOK];

  @override
  final String wireName = r'GroupAddMemberOK';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    GroupAddMemberOK object, {
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
    GroupAddMemberOK object, {
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
    required GroupAddMemberOKBuilder result,
    required List<Object?> unhandled,
  }) {
    for (var i = 0; i < serializedList.length; i += 2) {
      final key = serializedList[i] as String;
      final value = serializedList[i + 1];
      switch (key) {
        case r'status':
          final valueDes =
              serializers.deserialize(
                    value,
                    specifiedType: const FullType(String),
                  )
                  as String;
          result.status = valueDes;
          break;
        case r'message':
          final valueDes =
              serializers.deserialize(
                    value,
                    specifiedType: const FullType(String),
                  )
                  as String;
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
  GroupAddMemberOK deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = GroupAddMemberOKBuilder();
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
