//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'notify_accept_offer_group_input.g.dart';

/// NotifyAcceptOfferGroupInput
///
/// Properties:
/// * [mnemonic] - A unique phrase used to publish and identify the offer.
/// * [did] - Permanent channel DID of the user upon approval of the connection request.
/// * [offerLink] - The offer link associated with the published offer.
/// * [senderInfo] - Sender info to be shown in notification message.
@BuiltValue()
abstract class NotifyAcceptOfferGroupInput
    implements
        Built<NotifyAcceptOfferGroupInput, NotifyAcceptOfferGroupInputBuilder> {
  /// A unique phrase used to publish and identify the offer.
  @BuiltValueField(wireName: r'mnemonic')
  String get mnemonic;

  /// Permanent channel DID of the user upon approval of the connection request.
  @BuiltValueField(wireName: r'did')
  String get did;

  /// The offer link associated with the published offer.
  @BuiltValueField(wireName: r'offerLink')
  String get offerLink;

  /// Sender info to be shown in notification message.
  @BuiltValueField(wireName: r'senderInfo')
  String get senderInfo;

  NotifyAcceptOfferGroupInput._();

  factory NotifyAcceptOfferGroupInput([
    void updates(NotifyAcceptOfferGroupInputBuilder b),
  ]) = _$NotifyAcceptOfferGroupInput;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(NotifyAcceptOfferGroupInputBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<NotifyAcceptOfferGroupInput> get serializer =>
      _$NotifyAcceptOfferGroupInputSerializer();
}

class _$NotifyAcceptOfferGroupInputSerializer
    implements PrimitiveSerializer<NotifyAcceptOfferGroupInput> {
  @override
  final Iterable<Type> types = const [
    NotifyAcceptOfferGroupInput,
    _$NotifyAcceptOfferGroupInput,
  ];

  @override
  final String wireName = r'NotifyAcceptOfferGroupInput';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    NotifyAcceptOfferGroupInput object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    yield r'mnemonic';
    yield serializers.serialize(
      object.mnemonic,
      specifiedType: const FullType(String),
    );
    yield r'did';
    yield serializers.serialize(
      object.did,
      specifiedType: const FullType(String),
    );
    yield r'offerLink';
    yield serializers.serialize(
      object.offerLink,
      specifiedType: const FullType(String),
    );
    yield r'senderInfo';
    yield serializers.serialize(
      object.senderInfo,
      specifiedType: const FullType(String),
    );
  }

  @override
  Object serialize(
    Serializers serializers,
    NotifyAcceptOfferGroupInput object, {
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
    required NotifyAcceptOfferGroupInputBuilder result,
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
        case r'did':
          final valueDes =
              serializers.deserialize(
                    value,
                    specifiedType: const FullType(String),
                  )
                  as String;
          result.did = valueDes;
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
        case r'senderInfo':
          final valueDes =
              serializers.deserialize(
                    value,
                    specifiedType: const FullType(String),
                  )
                  as String;
          result.senderInfo = valueDes;
          break;
        default:
          unhandled.add(key);
          unhandled.add(value);
          break;
      }
    }
  }

  @override
  NotifyAcceptOfferGroupInput deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = NotifyAcceptOfferGroupInputBuilder();
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
