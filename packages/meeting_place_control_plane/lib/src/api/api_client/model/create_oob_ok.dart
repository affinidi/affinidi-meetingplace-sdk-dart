//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'create_oob_ok.g.dart';

/// CreateOobOK
///
/// Properties:
/// * [oobUrl] - The full URL of the OOB offer created
/// * [oobId] - The unique identifier of the OOB offer created.
@BuiltValue()
abstract class CreateOobOK implements Built<CreateOobOK, CreateOobOKBuilder> {
  /// The full URL of the OOB offer created
  @BuiltValueField(wireName: r'oobUrl')
  String get oobUrl;

  /// The unique identifier of the OOB offer created.
  @BuiltValueField(wireName: r'oobId')
  String get oobId;

  CreateOobOK._();

  factory CreateOobOK([void updates(CreateOobOKBuilder b)]) = _$CreateOobOK;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(CreateOobOKBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<CreateOobOK> get serializer => _$CreateOobOKSerializer();
}

class _$CreateOobOKSerializer implements PrimitiveSerializer<CreateOobOK> {
  @override
  final Iterable<Type> types = const [CreateOobOK, _$CreateOobOK];

  @override
  final String wireName = r'CreateOobOK';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    CreateOobOK object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    yield r'oobUrl';
    yield serializers.serialize(
      object.oobUrl,
      specifiedType: const FullType(String),
    );
    yield r'oobId';
    yield serializers.serialize(
      object.oobId,
      specifiedType: const FullType(String),
    );
  }

  @override
  Object serialize(
    Serializers serializers,
    CreateOobOK object, {
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
    required CreateOobOKBuilder result,
    required List<Object?> unhandled,
  }) {
    for (var i = 0; i < serializedList.length; i += 2) {
      final key = serializedList[i] as String;
      final value = serializedList[i + 1];
      switch (key) {
        case r'oobUrl':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.oobUrl = valueDes;
          break;
        case r'oobId':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.oobId = valueDes;
          break;
        default:
          unhandled.add(key);
          unhandled.add(value);
          break;
      }
    }
  }

  @override
  CreateOobOK deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = CreateOobOKBuilder();
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
