//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'notify_outreach_input.g.dart';

/// NotifyOutreachInput
///
/// Properties:
/// * [mnemonic] - A unique phrase used to publish and identify the offer.
/// * [senderInfo] - Sender info to be shown in notification message.
@BuiltValue()
abstract class NotifyOutreachInput
    implements Built<NotifyOutreachInput, NotifyOutreachInputBuilder> {
  /// A unique phrase used to publish and identify the offer.
  @BuiltValueField(wireName: r'mnemonic')
  String get mnemonic;

  /// Sender info to be shown in notification message.
  @BuiltValueField(wireName: r'senderInfo')
  String get senderInfo;

  NotifyOutreachInput._();

  factory NotifyOutreachInput([void updates(NotifyOutreachInputBuilder b)]) =
      _$NotifyOutreachInput;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(NotifyOutreachInputBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<NotifyOutreachInput> get serializer =>
      _$NotifyOutreachInputSerializer();
}

class _$NotifyOutreachInputSerializer
    implements PrimitiveSerializer<NotifyOutreachInput> {
  @override
  final Iterable<Type> types = const [
    NotifyOutreachInput,
    _$NotifyOutreachInput,
  ];

  @override
  final String wireName = r'NotifyOutreachInput';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    NotifyOutreachInput object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    yield r'mnemonic';
    yield serializers.serialize(
      object.mnemonic,
      specifiedType: const FullType(String),
    );
    yield r'senderInfo';
    yield serializers.serialize(
      object.senderInfo,
      specifiedType: const FullType(String),
    );
  }

  @override
  Object serialize(
    Serializers serializers,
    NotifyOutreachInput object, {
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
    required NotifyOutreachInputBuilder result,
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
        case r'senderInfo':
          final valueDes =
              serializers.deserialize(
                    value,
                    specifiedType: const FullType(String),
                  )
                  as String;
          result.senderInfo = valueDes;
          break;
        default:
          unhandled.add(key);
          unhandled.add(value);
          break;
      }
    }
  }

  @override
  NotifyOutreachInput deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = NotifyOutreachInputBuilder();
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
