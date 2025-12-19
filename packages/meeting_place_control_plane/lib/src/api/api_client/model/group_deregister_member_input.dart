//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'group_deregister_member_input.g.dart';

/// List of required and optional parameters to remove a member from the group chat.
///
/// Properties:
/// * [memberDid] - Decentralised Identifier (DID) of the member to remove.
/// * [groupId] - The unique identifier of the group chat to remove the member from.
/// * [messageToRelay] - An encrypted DIDComm message to send to the remaining group chat members in base64 format.
@BuiltValue()
abstract class GroupDeregisterMemberInput
    implements
        Built<GroupDeregisterMemberInput, GroupDeregisterMemberInputBuilder> {
  /// Decentralised Identifier (DID) of the member to remove.
  @BuiltValueField(wireName: r'memberDid')
  String get memberDid;

  /// The unique identifier of the group chat to remove the member from.
  @BuiltValueField(wireName: r'groupId')
  String get groupId;

  /// An encrypted DIDComm message to send to the remaining group chat members in base64 format.
  @BuiltValueField(wireName: r'messageToRelay')
  String? get messageToRelay;

  GroupDeregisterMemberInput._();

  factory GroupDeregisterMemberInput([
    void updates(GroupDeregisterMemberInputBuilder b),
  ]) = _$GroupDeregisterMemberInput;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(GroupDeregisterMemberInputBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<GroupDeregisterMemberInput> get serializer =>
      _$GroupDeregisterMemberInputSerializer();
}

class _$GroupDeregisterMemberInputSerializer
    implements PrimitiveSerializer<GroupDeregisterMemberInput> {
  @override
  final Iterable<Type> types = const [
    GroupDeregisterMemberInput,
    _$GroupDeregisterMemberInput,
  ];

  @override
  final String wireName = r'GroupDeregisterMemberInput';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    GroupDeregisterMemberInput object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    yield r'memberDid';
    yield serializers.serialize(
      object.memberDid,
      specifiedType: const FullType(String),
    );
    yield r'groupId';
    yield serializers.serialize(
      object.groupId,
      specifiedType: const FullType(String),
    );
    if (object.messageToRelay != null) {
      yield r'messageToRelay';
      yield serializers.serialize(
        object.messageToRelay,
        specifiedType: const FullType(String),
      );
    }
  }

  @override
  Object serialize(
    Serializers serializers,
    GroupDeregisterMemberInput object, {
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
    required GroupDeregisterMemberInputBuilder result,
    required List<Object?> unhandled,
  }) {
    for (var i = 0; i < serializedList.length; i += 2) {
      final key = serializedList[i] as String;
      final value = serializedList[i + 1];
      switch (key) {
        case r'memberDid':
          final valueDes =
              serializers.deserialize(
                    value,
                    specifiedType: const FullType(String),
                  )
                  as String;
          result.memberDid = valueDes;
          break;
        case r'groupId':
          final valueDes =
              serializers.deserialize(
                    value,
                    specifiedType: const FullType(String),
                  )
                  as String;
          result.groupId = valueDes;
          break;
        case r'messageToRelay':
          final valueDes =
              serializers.deserialize(
                    value,
                    specifiedType: const FullType(String),
                  )
                  as String;
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
  GroupDeregisterMemberInput deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = GroupDeregisterMemberInputBuilder();
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
