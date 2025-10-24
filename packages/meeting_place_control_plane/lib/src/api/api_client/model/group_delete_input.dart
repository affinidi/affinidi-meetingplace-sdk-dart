//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'group_delete_input.g.dart';

/// List of required parameters to delete a group chat.
///
/// Properties:
/// * [groupId] - Unique identifier of the group chat to delete.
/// * [messageToRelay] - Message to send to the group chat members upon deletion.
@BuiltValue()
abstract class GroupDeleteInput
    implements Built<GroupDeleteInput, GroupDeleteInputBuilder> {
  /// Unique identifier of the group chat to delete.
  @BuiltValueField(wireName: r'groupId')
  String get groupId;

  /// Message to send to the group chat members upon deletion.
  @BuiltValueField(wireName: r'messageToRelay')
  String get messageToRelay;

  GroupDeleteInput._();

  factory GroupDeleteInput([void updates(GroupDeleteInputBuilder b)]) =
      _$GroupDeleteInput;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(GroupDeleteInputBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<GroupDeleteInput> get serializer =>
      _$GroupDeleteInputSerializer();
}

class _$GroupDeleteInputSerializer
    implements PrimitiveSerializer<GroupDeleteInput> {
  @override
  final Iterable<Type> types = const [GroupDeleteInput, _$GroupDeleteInput];

  @override
  final String wireName = r'GroupDeleteInput';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    GroupDeleteInput object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    yield r'groupId';
    yield serializers.serialize(
      object.groupId,
      specifiedType: const FullType(String),
    );
    yield r'messageToRelay';
    yield serializers.serialize(
      object.messageToRelay,
      specifiedType: const FullType(String),
    );
  }

  @override
  Object serialize(
    Serializers serializers,
    GroupDeleteInput object, {
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
    required GroupDeleteInputBuilder result,
    required List<Object?> unhandled,
  }) {
    for (var i = 0; i < serializedList.length; i += 2) {
      final key = serializedList[i] as String;
      final value = serializedList[i + 1];
      switch (key) {
        case r'groupId':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.groupId = valueDes;
          break;
        case r'messageToRelay':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.messageToRelay = valueDes;
          break;
        default:
          unhandled.add(key);
          unhandled.add(value);
          break;
      }
    }
  }

  @override
  GroupDeleteInput deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = GroupDeleteInputBuilder();
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
