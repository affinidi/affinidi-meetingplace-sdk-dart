//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_collection/built_collection.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

import 'update_offers_score_ok_failed_offers_inner.dart';

part 'update_offers_score_ok.g.dart';

/// UpdateOffersScoreOK
///
/// Properties:
/// * [updatedOffers]
/// * [failedOffers]
@BuiltValue()
abstract class UpdateOffersScoreOK
    implements Built<UpdateOffersScoreOK, UpdateOffersScoreOKBuilder> {
  @BuiltValueField(wireName: r'updatedOffers')
  BuiltList<String> get updatedOffers;

  @BuiltValueField(wireName: r'failedOffers')
  BuiltList<UpdateOffersScoreOKFailedOffersInner> get failedOffers;

  UpdateOffersScoreOK._();

  factory UpdateOffersScoreOK([void updates(UpdateOffersScoreOKBuilder b)]) =
      _$UpdateOffersScoreOK;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(UpdateOffersScoreOKBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<UpdateOffersScoreOK> get serializer =>
      _$UpdateOffersScoreOKSerializer();
}

class _$UpdateOffersScoreOKSerializer
    implements PrimitiveSerializer<UpdateOffersScoreOK> {
  @override
  final Iterable<Type> types = const [
    UpdateOffersScoreOK,
    _$UpdateOffersScoreOK,
  ];

  @override
  final String wireName = r'UpdateOffersScoreOK';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    UpdateOffersScoreOK object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    yield r'updatedOffers';
    yield serializers.serialize(
      object.updatedOffers,
      specifiedType: const FullType(BuiltList, [FullType(String)]),
    );
    yield r'failedOffers';
    yield serializers.serialize(
      object.failedOffers,
      specifiedType: const FullType(BuiltList, [
        FullType(UpdateOffersScoreOKFailedOffersInner),
      ]),
    );
  }

  @override
  Object serialize(
    Serializers serializers,
    UpdateOffersScoreOK object, {
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
    required UpdateOffersScoreOKBuilder result,
    required List<Object?> unhandled,
  }) {
    for (var i = 0; i < serializedList.length; i += 2) {
      final key = serializedList[i] as String;
      final value = serializedList[i + 1];
      switch (key) {
        case r'updatedOffers':
          final valueDes =
              serializers.deserialize(
                    value,
                    specifiedType: const FullType(BuiltList, [
                      FullType(String),
                    ]),
                  )
                  as BuiltList<String>;
          result.updatedOffers.replace(valueDes);
          break;
        case r'failedOffers':
          final valueDes =
              serializers.deserialize(
                    value,
                    specifiedType: const FullType(BuiltList, [
                      FullType(UpdateOffersScoreOKFailedOffersInner),
                    ]),
                  )
                  as BuiltList<UpdateOffersScoreOKFailedOffersInner>;
          result.failedOffers.replace(valueDes);
          break;
        default:
          unhandled.add(key);
          unhandled.add(value);
          break;
      }
    }
  }

  @override
  UpdateOffersScoreOK deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = UpdateOffersScoreOKBuilder();
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
