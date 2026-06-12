// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'audio_video_call_service_state.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$AudioVideoCallServiceState {

 AudioVideoCallStatus get status; List<AudioVideoCallParticipant> get participants;/// Non-null only when [status] is [AudioVideoCallStatus.error].
 AudioVideoCallErrorCode? get errorCode;
/// Create a copy of AudioVideoCallServiceState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$AudioVideoCallServiceStateCopyWith<AudioVideoCallServiceState> get copyWith => _$AudioVideoCallServiceStateCopyWithImpl<AudioVideoCallServiceState>(this as AudioVideoCallServiceState, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AudioVideoCallServiceState&&(identical(other.status, status) || other.status == status)&&const DeepCollectionEquality().equals(other.participants, participants)&&(identical(other.errorCode, errorCode) || other.errorCode == errorCode));
}


@override
int get hashCode => Object.hash(runtimeType,status,const DeepCollectionEquality().hash(participants),errorCode);

@override
String toString() {
  return 'AudioVideoCallServiceState(status: $status, participants: $participants, errorCode: $errorCode)';
}


}

/// @nodoc
abstract mixin class $AudioVideoCallServiceStateCopyWith<$Res>  {
  factory $AudioVideoCallServiceStateCopyWith(AudioVideoCallServiceState value, $Res Function(AudioVideoCallServiceState) _then) = _$AudioVideoCallServiceStateCopyWithImpl;
@useResult
$Res call({
 AudioVideoCallStatus status, List<AudioVideoCallParticipant> participants, AudioVideoCallErrorCode? errorCode
});




}
/// @nodoc
class _$AudioVideoCallServiceStateCopyWithImpl<$Res>
    implements $AudioVideoCallServiceStateCopyWith<$Res> {
  _$AudioVideoCallServiceStateCopyWithImpl(this._self, this._then);

  final AudioVideoCallServiceState _self;
  final $Res Function(AudioVideoCallServiceState) _then;

/// Create a copy of AudioVideoCallServiceState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? status = null,Object? participants = null,Object? errorCode = freezed,}) {
  return _then(_self.copyWith(
status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as AudioVideoCallStatus,participants: null == participants ? _self.participants : participants // ignore: cast_nullable_to_non_nullable
as List<AudioVideoCallParticipant>,errorCode: freezed == errorCode ? _self.errorCode : errorCode // ignore: cast_nullable_to_non_nullable
as AudioVideoCallErrorCode?,
  ));
}

}


/// Adds pattern-matching-related methods to [AudioVideoCallServiceState].
extension AudioVideoCallServiceStatePatterns on AudioVideoCallServiceState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _AudioVideoCallServiceState value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _AudioVideoCallServiceState() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _AudioVideoCallServiceState value)  $default,){
final _that = this;
switch (_that) {
case _AudioVideoCallServiceState():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _AudioVideoCallServiceState value)?  $default,){
final _that = this;
switch (_that) {
case _AudioVideoCallServiceState() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( AudioVideoCallStatus status,  List<AudioVideoCallParticipant> participants,  AudioVideoCallErrorCode? errorCode)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _AudioVideoCallServiceState() when $default != null:
return $default(_that.status,_that.participants,_that.errorCode);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( AudioVideoCallStatus status,  List<AudioVideoCallParticipant> participants,  AudioVideoCallErrorCode? errorCode)  $default,) {final _that = this;
switch (_that) {
case _AudioVideoCallServiceState():
return $default(_that.status,_that.participants,_that.errorCode);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( AudioVideoCallStatus status,  List<AudioVideoCallParticipant> participants,  AudioVideoCallErrorCode? errorCode)?  $default,) {final _that = this;
switch (_that) {
case _AudioVideoCallServiceState() when $default != null:
return $default(_that.status,_that.participants,_that.errorCode);case _:
  return null;

}
}

}

/// @nodoc


class _AudioVideoCallServiceState extends AudioVideoCallServiceState {
   _AudioVideoCallServiceState({this.status = AudioVideoCallStatus.idle, final  List<AudioVideoCallParticipant> participants = const [], this.errorCode}): _participants = participants,super._();
  

@override@JsonKey() final  AudioVideoCallStatus status;
 final  List<AudioVideoCallParticipant> _participants;
@override@JsonKey() List<AudioVideoCallParticipant> get participants {
  if (_participants is EqualUnmodifiableListView) return _participants;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_participants);
}

/// Non-null only when [status] is [AudioVideoCallStatus.error].
@override final  AudioVideoCallErrorCode? errorCode;

/// Create a copy of AudioVideoCallServiceState
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$AudioVideoCallServiceStateCopyWith<_AudioVideoCallServiceState> get copyWith => __$AudioVideoCallServiceStateCopyWithImpl<_AudioVideoCallServiceState>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _AudioVideoCallServiceState&&(identical(other.status, status) || other.status == status)&&const DeepCollectionEquality().equals(other._participants, _participants)&&(identical(other.errorCode, errorCode) || other.errorCode == errorCode));
}


@override
int get hashCode => Object.hash(runtimeType,status,const DeepCollectionEquality().hash(_participants),errorCode);

@override
String toString() {
  return 'AudioVideoCallServiceState(status: $status, participants: $participants, errorCode: $errorCode)';
}


}

/// @nodoc
abstract mixin class _$AudioVideoCallServiceStateCopyWith<$Res> implements $AudioVideoCallServiceStateCopyWith<$Res> {
  factory _$AudioVideoCallServiceStateCopyWith(_AudioVideoCallServiceState value, $Res Function(_AudioVideoCallServiceState) _then) = __$AudioVideoCallServiceStateCopyWithImpl;
@override @useResult
$Res call({
 AudioVideoCallStatus status, List<AudioVideoCallParticipant> participants, AudioVideoCallErrorCode? errorCode
});




}
/// @nodoc
class __$AudioVideoCallServiceStateCopyWithImpl<$Res>
    implements _$AudioVideoCallServiceStateCopyWith<$Res> {
  __$AudioVideoCallServiceStateCopyWithImpl(this._self, this._then);

  final _AudioVideoCallServiceState _self;
  final $Res Function(_AudioVideoCallServiceState) _then;

/// Create a copy of AudioVideoCallServiceState
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? status = null,Object? participants = null,Object? errorCode = freezed,}) {
  return _then(_AudioVideoCallServiceState(
status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as AudioVideoCallStatus,participants: null == participants ? _self._participants : participants // ignore: cast_nullable_to_non_nullable
as List<AudioVideoCallParticipant>,errorCode: freezed == errorCode ? _self.errorCode : errorCode // ignore: cast_nullable_to_non_nullable
as AudioVideoCallErrorCode?,
  ));
}


}

// dart format on
