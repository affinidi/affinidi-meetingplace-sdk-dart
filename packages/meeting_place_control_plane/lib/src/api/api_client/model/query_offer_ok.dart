//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'query_offer_ok.g.dart';

/// QueryOfferOK
///
/// Properties:
/// * [status]
/// * [message]
/// * [offerLink]
/// * [name]
/// * [description]
/// * [validUntil] - validity date and time in ISO-8601 format, e.g. 2023-09-20T07:12:13
/// * [contactCard] - A ContactCard containing the details of the offer encoded in base64 format.
/// * [contactAttributes] - A bitfield of contact attributes
/// * [offerType] - Offer type information
/// * [mediatorDid] - The mediator DID use to register the offer.
/// * [mediatorEndpoint] - The mediator endpoint to register the offer.
/// * [mediatorWSSEndpoint] - The websocket endpoint of the mediator to register the offer.
/// * [didcommMessage] - The didcomm message connected to this offer
/// * [maximumUsage] - maximum number of times this offer can be claimed, or 0 for unlimited
/// * [groupId]
/// * [groupDid]
/// * [reputation] - publisher reputation (e.g. VRC count)
@BuiltValue()
abstract class QueryOfferOK
    implements Built<QueryOfferOK, QueryOfferOKBuilder> {
  @BuiltValueField(wireName: r'status')
  String get status;

  @BuiltValueField(wireName: r'message')
  String? get message;

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

  /// A bitfield of contact attributes
  @BuiltValueField(wireName: r'contactAttributes')
  int get contactAttributes;

  /// Offer type information
  @BuiltValueField(wireName: r'offerType')
  int? get offerType;

  /// The mediator DID use to register the offer.
  @BuiltValueField(wireName: r'mediatorDid')
  String get mediatorDid;

  /// The mediator endpoint to register the offer.
  @BuiltValueField(wireName: r'mediatorEndpoint')
  String get mediatorEndpoint;

  /// The websocket endpoint of the mediator to register the offer.
  @BuiltValueField(wireName: r'mediatorWSSEndpoint')
  String get mediatorWSSEndpoint;

  /// The didcomm message connected to this offer
  @BuiltValueField(wireName: r'didcommMessage')
  String get didcommMessage;

  /// maximum number of times this offer can be claimed, or 0 for unlimited
  @BuiltValueField(wireName: r'maximumUsage')
  int? get maximumUsage;

  @BuiltValueField(wireName: r'groupId')
  String? get groupId;

  @BuiltValueField(wireName: r'groupDid')
  String? get groupDid;

  /// Publisher reputation (e.g. VRC count).
  @BuiltValueField(wireName: r'reputation')
  int? get reputation;

  QueryOfferOK._();

  factory QueryOfferOK([void updates(QueryOfferOKBuilder b)]) = _$QueryOfferOK;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(QueryOfferOKBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<QueryOfferOK> get serializer => _$QueryOfferOKSerializer();
}

class _$QueryOfferOKSerializer implements PrimitiveSerializer<QueryOfferOK> {
  @override
  final Iterable<Type> types = const [QueryOfferOK, _$QueryOfferOK];

  @override
  final String wireName = r'QueryOfferOK';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    QueryOfferOK object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    yield r'status';
    yield serializers.serialize(
      object.status,
      specifiedType: const FullType(String),
    );
    if (object.message != null) {
      yield r'message';
      yield serializers.serialize(
        object.message,
        specifiedType: const FullType(String),
      );
    }
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
    yield r'contactAttributes';
    yield serializers.serialize(
      object.contactAttributes,
      specifiedType: const FullType(int),
    );
    if (object.offerType != null) {
      yield r'offerType';
      yield serializers.serialize(
        object.offerType,
        specifiedType: const FullType(int),
      );
    }
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
    yield r'didcommMessage';
    yield serializers.serialize(
      object.didcommMessage,
      specifiedType: const FullType(String),
    );
    if (object.maximumUsage != null) {
      yield r'maximumUsage';
      yield serializers.serialize(
        object.maximumUsage,
        specifiedType: const FullType(int),
      );
    }
    if (object.groupId != null) {
      yield r'groupId';
      yield serializers.serialize(
        object.groupId,
        specifiedType: const FullType(String),
      );
    }
    if (object.groupDid != null) {
      yield r'groupDid';
      yield serializers.serialize(
        object.groupDid,
        specifiedType: const FullType(String),
      );
    }
  }

  @override
  Object serialize(
    Serializers serializers,
    QueryOfferOK object, {
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
    required QueryOfferOKBuilder result,
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
        case r'contactAttributes':
          final valueDes =
              serializers.deserialize(value, specifiedType: const FullType(int))
                  as int;
          result.contactAttributes = valueDes;
          break;
        case r'offerType':
          final valueDes =
              serializers.deserialize(value, specifiedType: const FullType(int))
                  as int;
          result.offerType = valueDes;
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
        case r'didcommMessage':
          final valueDes =
              serializers.deserialize(
                    value,
                    specifiedType: const FullType(String),
                  )
                  as String;
          result.didcommMessage = valueDes;
          break;
        case r'maximumUsage':
          final valueDes =
              serializers.deserialize(value, specifiedType: const FullType(int))
                  as int;
          result.maximumUsage = valueDes;
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
        case r'groupDid':
          final valueDes =
              serializers.deserialize(
                    value,
                    specifiedType: const FullType(String),
                  )
                  as String;
          result.groupDid = valueDes;
          break;
        default:
          unhandled.add(key);
          unhandled.add(value);
          break;
      }
    }
  }

  @override
  QueryOfferOK deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = QueryOfferOKBuilder();
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
