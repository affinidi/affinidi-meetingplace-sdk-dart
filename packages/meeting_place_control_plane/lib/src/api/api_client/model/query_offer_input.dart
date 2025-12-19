//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'query_offer_input.g.dart';

/// List of required and optional parameters to find an offer.
///
/// Properties:
/// * [mnemonic] - A unique phrase used to publish and identify the offer.
@BuiltValue()
abstract class QueryOfferInput
    implements Built<QueryOfferInput, QueryOfferInputBuilder> {
  /// A unique phrase used to publish and identify the offer.
  @BuiltValueField(wireName: r'mnemonic')
  String get mnemonic;

  QueryOfferInput._();

  factory QueryOfferInput([void updates(QueryOfferInputBuilder b)]) =
      _$QueryOfferInput;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(QueryOfferInputBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<QueryOfferInput> get serializer =>
      _$QueryOfferInputSerializer();
}

class _$QueryOfferInputSerializer
    implements PrimitiveSerializer<QueryOfferInput> {
  @override
  final Iterable<Type> types = const [QueryOfferInput, _$QueryOfferInput];

  @override
  final String wireName = r'QueryOfferInput';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    QueryOfferInput object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    yield r'mnemonic';
    yield serializers.serialize(
      object.mnemonic,
      specifiedType: const FullType(String),
    );
  }

  @override
  Object serialize(
    Serializers serializers,
    QueryOfferInput object, {
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
    required QueryOfferInputBuilder result,
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
        default:
          unhandled.add(key);
          unhandled.add(value);
          break;
      }
    }
  }

  @override
  QueryOfferInput deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = QueryOfferInputBuilder();
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
