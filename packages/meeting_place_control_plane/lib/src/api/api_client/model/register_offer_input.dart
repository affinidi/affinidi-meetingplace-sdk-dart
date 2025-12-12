//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_collection/built_collection.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'register_offer_input.g.dart';

/// RegisterOfferInput
///
/// Properties:
/// * [offerName] - Name of the offer.
/// * [offerDescription] - Describes the purpose of the connection offer.
/// * [offerType] - Specifies the type of the offer: 1-Chat, 2-Poll, 3-Group Chat, and 4-Outreach.
/// * [didcommMessage] - A plaintext DIDComm message containing the offer encoded in base64 format.
/// * [contactCard] - A ContactCard of the user who registered the offer encoded in base64 format.
/// * [validUntil] - The validity date and time in ISO-8601 format, e.g., 2023-09-20T07:12:13  or an empty string for no expiry.
/// * [maximumUsage] - The maximum number of times other users can claim the offer. Set 0 for unlimited claims.
/// * [deviceToken] - The device token for push notification when the offer is accessed.  Maximum length of 2048 characters.
/// * [platformType] - Platform type for sending notification.
/// * [contactAttributes] - A bitfield of contact attributes.
/// * [mediatorDid] - The mediator DID use to register the offer.
/// * [mediatorEndpoint] - The mediator endpoint to register the offer.
/// * [mediatorWSSEndpoint] - The websocket endpoint of the mediator to register the offer.
/// * [customPhrase] - A custom phrase to find and claim the offer by another user.
/// * [isSearchable] - Indicates whether the offer is searchable by other users.
/// * [metadata] - Metadata containing additional information about the offer.
@BuiltValue()
abstract class RegisterOfferInput
    implements Built<RegisterOfferInput, RegisterOfferInputBuilder> {
  /// Name of the offer.
  @BuiltValueField(wireName: r'offerName')
  String get offerName;

  /// Describes the purpose of the connection offer.
  @BuiltValueField(wireName: r'offerDescription')
  String? get offerDescription;

  /// Specifies the type of the offer: 1-Chat, 2-Poll, 3-Group Chat, and 4-Outreach.
  @BuiltValueField(wireName: r'offerType')
  RegisterOfferInputOfferTypeEnum? get offerType;
  // enum offerTypeEnum {  1,  2,  3,  4,  };

  /// A plaintext DIDComm message containing the offer encoded in base64 format.
  @BuiltValueField(wireName: r'didcommMessage')
  String get didcommMessage;

  /// A ContactCard of the user who registered the offer encoded in base64 format.
  @BuiltValueField(wireName: r'contactCard')
  String get contactCard;

  /// The validity date and time in ISO-8601 format, e.g., 2023-09-20T07:12:13  or an empty string for no expiry.
  @BuiltValueField(wireName: r'validUntil')
  String? get validUntil;

  /// The maximum number of times other users can claim the offer. Set 0 for unlimited claims.
  @BuiltValueField(wireName: r'maximumUsage')
  int? get maximumUsage;

  /// The device token for push notification when the offer is accessed.  Maximum length of 2048 characters.
  @BuiltValueField(wireName: r'deviceToken')
  String get deviceToken;

  /// Platform type for sending notification.
  @BuiltValueField(wireName: r'platformType')
  RegisterOfferInputPlatformTypeEnum get platformType;
  // enum platformTypeEnum {  DIDCOMM,  PUSH_NOTIFICATION,  NONE,  };

  /// A bitfield of contact attributes.
  @BuiltValueField(wireName: r'contactAttributes')
  int get contactAttributes;

  /// The mediator DID use to register the offer.
  @BuiltValueField(wireName: r'mediatorDid')
  String get mediatorDid;

  /// The mediator endpoint to register the offer.
  @BuiltValueField(wireName: r'mediatorEndpoint')
  String get mediatorEndpoint;

  /// The websocket endpoint of the mediator to register the offer.
  @BuiltValueField(wireName: r'mediatorWSSEndpoint')
  String get mediatorWSSEndpoint;

  /// A custom phrase to find and claim the offer by another user.
  @BuiltValueField(wireName: r'customPhrase')
  String? get customPhrase;

  /// Indicates whether the offer is searchable by other users.
  @BuiltValueField(wireName: r'isSearchable')
  bool? get isSearchable;

  /// Metadata containing additional information about the offer.
  @BuiltValueField(wireName: r'metadata')
  String? get metadata;

  RegisterOfferInput._();

  factory RegisterOfferInput([void updates(RegisterOfferInputBuilder b)]) =
      _$RegisterOfferInput;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(RegisterOfferInputBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<RegisterOfferInput> get serializer =>
      _$RegisterOfferInputSerializer();
}

class _$RegisterOfferInputSerializer
    implements PrimitiveSerializer<RegisterOfferInput> {
  @override
  final Iterable<Type> types = const [RegisterOfferInput, _$RegisterOfferInput];

  @override
  final String wireName = r'RegisterOfferInput';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    RegisterOfferInput object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    yield r'offerName';
    yield serializers.serialize(
      object.offerName,
      specifiedType: const FullType(String),
    );
    if (object.offerDescription != null) {
      yield r'offerDescription';
      yield serializers.serialize(
        object.offerDescription,
        specifiedType: const FullType(String),
      );
    }
    if (object.offerType != null) {
      yield r'offerType';
      yield serializers.serialize(
        object.offerType,
        specifiedType: const FullType(RegisterOfferInputOfferTypeEnum),
      );
    }
    yield r'didcommMessage';
    yield serializers.serialize(
      object.didcommMessage,
      specifiedType: const FullType(String),
    );
    yield r'contactCard';
    yield serializers.serialize(
      object.contactCard,
      specifiedType: const FullType(String),
    );
    if (object.validUntil != null) {
      yield r'validUntil';
      yield serializers.serialize(
        object.validUntil,
        specifiedType: const FullType(String),
      );
    }
    if (object.maximumUsage != null) {
      yield r'maximumUsage';
      yield serializers.serialize(
        object.maximumUsage,
        specifiedType: const FullType(int),
      );
    }
    yield r'deviceToken';
    yield serializers.serialize(
      object.deviceToken,
      specifiedType: const FullType(String),
    );
    yield r'platformType';
    yield serializers.serialize(
      object.platformType,
      specifiedType: const FullType(RegisterOfferInputPlatformTypeEnum),
    );
    yield r'contactAttributes';
    yield serializers.serialize(
      object.contactAttributes,
      specifiedType: const FullType(int),
    );
    yield r'mediatorDid';
    yield serializers.serialize(
      object.mediatorDid,
      specifiedType: const FullType(String),
    );
    yield r'mediatorEndpoint';
    yield serializers.serialize(
      object.mediatorEndpoint,
      specifiedType: const FullType(String),
    );
    yield r'mediatorWSSEndpoint';
    yield serializers.serialize(
      object.mediatorWSSEndpoint,
      specifiedType: const FullType(String),
    );
    if (object.customPhrase != null) {
      yield r'customPhrase';
      yield serializers.serialize(
        object.customPhrase,
        specifiedType: const FullType(String),
      );
    }
    if (object.isSearchable != null) {
      yield r'isSearchable';
      yield serializers.serialize(
        object.isSearchable,
        specifiedType: const FullType(bool),
      );
    }
    if (object.metadata != null) {
      yield r'metadata';
      yield serializers.serialize(
        object.metadata,
        specifiedType: const FullType(String),
      );
    }
  }

  @override
  Object serialize(
    Serializers serializers,
    RegisterOfferInput object, {
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
    required RegisterOfferInputBuilder result,
    required List<Object?> unhandled,
  }) {
    for (var i = 0; i < serializedList.length; i += 2) {
      final key = serializedList[i] as String;
      final value = serializedList[i + 1];
      switch (key) {
        case r'offerName':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.offerName = valueDes;
          break;
        case r'offerDescription':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.offerDescription = valueDes;
          break;
        case r'offerType':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(RegisterOfferInputOfferTypeEnum),
          ) as RegisterOfferInputOfferTypeEnum;
          result.offerType = valueDes;
          break;
        case r'didcommMessage':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.didcommMessage = valueDes;
          break;
        case r'contactCard':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.contactCard = valueDes;
          break;
        case r'validUntil':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.validUntil = valueDes;
          break;
        case r'maximumUsage':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(int),
          ) as int;
          result.maximumUsage = valueDes;
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
            specifiedType: const FullType(RegisterOfferInputPlatformTypeEnum),
          ) as RegisterOfferInputPlatformTypeEnum;
          result.platformType = valueDes;
          break;
        case r'contactAttributes':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(int),
          ) as int;
          result.contactAttributes = valueDes;
          break;
        case r'mediatorDid':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.mediatorDid = valueDes;
          break;
        case r'mediatorEndpoint':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.mediatorEndpoint = valueDes;
          break;
        case r'mediatorWSSEndpoint':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.mediatorWSSEndpoint = valueDes;
          break;
        case r'customPhrase':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.customPhrase = valueDes;
          break;
        case r'isSearchable':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(bool),
          ) as bool;
          result.isSearchable = valueDes;
          break;
        case r'metadata':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.metadata = valueDes;
          break;
        default:
          unhandled.add(key);
          unhandled.add(value);
          break;
      }
    }
  }

  @override
  RegisterOfferInput deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = RegisterOfferInputBuilder();
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

