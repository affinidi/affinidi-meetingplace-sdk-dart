//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_collection/built_collection.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'register_offer_group_input.g.dart';

/// List of required and optional parameters to register a connection offer for group chat.
///
/// Properties:
/// * [offerName] - Name of the offer.
/// * [offerDescription] - Describes the purpose of the connection offer.
/// * [didcommMessage] - A plaintext DIDComm message containing the offer encoded in base64 format.
/// * [contactCard] - A ContactCard of the user who registered the offer encoded in base64 format.
/// * [validUntil] - The validity date and time in ISO-8601 format, e.g., 2023-09-20T07:12:13  or an empty string for no expiry.
/// * [maximumUsage] - The maximum number of times other users can claim the offer. Set 0 for unlimited claims.
/// * [deviceToken] - The device token for push notification when the offer is accessed.  Maximum length of 2048 characters.
/// * [platformType] - Platform type for sending notification.
/// * [mediatorDid] - The mediator DID use to register the offer.
/// * [mediatorEndpoint] - The mediator endpoint to register the offer.
/// * [mediatorWSSEndpoint] - The websocket endpoint of the mediator to register the offer.
/// * [customPhrase] - A custom phrase to find and claim the offer by another user.
/// * [isSearchable] - Indicates whether the offer is searchable by other users.
/// * [metadata] - Metadata containing additional information about the offer.
/// * [adminReencryptionKey] - Reencryption key for the group chat admin.
/// * [adminDid] - The Decentralised Identifier (DUD) of the group chat admin.
/// * [adminPublicKey] - The public key information of the group chat admin.
/// * [memberVCard] - A vCard of the group chat member encoded in base64 format.
@BuiltValue()
abstract class RegisterOfferGroupInput
    implements Built<RegisterOfferGroupInput, RegisterOfferGroupInputBuilder> {
  /// Name of the offer.
  @BuiltValueField(wireName: r'offerName')
  String get offerName;

  /// Describes the purpose of the connection offer.
  @BuiltValueField(wireName: r'offerDescription')
  String get offerDescription;

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
  RegisterOfferGroupInputPlatformTypeEnum get platformType;
  // enum platformTypeEnum {  DIDCOMM,  PUSH_NOTIFICATION,  NONE,  };

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

  /// Reencryption key for the group chat admin.
  @BuiltValueField(wireName: r'adminReencryptionKey')
  String get adminReencryptionKey;

  /// The Decentralised Identifier (DUD) of the group chat admin.
  @BuiltValueField(wireName: r'adminDid')
  String get adminDid;

  /// The public key information of the group chat admin.
  @BuiltValueField(wireName: r'adminPublicKey')
  String get adminPublicKey;

  /// A ContactCard of the group chat member encoded in base64 format.
  @BuiltValueField(wireName: r'memberContactCard')
  String get memberContactCard;

  RegisterOfferGroupInput._();

  factory RegisterOfferGroupInput(
          [void updates(RegisterOfferGroupInputBuilder b)]) =
      _$RegisterOfferGroupInput;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(RegisterOfferGroupInputBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<RegisterOfferGroupInput> get serializer =>
      _$RegisterOfferGroupInputSerializer();
}

class _$RegisterOfferGroupInputSerializer
    implements PrimitiveSerializer<RegisterOfferGroupInput> {
  @override
  final Iterable<Type> types = const [
    RegisterOfferGroupInput,
    _$RegisterOfferGroupInput
  ];

  @override
  final String wireName = r'RegisterOfferGroupInput';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    RegisterOfferGroupInput object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    yield r'offerName';
    yield serializers.serialize(
      object.offerName,
      specifiedType: const FullType(String),
    );
    yield r'offerDescription';
    yield serializers.serialize(
      object.offerDescription,
      specifiedType: const FullType(String),
    );
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
      specifiedType: const FullType(RegisterOfferGroupInputPlatformTypeEnum),
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
    yield r'adminReencryptionKey';
    yield serializers.serialize(
      object.adminReencryptionKey,
      specifiedType: const FullType(String),
    );
    yield r'adminDid';
    yield serializers.serialize(
      object.adminDid,
      specifiedType: const FullType(String),
    );
    yield r'adminPublicKey';
    yield serializers.serialize(
      object.adminPublicKey,
      specifiedType: const FullType(String),
    );
    yield r'memberContactCard';
    yield serializers.serialize(
      object.memberContactCard,
      specifiedType: const FullType(String),
    );
  }

  @override
  Object serialize(
    Serializers serializers,
    RegisterOfferGroupInput object, {
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
    required RegisterOfferGroupInputBuilder result,
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
            specifiedType:
                const FullType(RegisterOfferGroupInputPlatformTypeEnum),
          ) as RegisterOfferGroupInputPlatformTypeEnum;
          result.platformType = valueDes;
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
        case r'adminReencryptionKey':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.adminReencryptionKey = valueDes;
          break;
        case r'adminDid':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.adminDid = valueDes;
          break;
        case r'adminPublicKey':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.adminPublicKey = valueDes;
          break;
        case r'memberContactCard':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.memberContactCard = valueDes;
          break;
        default:
          unhandled.add(key);
          unhandled.add(value);
          break;
      }
    }
  }

  @override
  RegisterOfferGroupInput deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = RegisterOfferGroupInputBuilder();
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

class RegisterOfferGroupInputPlatformTypeEnum extends EnumClass {
  /// Platform type for sending notification.
  @BuiltValueEnumConst(wireName: r'DIDCOMM')
  static const RegisterOfferGroupInputPlatformTypeEnum DIDCOMM =
      _$registerOfferGroupInputPlatformTypeEnum_DIDCOMM;

  /// Platform type for sending notification.
  @BuiltValueEnumConst(wireName: r'PUSH_NOTIFICATION')
  static const RegisterOfferGroupInputPlatformTypeEnum PUSH_NOTIFICATION =
      _$registerOfferGroupInputPlatformTypeEnum_PUSH_NOTIFICATION;

  /// Platform type for sending notification.
  @BuiltValueEnumConst(wireName: r'NONE')
  static const RegisterOfferGroupInputPlatformTypeEnum NONE =
      _$registerOfferGroupInputPlatformTypeEnum_NONE;

  static Serializer<RegisterOfferGroupInputPlatformTypeEnum> get serializer =>
      _$registerOfferGroupInputPlatformTypeEnumSerializer;

  const RegisterOfferGroupInputPlatformTypeEnum._(String name) : super(name);

  static BuiltSet<RegisterOfferGroupInputPlatformTypeEnum> get values =>
      _$registerOfferGroupInputPlatformTypeEnumValues;
  static RegisterOfferGroupInputPlatformTypeEnum valueOf(String name) =>
      _$registerOfferGroupInputPlatformTypeEnumValueOf(name);
}
