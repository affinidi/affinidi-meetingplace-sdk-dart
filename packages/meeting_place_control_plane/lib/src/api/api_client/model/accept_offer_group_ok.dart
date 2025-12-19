//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'accept_offer_group_ok.g.dart';

/// AcceptOfferGroupOK
///
/// Properties:
/// * [status]
/// * [message]
/// * [didcommMessage]
/// * [offerLink]
/// * [name]
/// * [description]
/// * [validUntil] - validity date and time in ISO-8601 format, e.g. 2023-09-20T07:12:13
/// * [contactCard] - A ContactCard containing the details of the offer encoded in base64 format.
/// * [mediatorDid] - The mediator DID use to register the offer.
/// * [mediatorEndpoint] - The mediator endpoint to register the offer.
/// * [mediatorWSSEndpoint] - The websocket endpoint of the mediator to register the offer.
@BuiltValue()
abstract class AcceptOfferGroupOK
    implements Built<AcceptOfferGroupOK, AcceptOfferGroupOKBuilder> {
  @BuiltValueField(wireName: r'status')
  String? get status;

  @BuiltValueField(wireName: r'message')
  String? get message;

  @BuiltValueField(wireName: r'didcommMessage')
  String get didcommMessage;

  @BuiltValueField(wireName: r'offerLink')
  String get offerLink;

  @BuiltValueField(wireName: r'name')
  String get name;

  @BuiltValueField(wireName: r'description')
  String get description;

  /// validity date and time in ISO-8601 format, e.g. 2023-09-20T07:12:13
  @BuiltValueField(wireName: r'validUntil')
  String? get validUntil;

  /// A ContactCard containing the details of the offer encoded in base64 format.
  @BuiltValueField(wireName: r'contactCard')
  String get contactCard;

  /// The mediator DID use to register the offer.
  @BuiltValueField(wireName: r'mediatorDid')
  String get mediatorDid;

  /// The mediator endpoint to register the offer.
  @BuiltValueField(wireName: r'mediatorEndpoint')
  String get mediatorEndpoint;

  /// The websocket endpoint of the mediator to register the offer.
  @BuiltValueField(wireName: r'mediatorWSSEndpoint')
  String get mediatorWSSEndpoint;

  AcceptOfferGroupOK._();

  factory AcceptOfferGroupOK([void updates(AcceptOfferGroupOKBuilder b)]) =
      _$AcceptOfferGroupOK;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(AcceptOfferGroupOKBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<AcceptOfferGroupOK> get serializer =>
      _$AcceptOfferGroupOKSerializer();
}

class _$AcceptOfferGroupOKSerializer
    implements PrimitiveSerializer<AcceptOfferGroupOK> {
  @override
  final Iterable<Type> types = const [AcceptOfferGroupOK, _$AcceptOfferGroupOK];

  @override
  final String wireName = r'AcceptOfferGroupOK';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    AcceptOfferGroupOK object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    if (object.status != null) {
      yield r'status';
      yield serializers.serialize(
        object.status,
        specifiedType: const FullType(String),
      );
    }
    if (object.message != null) {
      yield r'message';
      yield serializers.serialize(
        object.message,
        specifiedType: const FullType(String),
      );
    }
    yield r'didcommMessage';
    yield serializers.serialize(
      object.didcommMessage,
      specifiedType: const FullType(String),
    );
    yield r'offerLink';
    yield serializers.serialize(
      object.offerLink,
      specifiedType: const FullType(String),
    );
    yield r'name';
    yield serializers.serialize(
      object.name,
      specifiedType: const FullType(String),
    );
    yield r'description';
    yield serializers.serialize(
      object.description,
      specifiedType: const FullType(String),
    );
    if (object.validUntil != null) {
      yield r'validUntil';
      yield serializers.serialize(
        object.validUntil,
        specifiedType: const FullType(String),
      );
    }
    yield r'contactCard';
    yield serializers.serialize(
      object.contactCard,
      specifiedType: const FullType(String),
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
  }

  @override
  Object serialize(
    Serializers serializers,
    AcceptOfferGroupOK object, {
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
    required AcceptOfferGroupOKBuilder result,
    required List<Object?> unhandled,
  }) {
    for (var i = 0; i < serializedList.length; i += 2) {
      final key = serializedList[i] as String;
      final value = serializedList[i + 1];
      switch (key) {
        case r'status':
          final valueDes =
              serializers.deserialize(
                    value,
                    specifiedType: const FullType(String),
                  )
                  as String;
          result.status = valueDes;
          break;
        case r'message':
          final valueDes =
              serializers.deserialize(
                    value,
                    specifiedType: const FullType(String),
                  )
                  as String;
          result.message = valueDes;
          break;
        case r'didcommMessage':
          final valueDes =
              serializers.deserialize(
                    value,
                    specifiedType: const FullType(String),
                  )
                  as String;
          result.didcommMessage = valueDes;
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
        case r'name':
          final valueDes =
              serializers.deserialize(
                    value,
                    specifiedType: const FullType(String),
                  )
                  as String;
          result.name = valueDes;
          break;
        case r'description':
          final valueDes =
              serializers.deserialize(
                    value,
                    specifiedType: const FullType(String),
                  )
                  as String;
          result.description = valueDes;
          break;
        case r'validUntil':
          final valueDes =
              serializers.deserialize(
                    value,
                    specifiedType: const FullType(String),
                  )
                  as String;
          result.validUntil = valueDes;
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
        case r'mediatorDid':
          final valueDes =
              serializers.deserialize(
                    value,
                    specifiedType: const FullType(String),
                  )
                  as String;
          result.mediatorDid = valueDes;
          break;
        case r'mediatorEndpoint':
          final valueDes =
              serializers.deserialize(
                    value,
                    specifiedType: const FullType(String),
                  )
                  as String;
          result.mediatorEndpoint = valueDes;
          break;
        case r'mediatorWSSEndpoint':
          final valueDes =
              serializers.deserialize(
                    value,
                    specifiedType: const FullType(String),
                  )
                  as String;
          result.mediatorWSSEndpoint = valueDes;
          break;
        default:
          unhandled.add(key);
          unhandled.add(value);
          break;
      }
    }
  }

  @override
  AcceptOfferGroupOK deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = AcceptOfferGroupOKBuilder();
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
