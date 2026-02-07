//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'update_offers_score_ok_failed_offers_inner.g.dart';

/// UpdateOffersScoreOKFailedOffersInner
///
/// Properties:
/// * [mnemonic] 
/// * [reason] 
@BuiltValue()
abstract class UpdateOffersScoreOKFailedOffersInner implements Built<UpdateOffersScoreOKFailedOffersInner, UpdateOffersScoreOKFailedOffersInnerBuilder> {
  @BuiltValueField(wireName: r'mnemonic')
  String? get mnemonic;

  @BuiltValueField(wireName: r'reason')
  String? get reason;

  UpdateOffersScoreOKFailedOffersInner._();

  factory UpdateOffersScoreOKFailedOffersInner([void updates(UpdateOffersScoreOKFailedOffersInnerBuilder b)]) = _$UpdateOffersScoreOKFailedOffersInner;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(UpdateOffersScoreOKFailedOffersInnerBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<UpdateOffersScoreOKFailedOffersInner> get serializer => _$UpdateOffersScoreOKFailedOffersInnerSerializer();
}

class _$UpdateOffersScoreOKFailedOffersInnerSerializer implements PrimitiveSerializer<UpdateOffersScoreOKFailedOffersInner> {
  @override
  final Iterable<Type> types = const [UpdateOffersScoreOKFailedOffersInner, _$UpdateOffersScoreOKFailedOffersInner];

  @override
  final String wireName = r'UpdateOffersScoreOKFailedOffersInner';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    UpdateOffersScoreOKFailedOffersInner object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    if (object.mnemonic != null) {
      yield r'mnemonic';
      yield serializers.serialize(
        object.mnemonic,
        specifiedType: const FullType(String),
      );
    }
    if (object.reason != null) {
      yield r'reason';
      yield serializers.serialize(
        object.reason,
        specifiedType: const FullType(String),
      );
    }
  }

  @override
  Object serialize(
    Serializers serializers,
    UpdateOffersScoreOKFailedOffersInner object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required UpdateOffersScoreOKFailedOffersInnerBuilder result,
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
        case r'reason':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.reason = valueDes;
          break;
        default:
          unhandled.add(key);
          unhandled.add(value);
          break;
      }
    }
  }

  @override
  UpdateOffersScoreOKFailedOffersInner deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = UpdateOffersScoreOKFailedOffersInnerBuilder();
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

