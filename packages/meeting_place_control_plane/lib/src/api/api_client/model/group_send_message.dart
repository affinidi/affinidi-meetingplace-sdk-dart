//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'group_send_message.g.dart';

/// List of required and optional parameters to send a group chat message.
///
/// Properties:
/// * [offerLink] - The Offer link associated with the group chat.
/// * [fromDid] - The Decentralised Identifier (DID) of the message sender.
/// * [groupDid] - The channel DID for the group chat.
/// * [payload] - Input payload containing the message to send to the group chat.
/// * [ephemeral] - Indicates whether the message is ephemeral and should not be stored persistently.
/// * [expiresTime] - The date and time of when the message expires in ISO-8601 format, e.g., 2023-09-20T07:12:13.
/// * [notify] - Indicates whether to send a notification to the group chat members using push notification.
/// * [incSeqNo] - Indicates whether to increment the sequence number of the message in the group chat.
@BuiltValue()
abstract class GroupSendMessage
    implements Built<GroupSendMessage, GroupSendMessageBuilder> {
  /// The Offer link associated with the group chat.
  @BuiltValueField(wireName: r'offerLink')
  String get offerLink;

  /// The Decentralised Identifier (DID) of the message sender.
  @BuiltValueField(wireName: r'fromDid')
  String get fromDid;

  /// The channel DID for the group chat.
  @BuiltValueField(wireName: r'groupDid')
  String get groupDid;

  /// Input payload containing the message to send to the group chat.
  @BuiltValueField(wireName: r'payload')
  String get payload;

  /// Indicates whether the message is ephemeral and should not be stored persistently.
  @BuiltValueField(wireName: r'ephemeral')
  bool? get ephemeral;

  /// The date and time of when the message expires in ISO-8601 format, e.g., 2023-09-20T07:12:13.
  @BuiltValueField(wireName: r'expiresTime')
  String? get expiresTime;

  /// Indicates whether to send a notification to the group chat members using push notification.
  @BuiltValueField(wireName: r'notify')
  bool? get notify;

  /// Indicates whether to increment the sequence number of the message in the group chat.
  @BuiltValueField(wireName: r'incSeqNo')
  bool? get incSeqNo;

  GroupSendMessage._();

  factory GroupSendMessage([void updates(GroupSendMessageBuilder b)]) =
      _$GroupSendMessage;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(GroupSendMessageBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<GroupSendMessage> get serializer =>
      _$GroupSendMessageSerializer();
}

class _$GroupSendMessageSerializer
    implements PrimitiveSerializer<GroupSendMessage> {
  @override
  final Iterable<Type> types = const [GroupSendMessage, _$GroupSendMessage];

  @override
  final String wireName = r'GroupSendMessage';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    GroupSendMessage object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    yield r'offerLink';
    yield serializers.serialize(
      object.offerLink,
      specifiedType: const FullType(String),
    );
    yield r'fromDid';
    yield serializers.serialize(
      object.fromDid,
      specifiedType: const FullType(String),
    );
    yield r'groupDid';
    yield serializers.serialize(
      object.groupDid,
      specifiedType: const FullType(String),
    );
    yield r'payload';
    yield serializers.serialize(
      object.payload,
      specifiedType: const FullType(String),
    );
    if (object.ephemeral != null) {
      yield r'ephemeral';
      yield serializers.serialize(
        object.ephemeral,
        specifiedType: const FullType(bool),
      );
    }
    if (object.expiresTime != null) {
      yield r'expiresTime';
      yield serializers.serialize(
        object.expiresTime,
        specifiedType: const FullType(String),
      );
    }
    if (object.notify != null) {
      yield r'notify';
      yield serializers.serialize(
        object.notify,
        specifiedType: const FullType(bool),
      );
    }
    if (object.incSeqNo != null) {
      yield r'incSeqNo';
      yield serializers.serialize(
        object.incSeqNo,
        specifiedType: const FullType(bool),
      );
    }
  }

  @override
  Object serialize(
    Serializers serializers,
    GroupSendMessage object, {
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
    required GroupSendMessageBuilder result,
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
        case r'fromDid':
          final valueDes =
              serializers.deserialize(
                    value,
                    specifiedType: const FullType(String),
                  )
                  as String;
          result.fromDid = valueDes;
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
        case r'payload':
          final valueDes =
              serializers.deserialize(
                    value,
                    specifiedType: const FullType(String),
                  )
                  as String;
          result.payload = valueDes;
          break;
        case r'ephemeral':
          final valueDes =
              serializers.deserialize(
                    value,
                    specifiedType: const FullType(bool),
                  )
                  as bool;
          result.ephemeral = valueDes;
          break;
        case r'expiresTime':
          final valueDes =
              serializers.deserialize(
                    value,
                    specifiedType: const FullType(String),
                  )
                  as String;
          result.expiresTime = valueDes;
          break;
        case r'notify':
          final valueDes =
              serializers.deserialize(
                    value,
                    specifiedType: const FullType(bool),
                  )
                  as bool;
          result.notify = valueDes;
          break;
        case r'incSeqNo':
          final valueDes =
              serializers.deserialize(
                    value,
                    specifiedType: const FullType(bool),
                  )
                  as bool;
          result.incSeqNo = valueDes;
          break;
        default:
          unhandled.add(key);
          unhandled.add(value);
          break;
      }
    }
  }

  @override
  GroupSendMessage deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = GroupSendMessageBuilder();
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
