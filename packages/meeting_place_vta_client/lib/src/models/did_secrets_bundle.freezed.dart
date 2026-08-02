// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'did_secrets_bundle.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$DidSecretEntry {

@JsonKey(name: 'key_id') String get keyId;@JsonKey(name: 'key_type') String get keyType;@JsonKey(name: 'private_key_multibase') String get privateKeyMultibase;
/// Create a copy of DidSecretEntry
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$DidSecretEntryCopyWith<DidSecretEntry> get copyWith => _$DidSecretEntryCopyWithImpl<DidSecretEntry>(this as DidSecretEntry, _$identity);

  /// Serializes this DidSecretEntry to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is DidSecretEntry&&(identical(other.keyId, keyId) || other.keyId == keyId)&&(identical(other.keyType, keyType) || other.keyType == keyType)&&(identical(other.privateKeyMultibase, privateKeyMultibase) || other.privateKeyMultibase == privateKeyMultibase));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,keyId,keyType,privateKeyMultibase);

@override
String toString() {
  return 'DidSecretEntry(keyId: $keyId, keyType: $keyType, privateKeyMultibase: $privateKeyMultibase)';
}


}

/// @nodoc
abstract mixin class $DidSecretEntryCopyWith<$Res>  {
  factory $DidSecretEntryCopyWith(DidSecretEntry value, $Res Function(DidSecretEntry) _then) = _$DidSecretEntryCopyWithImpl;
@useResult
$Res call({
@JsonKey(name: 'key_id') String keyId,@JsonKey(name: 'key_type') String keyType,@JsonKey(name: 'private_key_multibase') String privateKeyMultibase
});




}
/// @nodoc
class _$DidSecretEntryCopyWithImpl<$Res>
    implements $DidSecretEntryCopyWith<$Res> {
  _$DidSecretEntryCopyWithImpl(this._self, this._then);

  final DidSecretEntry _self;
  final $Res Function(DidSecretEntry) _then;

/// Create a copy of DidSecretEntry
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? keyId = null,Object? keyType = null,Object? privateKeyMultibase = null,}) {
  return _then(_self.copyWith(
keyId: null == keyId ? _self.keyId : keyId // ignore: cast_nullable_to_non_nullable
as String,keyType: null == keyType ? _self.keyType : keyType // ignore: cast_nullable_to_non_nullable
as String,privateKeyMultibase: null == privateKeyMultibase ? _self.privateKeyMultibase : privateKeyMultibase // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [DidSecretEntry].
extension DidSecretEntryPatterns on DidSecretEntry {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _DidSecretEntry value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _DidSecretEntry() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _DidSecretEntry value)  $default,){
final _that = this;
switch (_that) {
case _DidSecretEntry():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _DidSecretEntry value)?  $default,){
final _that = this;
switch (_that) {
case _DidSecretEntry() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function(@JsonKey(name: 'key_id')  String keyId, @JsonKey(name: 'key_type')  String keyType, @JsonKey(name: 'private_key_multibase')  String privateKeyMultibase)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _DidSecretEntry() when $default != null:
return $default(_that.keyId,_that.keyType,_that.privateKeyMultibase);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function(@JsonKey(name: 'key_id')  String keyId, @JsonKey(name: 'key_type')  String keyType, @JsonKey(name: 'private_key_multibase')  String privateKeyMultibase)  $default,) {final _that = this;
switch (_that) {
case _DidSecretEntry():
return $default(_that.keyId,_that.keyType,_that.privateKeyMultibase);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function(@JsonKey(name: 'key_id')  String keyId, @JsonKey(name: 'key_type')  String keyType, @JsonKey(name: 'private_key_multibase')  String privateKeyMultibase)?  $default,) {final _that = this;
switch (_that) {
case _DidSecretEntry() when $default != null:
return $default(_that.keyId,_that.keyType,_that.privateKeyMultibase);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _DidSecretEntry implements DidSecretEntry {
  const _DidSecretEntry({@JsonKey(name: 'key_id') required this.keyId, @JsonKey(name: 'key_type') required this.keyType, @JsonKey(name: 'private_key_multibase') required this.privateKeyMultibase});
  factory _DidSecretEntry.fromJson(Map<String, dynamic> json) => _$DidSecretEntryFromJson(json);

@override@JsonKey(name: 'key_id') final  String keyId;
@override@JsonKey(name: 'key_type') final  String keyType;
@override@JsonKey(name: 'private_key_multibase') final  String privateKeyMultibase;

/// Create a copy of DidSecretEntry
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$DidSecretEntryCopyWith<_DidSecretEntry> get copyWith => __$DidSecretEntryCopyWithImpl<_DidSecretEntry>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$DidSecretEntryToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _DidSecretEntry&&(identical(other.keyId, keyId) || other.keyId == keyId)&&(identical(other.keyType, keyType) || other.keyType == keyType)&&(identical(other.privateKeyMultibase, privateKeyMultibase) || other.privateKeyMultibase == privateKeyMultibase));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,keyId,keyType,privateKeyMultibase);

@override
String toString() {
  return 'DidSecretEntry(keyId: $keyId, keyType: $keyType, privateKeyMultibase: $privateKeyMultibase)';
}


}

/// @nodoc
abstract mixin class _$DidSecretEntryCopyWith<$Res> implements $DidSecretEntryCopyWith<$Res> {
  factory _$DidSecretEntryCopyWith(_DidSecretEntry value, $Res Function(_DidSecretEntry) _then) = __$DidSecretEntryCopyWithImpl;
@override @useResult
$Res call({
@JsonKey(name: 'key_id') String keyId,@JsonKey(name: 'key_type') String keyType,@JsonKey(name: 'private_key_multibase') String privateKeyMultibase
});




}
/// @nodoc
class __$DidSecretEntryCopyWithImpl<$Res>
    implements _$DidSecretEntryCopyWith<$Res> {
  __$DidSecretEntryCopyWithImpl(this._self, this._then);

  final _DidSecretEntry _self;
  final $Res Function(_DidSecretEntry) _then;

/// Create a copy of DidSecretEntry
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? keyId = null,Object? keyType = null,Object? privateKeyMultibase = null,}) {
  return _then(_DidSecretEntry(
keyId: null == keyId ? _self.keyId : keyId // ignore: cast_nullable_to_non_nullable
as String,keyType: null == keyType ? _self.keyType : keyType // ignore: cast_nullable_to_non_nullable
as String,privateKeyMultibase: null == privateKeyMultibase ? _self.privateKeyMultibase : privateKeyMultibase // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}


/// @nodoc
mixin _$DidSecretsBundle {

 String get did; List<DidSecretEntry> get secrets;
/// Create a copy of DidSecretsBundle
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$DidSecretsBundleCopyWith<DidSecretsBundle> get copyWith => _$DidSecretsBundleCopyWithImpl<DidSecretsBundle>(this as DidSecretsBundle, _$identity);

  /// Serializes this DidSecretsBundle to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is DidSecretsBundle&&(identical(other.did, did) || other.did == did)&&const DeepCollectionEquality().equals(other.secrets, secrets));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,did,const DeepCollectionEquality().hash(secrets));

@override
String toString() {
  return 'DidSecretsBundle(did: $did, secrets: $secrets)';
}


}

/// @nodoc
abstract mixin class $DidSecretsBundleCopyWith<$Res>  {
  factory $DidSecretsBundleCopyWith(DidSecretsBundle value, $Res Function(DidSecretsBundle) _then) = _$DidSecretsBundleCopyWithImpl;
@useResult
$Res call({
 String did, List<DidSecretEntry> secrets
});




}
/// @nodoc
class _$DidSecretsBundleCopyWithImpl<$Res>
    implements $DidSecretsBundleCopyWith<$Res> {
  _$DidSecretsBundleCopyWithImpl(this._self, this._then);

  final DidSecretsBundle _self;
  final $Res Function(DidSecretsBundle) _then;

/// Create a copy of DidSecretsBundle
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? did = null,Object? secrets = null,}) {
  return _then(_self.copyWith(
did: null == did ? _self.did : did // ignore: cast_nullable_to_non_nullable
as String,secrets: null == secrets ? _self.secrets : secrets // ignore: cast_nullable_to_non_nullable
as List<DidSecretEntry>,
  ));
}

}


/// Adds pattern-matching-related methods to [DidSecretsBundle].
extension DidSecretsBundlePatterns on DidSecretsBundle {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _DidSecretsBundle value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _DidSecretsBundle() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _DidSecretsBundle value)  $default,){
final _that = this;
switch (_that) {
case _DidSecretsBundle():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _DidSecretsBundle value)?  $default,){
final _that = this;
switch (_that) {
case _DidSecretsBundle() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String did,  List<DidSecretEntry> secrets)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _DidSecretsBundle() when $default != null:
return $default(_that.did,_that.secrets);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String did,  List<DidSecretEntry> secrets)  $default,) {final _that = this;
switch (_that) {
case _DidSecretsBundle():
return $default(_that.did,_that.secrets);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String did,  List<DidSecretEntry> secrets)?  $default,) {final _that = this;
switch (_that) {
case _DidSecretsBundle() when $default != null:
return $default(_that.did,_that.secrets);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _DidSecretsBundle implements DidSecretsBundle {
  const _DidSecretsBundle({required this.did, required final  List<DidSecretEntry> secrets}): _secrets = secrets;
  factory _DidSecretsBundle.fromJson(Map<String, dynamic> json) => _$DidSecretsBundleFromJson(json);

@override final  String did;
 final  List<DidSecretEntry> _secrets;
@override List<DidSecretEntry> get secrets {
  if (_secrets is EqualUnmodifiableListView) return _secrets;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_secrets);
}


/// Create a copy of DidSecretsBundle
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$DidSecretsBundleCopyWith<_DidSecretsBundle> get copyWith => __$DidSecretsBundleCopyWithImpl<_DidSecretsBundle>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$DidSecretsBundleToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _DidSecretsBundle&&(identical(other.did, did) || other.did == did)&&const DeepCollectionEquality().equals(other._secrets, _secrets));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,did,const DeepCollectionEquality().hash(_secrets));

@override
String toString() {
  return 'DidSecretsBundle(did: $did, secrets: $secrets)';
}


}

/// @nodoc
abstract mixin class _$DidSecretsBundleCopyWith<$Res> implements $DidSecretsBundleCopyWith<$Res> {
  factory _$DidSecretsBundleCopyWith(_DidSecretsBundle value, $Res Function(_DidSecretsBundle) _then) = __$DidSecretsBundleCopyWithImpl;
@override @useResult
$Res call({
 String did, List<DidSecretEntry> secrets
});




}
/// @nodoc
class __$DidSecretsBundleCopyWithImpl<$Res>
    implements _$DidSecretsBundleCopyWith<$Res> {
  __$DidSecretsBundleCopyWithImpl(this._self, this._then);

  final _DidSecretsBundle _self;
  final $Res Function(_DidSecretsBundle) _then;

/// Create a copy of DidSecretsBundle
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? did = null,Object? secrets = null,}) {
  return _then(_DidSecretsBundle(
did: null == did ? _self.did : did // ignore: cast_nullable_to_non_nullable
as String,secrets: null == secrets ? _self._secrets : secrets // ignore: cast_nullable_to_non_nullable
as List<DidSecretEntry>,
  ));
}


}

// dart format on
