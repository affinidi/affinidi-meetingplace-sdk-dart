//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'create_oob_input.g.dart';

/// CreateOobInput
///
/// Properties:
/// * [didcommMessage] - A plaintext DIDComm message containing the offer encoded in base64.
/// * [mediatorDid] - The mediator DID use to register the offer.
/// * [mediatorEndpoint] - The mediator endpoint to register the offer.
/// * [mediatorWSSEndpoint] - The websocket endpoint of the mediator to register the offer.
@BuiltValue()
abstract class CreateOobInput
    implements Built<CreateOobInput, CreateOobInputBuilder> {
  /// A plaintext DIDComm message containing the offer encoded in base64.
  @BuiltValueField(wireName: r'didcommMessage')
  String get didcommMessage;

  /// The mediator DID use to register the offer.
  @BuiltValueField(wireName: r'mediatorDid')
  String get mediatorDid;

  /// The mediator endpoint to register the offer.
  @BuiltValueField(wireName: r'mediatorEndpoint')
  String get mediatorEndpoint;

  /// The websocket endpoint of the mediator to register the offer.
  @BuiltValueField(wireName: r'mediatorWSSEndpoint')
  String get mediatorWSSEndpoint;

  CreateOobInput._();

  factory CreateOobInput([void updates(CreateOobInputBuilder b)]) =
      _$CreateOobInput;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(CreateOobInputBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<CreateOobInput> get serializer =>
      _$CreateOobInputSerializer();
}

class _$CreateOobInputSerializer
    implements PrimitiveSerializer<CreateOobInput> {
  @override
  final Iterable<Type> types = const [CreateOobInput, _$CreateOobInput];

  @override
  final String wireName = r'CreateOobInput';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    CreateOobInput object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    yield r'didcommMessage';
    yield serializers.serialize(
      object.didcommMessage,
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
    CreateOobInput object, {
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
    required CreateOobInputBuilder result,
    required List<Object?> unhandled,
  }) {
    for (var i = 0; i < serializedList.length; i += 2) {
      final key = serializedList[i] as String;
      final value = serializedList[i + 1];
      switch (key) {
        case r'didcommMessage':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.didcommMessage = valueDes;
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
        default:
          unhandled.add(key);
          unhandled.add(value);
          break;
      }
    }
  }

  @override
  CreateOobInput deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = CreateOobInputBuilder();
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
