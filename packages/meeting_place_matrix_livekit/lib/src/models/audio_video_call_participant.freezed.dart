// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'audio_video_call_participant.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$AudioVideoCallParticipant {

/// LiveKit participant identity string.
 String get identity; bool get hasVideo; bool get hasAudio; bool get isSpeaking; bool get isLocal;
/// Create a copy of AudioVideoCallParticipant
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$AudioVideoCallParticipantCopyWith<AudioVideoCallParticipant> get copyWith => _$AudioVideoCallParticipantCopyWithImpl<AudioVideoCallParticipant>(this as AudioVideoCallParticipant, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AudioVideoCallParticipant&&(identical(other.identity, identity) || other.identity == identity)&&(identical(other.hasVideo, hasVideo) || other.hasVideo == hasVideo)&&(identical(other.hasAudio, hasAudio) || other.hasAudio == hasAudio)&&(identical(other.isSpeaking, isSpeaking) || other.isSpeaking == isSpeaking)&&(identical(other.isLocal, isLocal) || other.isLocal == isLocal));
}


@override
int get hashCode => Object.hash(runtimeType,identity,hasVideo,hasAudio,isSpeaking,isLocal);

@override
String toString() {
  return 'AudioVideoCallParticipant(identity: $identity, hasVideo: $hasVideo, hasAudio: $hasAudio, isSpeaking: $isSpeaking, isLocal: $isLocal)';
}


}

/// @nodoc
abstract mixin class $AudioVideoCallParticipantCopyWith<$Res>  {
  factory $AudioVideoCallParticipantCopyWith(AudioVideoCallParticipant value, $Res Function(AudioVideoCallParticipant) _then) = _$AudioVideoCallParticipantCopyWithImpl;
@useResult
$Res call({
 String identity, bool hasVideo, bool hasAudio, bool isSpeaking, bool isLocal
});




}
/// @nodoc
class _$AudioVideoCallParticipantCopyWithImpl<$Res>
    implements $AudioVideoCallParticipantCopyWith<$Res> {
  _$AudioVideoCallParticipantCopyWithImpl(this._self, this._then);

  final AudioVideoCallParticipant _self;
  final $Res Function(AudioVideoCallParticipant) _then;

/// Create a copy of AudioVideoCallParticipant
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? identity = null,Object? hasVideo = null,Object? hasAudio = null,Object? isSpeaking = null,Object? isLocal = null,}) {
  return _then(_self.copyWith(
identity: null == identity ? _self.identity : identity // ignore: cast_nullable_to_non_nullable
as String,hasVideo: null == hasVideo ? _self.hasVideo : hasVideo // ignore: cast_nullable_to_non_nullable
as bool,hasAudio: null == hasAudio ? _self.hasAudio : hasAudio // ignore: cast_nullable_to_non_nullable
as bool,isSpeaking: null == isSpeaking ? _self.isSpeaking : isSpeaking // ignore: cast_nullable_to_non_nullable
as bool,isLocal: null == isLocal ? _self.isLocal : isLocal // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

}


/// Adds pattern-matching-related methods to [AudioVideoCallParticipant].
extension AudioVideoCallParticipantPatterns on AudioVideoCallParticipant {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _AudioVideoCallParticipant value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _AudioVideoCallParticipant() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _AudioVideoCallParticipant value)  $default,){
final _that = this;
switch (_that) {
case _AudioVideoCallParticipant():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _AudioVideoCallParticipant value)?  $default,){
final _that = this;
switch (_that) {
case _AudioVideoCallParticipant() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String identity,  bool hasVideo,  bool hasAudio,  bool isSpeaking,  bool isLocal)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _AudioVideoCallParticipant() when $default != null:
return $default(_that.identity,_that.hasVideo,_that.hasAudio,_that.isSpeaking,_that.isLocal);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String identity,  bool hasVideo,  bool hasAudio,  bool isSpeaking,  bool isLocal)  $default,) {final _that = this;
switch (_that) {
case _AudioVideoCallParticipant():
return $default(_that.identity,_that.hasVideo,_that.hasAudio,_that.isSpeaking,_that.isLocal);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String identity,  bool hasVideo,  bool hasAudio,  bool isSpeaking,  bool isLocal)?  $default,) {final _that = this;
switch (_that) {
case _AudioVideoCallParticipant() when $default != null:
return $default(_that.identity,_that.hasVideo,_that.hasAudio,_that.isSpeaking,_that.isLocal);case _:
  return null;

}
}

}

