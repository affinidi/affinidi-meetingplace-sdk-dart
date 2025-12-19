//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'cors_register_device_ok.g.dart';

/// CorsRegisterDeviceOK
///
/// Properties:
/// * [corsRegisterDeviceOk]
@BuiltValue()
abstract class CorsRegisterDeviceOK
    implements Built<CorsRegisterDeviceOK, CorsRegisterDeviceOKBuilder> {
  @BuiltValueField(wireName: r'corsRegisterDeviceOk')
  String? get corsRegisterDeviceOk;

  CorsRegisterDeviceOK._();

  factory CorsRegisterDeviceOK([void updates(CorsRegisterDeviceOKBuilder b)]) =
      _$CorsRegisterDeviceOK;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(CorsRegisterDeviceOKBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<CorsRegisterDeviceOK> get serializer =>
      _$CorsRegisterDeviceOKSerializer();
}

class _$CorsRegisterDeviceOKSerializer
    implements PrimitiveSerializer<CorsRegisterDeviceOK> {
  @override
  final Iterable<Type> types = const [
    CorsRegisterDeviceOK,
    _$CorsRegisterDeviceOK,
  ];

  @override
  final String wireName = r'CorsRegisterDeviceOK';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    CorsRegisterDeviceOK object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    if (object.corsRegisterDeviceOk != null) {
      yield r'corsRegisterDeviceOk';
      yield serializers.serialize(
        object.corsRegisterDeviceOk,
        specifiedType: const FullType(String),
      );
    }
  }

  @override
  Object serialize(
    Serializers serializers,
    CorsRegisterDeviceOK object, {
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
    required CorsRegisterDeviceOKBuilder result,
    required List<Object?> unhandled,
  }) {
    for (var i = 0; i < serializedList.length; i += 2) {
      final key = serializedList[i] as String;
      final value = serializedList[i + 1];
      switch (key) {
        case r'corsRegisterDeviceOk':
          final valueDes =
              serializers.deserialize(
                    value,
                    specifiedType: const FullType(String),
                  )
                  as String;
          result.corsRegisterDeviceOk = valueDes;
          break;
        default:
          unhandled.add(key);
          unhandled.add(value);
          break;
      }
    }
  }

  @override
  CorsRegisterDeviceOK deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = CorsRegisterDeviceOKBuilder();
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
