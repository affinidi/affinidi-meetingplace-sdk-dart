//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_collection/built_collection.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'accept_offer_input.g.dart';

/// AcceptOfferInput
///
/// Properties:
/// * [mnemonic] - A unique phrase used to publish and identify the offer.
/// * [did] - Permanent channel DID of the user upon approval of the connection request.
/// * [deviceToken] - The device token for push notification when the offer is processed.  Maximum length of 2048 characters.
/// * [platformType] - Platform type for sending notification.
/// * [contactCard] - A ContactCard containing the details of the offer encoded in base64 format.
/// * [offerLink]
@BuiltValue()
abstract class AcceptOfferInput
    implements Built<AcceptOfferInput, AcceptOfferInputBuilder> {
  /// A unique phrase used to publish and identify the offer.
  @BuiltValueField(wireName: r'mnemonic')
  String get mnemonic;

  /// Permanent channel DID of the user upon approval of the connection request.
  @BuiltValueField(wireName: r'did')
  String get did;

  /// The device token for push notification when the offer is processed.  Maximum length of 2048 characters.
  @BuiltValueField(wireName: r'deviceToken')
  String get deviceToken;

  /// Platform type for sending notification.
  @BuiltValueField(wireName: r'platformType')
  AcceptOfferInputPlatformTypeEnum get platformType;
  // enum platformTypeEnum {  DIDCOMM,  PUSH_NOTIFICATION,  NONE,  };

  /// A ContactCard containing the details of the offer encoded in base64 format.
  @BuiltValueField(wireName: r'contactCard')
  String get contactCard;

  @BuiltValueField(wireName: r'offerLink')
  String get offerLink;

  AcceptOfferInput._();

  factory AcceptOfferInput([void updates(AcceptOfferInputBuilder b)]) =
      _$AcceptOfferInput;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(AcceptOfferInputBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<AcceptOfferInput> get serializer =>
      _$AcceptOfferInputSerializer();
}

class _$AcceptOfferInputSerializer
    implements PrimitiveSerializer<AcceptOfferInput> {
  @override
  final Iterable<Type> types = const [AcceptOfferInput, _$AcceptOfferInput];

  @override
  final String wireName = r'AcceptOfferInput';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    AcceptOfferInput object, {
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
    yield r'deviceToken';
    yield serializers.serialize(
      object.deviceToken,
      specifiedType: const FullType(String),
    );
    yield r'platformType';
    yield serializers.serialize(
      object.platformType,
      specifiedType: const FullType(AcceptOfferInputPlatformTypeEnum),
    );
    yield r'contactCard';
    yield serializers.serialize(
      object.contactCard,
      specifiedType: const FullType(String),
    );
    yield r'offerLink';
    yield serializers.serialize(
      object.offerLink,
      specifiedType: const FullType(String),
    );
  }

  @override
  Object serialize(
    Serializers serializers,
    AcceptOfferInput object, {
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
    required AcceptOfferInputBuilder result,
    required List<Object?> unhandled,
  }) {
    for (var i = 0; i < serializedList.length; i += 2) {
      final key = serializedList[i] as String;
      final value = serializedList[i + 1];
      switch (key) {
        case r'mnemonic':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.mnemonic = valueDes;
          break;
        case r'did':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.did = valueDes;
          break;
        case r'deviceToken':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.deviceToken = valueDes;
          break;
        case r'platformType':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(AcceptOfferInputPlatformTypeEnum),
          ) as AcceptOfferInputPlatformTypeEnum;
          result.platformType = valueDes;
          break;
        case r'contactCard':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.contactCard = valueDes;
          break;
        case r'offerLink':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.offerLink = valueDes;
          break;
        default:
          unhandled.add(key);
          unhandled.add(value);
          break;
      }
    }
  }

  @override
  AcceptOfferInput deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = AcceptOfferInputBuilder();
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

class AcceptOfferInputPlatformTypeEnum extends EnumClass {
  /// Platform type for sending notification.
  @BuiltValueEnumConst(wireName: r'DIDCOMM')
  static const AcceptOfferInputPlatformTypeEnum DIDCOMM =
      _$acceptOfferInputPlatformTypeEnum_DIDCOMM;

  /// Platform type for sending notification.
  @BuiltValueEnumConst(wireName: r'PUSH_NOTIFICATION')
  static const AcceptOfferInputPlatformTypeEnum PUSH_NOTIFICATION =
      _$acceptOfferInputPlatformTypeEnum_PUSH_NOTIFICATION;

  /// Platform type for sending notification.
  @BuiltValueEnumConst(wireName: r'NONE')
  static const AcceptOfferInputPlatformTypeEnum NONE =
      _$acceptOfferInputPlatformTypeEnum_NONE;

  static Serializer<AcceptOfferInputPlatformTypeEnum> get serializer =>
      _$acceptOfferInputPlatformTypeEnumSerializer;

  const AcceptOfferInputPlatformTypeEnum._(String name) : super(name);

  static BuiltSet<AcceptOfferInputPlatformTypeEnum> get values =>
      _$acceptOfferInputPlatformTypeEnumValues;
  static AcceptOfferInputPlatformTypeEnum valueOf(String name) =>
      _$acceptOfferInputPlatformTypeEnumValueOf(name);
}
