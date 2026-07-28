// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'key_models.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$VtaKeyRecord {

@JsonKey(name: 'key_id') String get keyId;@JsonKey(name: 'key_type') String get keyType;@JsonKey(name: 'context_id') String? get contextId; String? get label; String? get status;
/// Create a copy of VtaKeyRecord
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$VtaKeyRecordCopyWith<VtaKeyRecord> get copyWith => _$VtaKeyRecordCopyWithImpl<VtaKeyRecord>(this as VtaKeyRecord, _$identity);

  /// Serializes this VtaKeyRecord to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is VtaKeyRecord&&(identical(other.keyId, keyId) || other.keyId == keyId)&&(identical(other.keyType, keyType) || other.keyType == keyType)&&(identical(other.contextId, contextId) || other.contextId == contextId)&&(identical(other.label, label) || other.label == label)&&(identical(other.status, status) || other.status == status));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,keyId,keyType,contextId,label,status);

@override
String toString() {
  return 'VtaKeyRecord(keyId: $keyId, keyType: $keyType, contextId: $contextId, label: $label, status: $status)';
}


}

/// @nodoc
abstract mixin class $VtaKeyRecordCopyWith<$Res>  {
  factory $VtaKeyRecordCopyWith(VtaKeyRecord value, $Res Function(VtaKeyRecord) _then) = _$VtaKeyRecordCopyWithImpl;
@useResult
$Res call({
@JsonKey(name: 'key_id') String keyId,@JsonKey(name: 'key_type') String keyType,@JsonKey(name: 'context_id') String? contextId, String? label, String? status
});




}
/// @nodoc
class _$VtaKeyRecordCopyWithImpl<$Res>
    implements $VtaKeyRecordCopyWith<$Res> {
  _$VtaKeyRecordCopyWithImpl(this._self, this._then);

  final VtaKeyRecord _self;
  final $Res Function(VtaKeyRecord) _then;

/// Create a copy of VtaKeyRecord
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? keyId = null,Object? keyType = null,Object? contextId = freezed,Object? label = freezed,Object? status = freezed,}) {
  return _then(_self.copyWith(
keyId: null == keyId ? _self.keyId : keyId // ignore: cast_nullable_to_non_nullable
as String,keyType: null == keyType ? _self.keyType : keyType // ignore: cast_nullable_to_non_nullable
as String,contextId: freezed == contextId ? _self.contextId : contextId // ignore: cast_nullable_to_non_nullable
as String?,label: freezed == label ? _self.label : label // ignore: cast_nullable_to_non_nullable
as String?,status: freezed == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [VtaKeyRecord].
extension VtaKeyRecordPatterns on VtaKeyRecord {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _VtaKeyRecord value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _VtaKeyRecord() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _VtaKeyRecord value)  $default,){
final _that = this;
switch (_that) {
case _VtaKeyRecord():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _VtaKeyRecord value)?  $default,){
final _that = this;
switch (_that) {
case _VtaKeyRecord() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function(@JsonKey(name: 'key_id')  String keyId, @JsonKey(name: 'key_type')  String keyType, @JsonKey(name: 'context_id')  String? contextId,  String? label,  String? status)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _VtaKeyRecord() when $default != null:
return $default(_that.keyId,_that.keyType,_that.contextId,_that.label,_that.status);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function(@JsonKey(name: 'key_id')  String keyId, @JsonKey(name: 'key_type')  String keyType, @JsonKey(name: 'context_id')  String? contextId,  String? label,  String? status)  $default,) {final _that = this;
switch (_that) {
case _VtaKeyRecord():
return $default(_that.keyId,_that.keyType,_that.contextId,_that.label,_that.status);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function(@JsonKey(name: 'key_id')  String keyId, @JsonKey(name: 'key_type')  String keyType, @JsonKey(name: 'context_id')  String? contextId,  String? label,  String? status)?  $default,) {final _that = this;
switch (_that) {
case _VtaKeyRecord() when $default != null:
return $default(_that.keyId,_that.keyType,_that.contextId,_that.label,_that.status);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _VtaKeyRecord implements VtaKeyRecord {
  const _VtaKeyRecord({@JsonKey(name: 'key_id') required this.keyId, @JsonKey(name: 'key_type') required this.keyType, @JsonKey(name: 'context_id') this.contextId, this.label, this.status});
  factory _VtaKeyRecord.fromJson(Map<String, dynamic> json) => _$VtaKeyRecordFromJson(json);

@override@JsonKey(name: 'key_id') final  String keyId;
@override@JsonKey(name: 'key_type') final  String keyType;
@override@JsonKey(name: 'context_id') final  String? contextId;
@override final  String? label;
@override final  String? status;

/// Create a copy of VtaKeyRecord
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$VtaKeyRecordCopyWith<_VtaKeyRecord> get copyWith => __$VtaKeyRecordCopyWithImpl<_VtaKeyRecord>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$VtaKeyRecordToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _VtaKeyRecord&&(identical(other.keyId, keyId) || other.keyId == keyId)&&(identical(other.keyType, keyType) || other.keyType == keyType)&&(identical(other.contextId, contextId) || other.contextId == contextId)&&(identical(other.label, label) || other.label == label)&&(identical(other.status, status) || other.status == status));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,keyId,keyType,contextId,label,status);

@override
String toString() {
  return 'VtaKeyRecord(keyId: $keyId, keyType: $keyType, contextId: $contextId, label: $label, status: $status)';
}


}

/// @nodoc
abstract mixin class _$VtaKeyRecordCopyWith<$Res> implements $VtaKeyRecordCopyWith<$Res> {
  factory _$VtaKeyRecordCopyWith(_VtaKeyRecord value, $Res Function(_VtaKeyRecord) _then) = __$VtaKeyRecordCopyWithImpl;
@override @useResult
$Res call({
@JsonKey(name: 'key_id') String keyId,@JsonKey(name: 'key_type') String keyType,@JsonKey(name: 'context_id') String? contextId, String? label, String? status
});




}
/// @nodoc
class __$VtaKeyRecordCopyWithImpl<$Res>
    implements _$VtaKeyRecordCopyWith<$Res> {
  __$VtaKeyRecordCopyWithImpl(this._self, this._then);

  final _VtaKeyRecord _self;
  final $Res Function(_VtaKeyRecord) _then;

/// Create a copy of VtaKeyRecord
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? keyId = null,Object? keyType = null,Object? contextId = freezed,Object? label = freezed,Object? status = freezed,}) {
  return _then(_VtaKeyRecord(
keyId: null == keyId ? _self.keyId : keyId // ignore: cast_nullable_to_non_nullable
as String,keyType: null == keyType ? _self.keyType : keyType // ignore: cast_nullable_to_non_nullable
as String,contextId: freezed == contextId ? _self.contextId : contextId // ignore: cast_nullable_to_non_nullable
as String?,label: freezed == label ? _self.label : label // ignore: cast_nullable_to_non_nullable
as String?,status: freezed == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

// dart format on