/// @nodoc


class _AudioVideoCallParticipant implements AudioVideoCallParticipant {
  const _AudioVideoCallParticipant({required this.identity, this.hasVideo = false, this.hasAudio = false, this.isSpeaking = false, this.isLocal = false});
  

/// LiveKit participant identity string.
@override final  String identity;
@override@JsonKey() final  bool hasVideo;
@override@JsonKey() final  bool hasAudio;
@override@JsonKey() final  bool isSpeaking;
@override@JsonKey() final  bool isLocal;

/// Create a copy of AudioVideoCallParticipant
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$AudioVideoCallParticipantCopyWith<_AudioVideoCallParticipant> get copyWith => __$AudioVideoCallParticipantCopyWithImpl<_AudioVideoCallParticipant>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _AudioVideoCallParticipant&&(identical(other.identity, identity) || other.identity == identity)&&(identical(other.hasVideo, hasVideo) || other.hasVideo == hasVideo)&&(identical(other.hasAudio, hasAudio) || other.hasAudio == hasAudio)&&(identical(other.isSpeaking, isSpeaking) || other.isSpeaking == isSpeaking)&&(identical(other.isLocal, isLocal) || other.isLocal == isLocal));
}


@override
int get hashCode => Object.hash(runtimeType,identity,hasVideo,hasAudio,isSpeaking,isLocal);

@override
String toString() {
  return 'AudioVideoCallParticipant(identity: $identity, hasVideo: $hasVideo, hasAudio: $hasAudio, isSpeaking: $isSpeaking, isLocal: $isLocal)';
}


}

/// @nodoc
abstract mixin class _$AudioVideoCallParticipantCopyWith<$Res> implements $AudioVideoCallParticipantCopyWith<$Res> {
  factory _$AudioVideoCallParticipantCopyWith(_AudioVideoCallParticipant value, $Res Function(_AudioVideoCallParticipant) _then) = __$AudioVideoCallParticipantCopyWithImpl;
@override @useResult
$Res call({
 String identity, bool hasVideo, bool hasAudio, bool isSpeaking, bool isLocal
});




}
/// @nodoc
class __$AudioVideoCallParticipantCopyWithImpl<$Res>
    implements _$AudioVideoCallParticipantCopyWith<$Res> {
  __$AudioVideoCallParticipantCopyWithImpl(this._self, this._then);

  final _AudioVideoCallParticipant _self;
  final $Res Function(_AudioVideoCallParticipant) _then;

/// Create a copy of AudioVideoCallParticipant
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? identity = null,Object? hasVideo = null,Object? hasAudio = null,Object? isSpeaking = null,Object? isLocal = null,}) {
  return _then(_AudioVideoCallParticipant(
identity: null == identity ? _self.identity : identity // ignore: cast_nullable_to_non_nullable
as String,hasVideo: null == hasVideo ? _self.hasVideo : hasVideo // ignore: cast_nullable_to_non_nullable
as bool,hasAudio: null == hasAudio ? _self.hasAudio : hasAudio // ignore: cast_nullable_to_non_nullable
as bool,isSpeaking: null == isSpeaking ? _self.isSpeaking : isSpeaking // ignore: cast_nullable_to_non_nullable
as bool,isLocal: null == isLocal ? _self.isLocal : isLocal // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}

// dart format on
