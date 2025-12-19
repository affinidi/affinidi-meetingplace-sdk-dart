//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'group_add_member_input.g.dart';

/// GroupAddMemberInput
///
/// Properties:
/// * [mnemonic] - A unique phrase used to publish and identify the offer.
/// * [offerLink] - The offer link
/// * [groupId] - Unique identifier of the group chat to which the member will be added.
/// * [memberDid] - Decentralised Identifier (DID) of the member to add to the group chat.
/// * [acceptOfferAsDid] - Decentralised Identifier (DID) of when the member accepted the offer.
/// * [reencryptionKey] - The reencryption key for the group chat member.
/// * [publicKey] - The public key information of the group chat member.
/// * [contactCard] - The ContactCard of the member to add to the group chat.
@BuiltValue()
abstract class GroupAddMemberInput
    implements Built<GroupAddMemberInput, GroupAddMemberInputBuilder> {
  /// A unique phrase used to publish and identify the offer.
  @BuiltValueField(wireName: r'mnemonic')
  String get mnemonic;

  /// The offer link
  @BuiltValueField(wireName: r'offerLink')
  String get offerLink;

  /// Unique identifier of the group chat to which the member will be added.
  @BuiltValueField(wireName: r'groupId')
  String get groupId;

  /// Decentralised Identifier (DID) of the member to add to the group chat.
  @BuiltValueField(wireName: r'memberDid')
  String get memberDid;

  /// Decentralised Identifier (DID) of when the member accepted the offer.
  @BuiltValueField(wireName: r'acceptOfferAsDid')
  String get acceptOfferAsDid;

  /// The reencryption key for the group chat member.
  @BuiltValueField(wireName: r'reencryptionKey')
  String get reencryptionKey;

  /// The public key information of the group chat member.
  @BuiltValueField(wireName: r'publicKey')
  String get publicKey;

  /// The ContactCard of the member to add to the group chat.
  @BuiltValueField(wireName: r'contactCard')
  String get contactCard;

  GroupAddMemberInput._();

  factory GroupAddMemberInput([void updates(GroupAddMemberInputBuilder b)]) =
      _$GroupAddMemberInput;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(GroupAddMemberInputBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<GroupAddMemberInput> get serializer =>
      _$GroupAddMemberInputSerializer();
}

class _$GroupAddMemberInputSerializer
    implements PrimitiveSerializer<GroupAddMemberInput> {
  @override
  final Iterable<Type> types = const [
    GroupAddMemberInput,
    _$GroupAddMemberInput,
  ];

  @override
  final String wireName = r'GroupAddMemberInput';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    GroupAddMemberInput object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    yield r'mnemonic';
    yield serializers.serialize(
      object.mnemonic,
      specifiedType: const FullType(String),
    );
    yield r'offerLink';
    yield serializers.serialize(
      object.offerLink,
      specifiedType: const FullType(String),
    );
    yield r'groupId';
    yield serializers.serialize(
      object.groupId,
      specifiedType: const FullType(String),
    );
    yield r'memberDid';
    yield serializers.serialize(
      object.memberDid,
      specifiedType: const FullType(String),
    );
    yield r'acceptOfferAsDid';
    yield serializers.serialize(
      object.acceptOfferAsDid,
      specifiedType: const FullType(String),
    );
    yield r'reencryptionKey';
    yield serializers.serialize(
      object.reencryptionKey,
      specifiedType: const FullType(String),
    );
    yield r'publicKey';
    yield serializers.serialize(
      object.publicKey,
      specifiedType: const FullType(String),
    );
    yield r'contactCard';
    yield serializers.serialize(
      object.contactCard,
      specifiedType: const FullType(String),
    );
  }

  @override
  Object serialize(
    Serializers serializers,
    GroupAddMemberInput object, {
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
    required GroupAddMemberInputBuilder result,
    required List<Object?> unhandled,
  }) {
    for (var i = 0; i < serializedList.length; i += 2) {
      final key = serializedList[i] as String;
      final value = serializedList[i + 1];
      switch (key) {
        case r'mnemonic':
          final valueDes =
              serializers.deserialize(
                    value,
                    specifiedType: const FullType(String),
                  )
                  as String;
          result.mnemonic = valueDes;
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
        case r'groupId':
          final valueDes =
              serializers.deserialize(
                    value,
                    specifiedType: const FullType(String),
                  )
                  as String;
          result.groupId = valueDes;
          break;
        case r'memberDid':
          final valueDes =
              serializers.deserialize(
                    value,
                    specifiedType: const FullType(String),
                  )
                  as String;
          result.memberDid = valueDes;
          break;
        case r'acceptOfferAsDid':
          final valueDes =
              serializers.deserialize(
                    value,
                    specifiedType: const FullType(String),
                  )
                  as String;
          result.acceptOfferAsDid = valueDes;
          break;
        case r'reencryptionKey':
          final valueDes =
              serializers.deserialize(
                    value,
                    specifiedType: const FullType(String),
                  )
                  as String;
          result.reencryptionKey = valueDes;
          break;
        case r'publicKey':
          final valueDes =
              serializers.deserialize(
                    value,
                    specifiedType: const FullType(String),
                  )
                  as String;
          result.publicKey = valueDes;
          break;
        case r'contactCard':
          final valueDes =
              serializers.deserialize(
                    value,
                    specifiedType: const FullType(String),
                  )
                  as String;
          result.contactCard = valueDes;
          break;
        default:
          unhandled.add(key);
          unhandled.add(value);
          break;
      }
    }
  }

  @override
  GroupAddMemberInput deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = GroupAddMemberInputBuilder();
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