class RegisterOfferInputOfferTypeEnum extends EnumClass {
  /// Specifies the type of the offer: 1-Chat, 2-Poll, 3-Group Chat, and 4-Outreach.
  @BuiltValueEnumConst(wireNumber: 1)
  static const RegisterOfferInputOfferTypeEnum number1 =
      _$registerOfferInputOfferTypeEnum_number1;

  /// Specifies the type of the offer: 1-Chat, 2-Poll, 3-Group Chat, and 4-Outreach.
  @BuiltValueEnumConst(wireNumber: 2)
  static const RegisterOfferInputOfferTypeEnum number2 =
      _$registerOfferInputOfferTypeEnum_number2;

  /// Specifies the type of the offer: 1-Chat, 2-Poll, 3-Group Chat, and 4-Outreach.
  @BuiltValueEnumConst(wireNumber: 3)
  static const RegisterOfferInputOfferTypeEnum number3 =
      _$registerOfferInputOfferTypeEnum_number3;

  /// Specifies the type of the offer: 1-Chat, 2-Poll, 3-Group Chat, and 4-Outreach.
  @BuiltValueEnumConst(wireNumber: 4)
  static const RegisterOfferInputOfferTypeEnum number4 =
      _$registerOfferInputOfferTypeEnum_number4;

