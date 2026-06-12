// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'sfu_token_response.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$SfuTokenResponse {

/// LiveKit JWT for connecting to the SFU.
 String get token;/// WebSocket URL of the LiveKit SFU (e.g. `wss://livekit.example.com`).
///
/// May be absent when the client has a pre-configured SFU URL.
 String? get url;
/// Create a copy of SfuTokenResponse
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SfuTokenResponseCopyWith<SfuTokenResponse> get copyWith => _$SfuTokenResponseCopyWithImpl<SfuTokenResponse>(this as SfuTokenResponse, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SfuTokenResponse&&(identical(other.token, token) || other.token == token)&&(identical(other.url, url) || other.url == url));
}


@override
int get hashCode => Object.hash(runtimeType,token,url);

@override
String toString() {
  return 'SfuTokenResponse(token: $token, url: $url)';
}


}

/// @nodoc
abstract mixin class $SfuTokenResponseCopyWith<$Res>  {
  factory $SfuTokenResponseCopyWith(SfuTokenResponse value, $Res Function(SfuTokenResponse) _then) = _$SfuTokenResponseCopyWithImpl;
@useResult
$Res call({
 String token, String? url
});




}
/// @nodoc
class _$SfuTokenResponseCopyWithImpl<$Res>
    implements $SfuTokenResponseCopyWith<$Res> {
  _$SfuTokenResponseCopyWithImpl(this._self, this._then);

  final SfuTokenResponse _self;
  final $Res Function(SfuTokenResponse) _then;

/// Create a copy of SfuTokenResponse
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? token = null,Object? url = freezed,}) {
  return _then(_self.copyWith(
token: null == token ? _self.token : token // ignore: cast_nullable_to_non_nullable
as String,url: freezed == url ? _self.url : url // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [SfuTokenResponse].
extension SfuTokenResponsePatterns on SfuTokenResponse {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _SfuTokenResponse value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _SfuTokenResponse() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _SfuTokenResponse value)  $default,){
final _that = this;
switch (_that) {
case _SfuTokenResponse():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _SfuTokenResponse value)?  $default,){
final _that = this;
switch (_that) {
case _SfuTokenResponse() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String token,  String? url)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _SfuTokenResponse() when $default != null:
return $default(_that.token,_that.url);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String token,  String? url)  $default,) {final _that = this;
switch (_that) {
case _SfuTokenResponse():
return $default(_that.token,_that.url);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String token,  String? url)?  $default,) {final _that = this;
switch (_that) {
case _SfuTokenResponse() when $default != null:
return $default(_that.token,_that.url);case _:
  return null;

}
}

}

/// @nodoc


class _SfuTokenResponse implements SfuTokenResponse {
  const _SfuTokenResponse({required this.token, this.url});
  

/// LiveKit JWT for connecting to the SFU.
@override final  String token;
/// WebSocket URL of the LiveKit SFU (e.g. `wss://livekit.example.com`).
///
/// May be absent when the client has a pre-configured SFU URL.
@override final  String? url;

/// Create a copy of SfuTokenResponse
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$SfuTokenResponseCopyWith<_SfuTokenResponse> get copyWith => __$SfuTokenResponseCopyWithImpl<_SfuTokenResponse>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _SfuTokenResponse&&(identical(other.token, token) || other.token == token)&&(identical(other.url, url) || other.url == url));
}


@override
int get hashCode => Object.hash(runtimeType,token,url);

@override
String toString() {
  return 'SfuTokenResponse(token: $token, url: $url)';
}


}

/// @nodoc
abstract mixin class _$SfuTokenResponseCopyWith<$Res> implements $SfuTokenResponseCopyWith<$Res> {
  factory _$SfuTokenResponseCopyWith(_SfuTokenResponse value, $Res Function(_SfuTokenResponse) _then) = __$SfuTokenResponseCopyWithImpl;
@override @useResult
$Res call({
 String token, String? url
});




}
/// @nodoc
class __$SfuTokenResponseCopyWithImpl<$Res>
    implements _$SfuTokenResponseCopyWith<$Res> {
  __$SfuTokenResponseCopyWithImpl(this._self, this._then);

  final _SfuTokenResponse _self;
  final $Res Function(_SfuTokenResponse) _then;

/// Create a copy of SfuTokenResponse
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? token = null,Object? url = freezed,}) {
  return _then(_SfuTokenResponse(
token: null == token ? _self.token : token // ignore: cast_nullable_to_non_nullable
as String,url: freezed == url ? _self.url : url // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

// dart format on
