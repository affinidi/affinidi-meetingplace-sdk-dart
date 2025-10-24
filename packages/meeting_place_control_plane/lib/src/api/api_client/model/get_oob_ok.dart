//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'get_oob_ok.g.dart';

/// GetOobOK
///
/// Properties:
/// * [didcommMessage] - The payload of the OOB offer
/// * [mediatorDid] - Mediator did for the OOB offer
/// * [mediatorEndpoint] - Mediator endpoint for the OOB offer
/// * [mediatorWSSEndpoint] - Websocket endpoint for the mediator
@BuiltValue()
abstract class GetOobOK implements Built<GetOobOK, GetOobOKBuilder> {
  /// The payload of the OOB offer
  @BuiltValueField(wireName: r'didcommMessage')
  String get didcommMessage;

  /// Mediator did for the OOB offer
  @BuiltValueField(wireName: r'mediatorDid')
  String get mediatorDid;

  /// Mediator endpoint for the OOB offer
  @BuiltValueField(wireName: r'mediatorEndpoint')
  String get mediatorEndpoint;

  /// Websocket endpoint for the mediator
  @BuiltValueField(wireName: r'mediatorWSSEndpoint')
  String get mediatorWSSEndpoint;

  GetOobOK._();

  factory GetOobOK([void updates(GetOobOKBuilder b)]) = _$GetOobOK;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(GetOobOKBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<GetOobOK> get serializer => _$GetOobOKSerializer();
}

class _$GetOobOKSerializer implements PrimitiveSerializer<GetOobOK> {
  @override
  final Iterable<Type> types = const [GetOobOK, _$GetOobOK];

  @override
  final String wireName = r'GetOobOK';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    GetOobOK object, {
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
    GetOobOK object, {
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
    required GetOobOKBuilder result,
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
  GetOobOK deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = GetOobOKBuilder();
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