  static Serializer<RegisterOfferInputOfferTypeEnum> get serializer =>
      _$registerOfferInputOfferTypeEnumSerializer;

  const RegisterOfferInputOfferTypeEnum._(String name) : super(name);

  static BuiltSet<RegisterOfferInputOfferTypeEnum> get values =>
      _$registerOfferInputOfferTypeEnumValues;
  static RegisterOfferInputOfferTypeEnum valueOf(String name) =>
      _$registerOfferInputOfferTypeEnumValueOf(name);
}

class RegisterOfferInputPlatformTypeEnum extends EnumClass {
  /// Platform type for sending notification.
  @BuiltValueEnumConst(wireName: r'DIDCOMM')
  static const RegisterOfferInputPlatformTypeEnum DIDCOMM =
      _$registerOfferInputPlatformTypeEnum_DIDCOMM;

  /// Platform type for sending notification.
  @BuiltValueEnumConst(wireName: r'PUSH_NOTIFICATION')
  static const RegisterOfferInputPlatformTypeEnum PUSH_NOTIFICATION =
      _$registerOfferInputPlatformTypeEnum_PUSH_NOTIFICATION;

  /// Platform type for sending notification.
  @BuiltValueEnumConst(wireName: r'NONE')
  static const RegisterOfferInputPlatformTypeEnum NONE =
      _$registerOfferInputPlatformTypeEnum_NONE;

  static Serializer<RegisterOfferInputPlatformTypeEnum> get serializer =>
      _$registerOfferInputPlatformTypeEnumSerializer;

  const RegisterOfferInputPlatformTypeEnum._(String name) : super(name);

  static BuiltSet<RegisterOfferInputPlatformTypeEnum> get values =>
      _$registerOfferInputPlatformTypeEnumValues;
  static RegisterOfferInputPlatformTypeEnum valueOf(String name) =>
      _$registerOfferInputPlatformTypeEnumValueOf(name);
}
