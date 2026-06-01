//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'group_notify_channel_input.g.dart';

/// List of required parameters to notify all members of a group chat.
///
/// Properties:
/// * [offerLink] - The Offer link associated with the group chat.
/// * [groupDid] - The channel DID for the group chat.
/// * [type] - The notification type to send to group members.
@BuiltValue()
abstract class GroupNotifyChannelInput
    implements Built<GroupNotifyChannelInput, GroupNotifyChannelInputBuilder> {
  /// The Offer link associated with the group chat.
  @BuiltValueField(wireName: r'offerLink')
  String get offerLink;

  /// The channel DID for the group chat.
  @BuiltValueField(wireName: r'groupDid')
  String get groupDid;

  /// The notification type to send to group members.
  @BuiltValueField(wireName: r'type')
  String get type;

  GroupNotifyChannelInput._();

  factory GroupNotifyChannelInput([
    void updates(GroupNotifyChannelInputBuilder b),
  ]) = _$GroupNotifyChannelInput;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(GroupNotifyChannelInputBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<GroupNotifyChannelInput> get serializer =>
      _$GroupNotifyChannelInputSerializer();
}

class _$GroupNotifyChannelInputSerializer
    implements PrimitiveSerializer<GroupNotifyChannelInput> {
  @override
  final Iterable<Type> types = const [
    GroupNotifyChannelInput,
    _$GroupNotifyChannelInput,
  ];

  @override
  final String wireName = r'GroupNotifyChannelInput';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    GroupNotifyChannelInput object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    yield r'offerLink';
    yield serializers.serialize(
      object.offerLink,
      specifiedType: const FullType(String),
    );
    yield r'groupDid';
    yield serializers.serialize(
      object.groupDid,
      specifiedType: const FullType(String),
    );
    yield r'type';
    yield serializers.serialize(
      object.type,
      specifiedType: const FullType(String),
    );
  }

  @override
  Object serialize(
    Serializers serializers,
    GroupNotifyChannelInput object, {
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
    required GroupNotifyChannelInputBuilder result,
    required List<Object?> unhandled,
  }) {
    for (var i = 0; i < serializedList.length; i += 2) {
      final key = serializedList[i] as String;
      final value = serializedList[i + 1];
      switch (key) {
        case r'offerLink':
          final valueDes =
              serializers.deserialize(
                    value,
                    specifiedType: const FullType(String),
                  )
                  as String;
          result.offerLink = valueDes;
          break;
        case r'groupDid':
          final valueDes =
              serializers.deserialize(
                    value,
                    specifiedType: const FullType(String),
                  )
                  as String;
          result.groupDid = valueDes;
          break;
        case r'type':
          final valueDes =
              serializers.deserialize(
                    value,
                    specifiedType: const FullType(String),
                  )
                  as String;
          result.type = valueDes;
          break;
        default:
          unhandled.add(key);
          unhandled.add(value);
          break;
      }
    }
  }

  @override
  GroupNotifyChannelInput deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = GroupNotifyChannelInputBuilder();
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
