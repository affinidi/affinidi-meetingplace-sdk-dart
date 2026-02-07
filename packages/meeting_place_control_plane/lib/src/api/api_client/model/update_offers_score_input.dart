//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_collection/built_collection.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'update_offers_score_input.g.dart';

/// UpdateOffersScoreInput
///
/// Properties:
/// * [score] - Latest score to set.
/// * [mnemonics] - List of mnemonics to update.
@BuiltValue()
abstract class UpdateOffersScoreInput
    implements Built<UpdateOffersScoreInput, UpdateOffersScoreInputBuilder> {
  /// Latest score to set.
  @BuiltValueField(wireName: r'score')
  int get score;

  /// List of mnemonics to update.
  @BuiltValueField(wireName: r'mnemonics')
  BuiltList<String> get mnemonics;

  UpdateOffersScoreInput._();

  factory UpdateOffersScoreInput([
    void updates(UpdateOffersScoreInputBuilder b),
  ]) = _$UpdateOffersScoreInput;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(UpdateOffersScoreInputBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<UpdateOffersScoreInput> get serializer =>
      _$UpdateOffersScoreInputSerializer();
}

class _$UpdateOffersScoreInputSerializer
    implements PrimitiveSerializer<UpdateOffersScoreInput> {
  @override
  final Iterable<Type> types = const [
    UpdateOffersScoreInput,
    _$UpdateOffersScoreInput,
  ];

  @override
  final String wireName = r'UpdateOffersScoreInput';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    UpdateOffersScoreInput object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    yield r'score';
    yield serializers.serialize(
      object.score,
      specifiedType: const FullType(int),
    );
    yield r'mnemonics';
    yield serializers.serialize(
      object.mnemonics,
      specifiedType: const FullType(BuiltList, [FullType(String)]),
    );
  }

  @override
  Object serialize(
    Serializers serializers,
    UpdateOffersScoreInput object, {
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
    required UpdateOffersScoreInputBuilder result,
    required List<Object?> unhandled,
  }) {
    for (var i = 0; i < serializedList.length; i += 2) {
      final key = serializedList[i] as String;
      final value = serializedList[i + 1];
      switch (key) {
        case r'score':
          final valueDes =
              serializers.deserialize(value, specifiedType: const FullType(int))
                  as int;
          result.score = valueDes;
          break;
        case r'mnemonics':
          final valueDes =
              serializers.deserialize(
                    value,
                    specifiedType: const FullType(BuiltList, [
                      FullType(String),
                    ]),
                  )
                  as BuiltList<String>;
          result.mnemonics.replace(valueDes);
          break;
        default:
          unhandled.add(key);
          unhandled.add(value);
          break;
      }
    }
  }

  @override
  UpdateOffersScoreInput deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = UpdateOffersScoreInputBuilder();
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
