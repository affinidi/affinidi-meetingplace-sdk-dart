//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_collection/built_collection.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'finalise_offer_input.g.dart';

/// List of required and optional parameters to finalise the acceptance of an offer.
///
/// Properties:
/// * [mnemonic] - A unique phrase used to publish and identify the offer.
/// * [did] - Channel DID to use to finalise the acceptance of an offer.
/// * [offerLink] - Offer link associated with the channel.
/// * [theirDid] - Decentralised Identifier (DID) of the user who accepted the offer.
/// * [deviceToken] - The device token for push notification when the offer is processed.  Maximum length of 2048 characters.
/// * [platformType] - Platform type for sending notification.
@BuiltValue()
abstract class FinaliseOfferInput
    implements Built<FinaliseOfferInput, FinaliseOfferInputBuilder> {
  /// A unique phrase used to publish and identify the offer.
  @BuiltValueField(wireName: r'mnemonic')
  String get mnemonic;

  /// Channel DID to use to finalise the acceptance of an offer.
  @BuiltValueField(wireName: r'did')
  String get did;

  /// Offer link associated with the channel.
  @BuiltValueField(wireName: r'offerLink')
  String get offerLink;

  /// Decentralised Identifier (DID) of the user who accepted the offer.
  @BuiltValueField(wireName: r'theirDid')
  String get theirDid;

  /// The device token for push notification when the offer is processed.  Maximum length of 2048 characters.
  @BuiltValueField(wireName: r'deviceToken')
  String? get deviceToken;

  /// Platform type for sending notification.
  @BuiltValueField(wireName: r'platformType')
  FinaliseOfferInputPlatformTypeEnum? get platformType;
  // enum platformTypeEnum {  DIDCOMM,  PUSH_NOTIFICATION,  NONE,  };

  FinaliseOfferInput._();

  factory FinaliseOfferInput([void updates(FinaliseOfferInputBuilder b)]) =
      _$FinaliseOfferInput;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(FinaliseOfferInputBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<FinaliseOfferInput> get serializer =>
      _$FinaliseOfferInputSerializer();
}

class _$FinaliseOfferInputSerializer
    implements PrimitiveSerializer<FinaliseOfferInput> {
  @override
  final Iterable<Type> types = const [FinaliseOfferInput, _$FinaliseOfferInput];

  @override
  final String wireName = r'FinaliseOfferInput';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    FinaliseOfferInput object, {
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
    yield r'theirDid';
    yield serializers.serialize(
      object.theirDid,
      specifiedType: const FullType(String),
    );
    if (object.deviceToken != null) {
      yield r'deviceToken';
      yield serializers.serialize(
        object.deviceToken,
        specifiedType: const FullType(String),
      );
    }
    if (object.platformType != null) {
      yield r'platformType';
      yield serializers.serialize(
        object.platformType,
        specifiedType: const FullType(FinaliseOfferInputPlatformTypeEnum),
      );
    }
  }

  @override
  Object serialize(
    Serializers serializers,
    FinaliseOfferInput object, {
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
    required FinaliseOfferInputBuilder result,
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
        case r'offerLink':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.offerLink = valueDes;
          break;
        case r'theirDid':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.theirDid = valueDes;
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
            specifiedType: const FullType(FinaliseOfferInputPlatformTypeEnum),
          ) as FinaliseOfferInputPlatformTypeEnum;
          result.platformType = valueDes;
          break;
        default:
          unhandled.add(key);
          unhandled.add(value);
          break;
      }
    }
  }

  @override
  FinaliseOfferInput deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = FinaliseOfferInputBuilder();
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

class FinaliseOfferInputPlatformTypeEnum extends EnumClass {
  /// Platform type for sending notification.
  @BuiltValueEnumConst(wireName: r'DIDCOMM')
  static const FinaliseOfferInputPlatformTypeEnum DIDCOMM =
      _$finaliseOfferInputPlatformTypeEnum_DIDCOMM;

  /// Platform type for sending notification.
  @BuiltValueEnumConst(wireName: r'PUSH_NOTIFICATION')
  static const FinaliseOfferInputPlatformTypeEnum PUSH_NOTIFICATION =
      _$finaliseOfferInputPlatformTypeEnum_PUSH_NOTIFICATION;

  /// Platform type for sending notification.
  @BuiltValueEnumConst(wireName: r'NONE')
  static const FinaliseOfferInputPlatformTypeEnum NONE =
      _$finaliseOfferInputPlatformTypeEnum_NONE;

  static Serializer<FinaliseOfferInputPlatformTypeEnum> get serializer =>
      _$finaliseOfferInputPlatformTypeEnumSerializer;

  const FinaliseOfferInputPlatformTypeEnum._(String name) : super(name);

  static BuiltSet<FinaliseOfferInputPlatformTypeEnum> get values =>
      _$finaliseOfferInputPlatformTypeEnumValues;
  static FinaliseOfferInputPlatformTypeEnum valueOf(String name) =>
      _$finaliseOfferInputPlatformTypeEnumValueOf(name);
}
