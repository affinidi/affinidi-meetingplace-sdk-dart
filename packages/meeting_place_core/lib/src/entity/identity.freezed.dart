// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'identity.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$Identity {
  String get id;
  String get did;
  ContactCard get card;
  bool get isPrimary;

  /// Create a copy of Identity
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $IdentityCopyWith<Identity> get copyWith =>
      _$IdentityCopyWithImpl<Identity>(this as Identity, _$identity);

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is Identity &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.did, did) || other.did == did) &&
            (identical(other.card, card) || other.card == card) &&
            (identical(other.isPrimary, isPrimary) ||
                other.isPrimary == isPrimary));
  }

  @override
  int get hashCode => Object.hash(runtimeType, id, did, card, isPrimary);

  @override
  String toString() {
    return 'Identity(id: $id, did: $did, card: $card, isPrimary: $isPrimary)';
  }
}

/// @nodoc
abstract mixin class $IdentityCopyWith<$Res> {
  factory $IdentityCopyWith(Identity value, $Res Function(Identity) _then) =
      _$IdentityCopyWithImpl;
  @useResult
  $Res call({String id, String did, ContactCard card, bool isPrimary});

  $ContactCardCopyWith<$Res> get card;
}

/// @nodoc
class _$IdentityCopyWithImpl<$Res> implements $IdentityCopyWith<$Res> {
  _$IdentityCopyWithImpl(this._self, this._then);

  final Identity _self;
  final $Res Function(Identity) _then;

  /// Create a copy of Identity
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? did = null,
    Object? card = null,
    Object? isPrimary = null,
  }) {
    return _then(_self.copyWith(
      id: null == id
          ? _self.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      did: null == did
          ? _self.did
          : did // ignore: cast_nullable_to_non_nullable
              as String,
      card: null == card
          ? _self.card
          : card // ignore: cast_nullable_to_non_nullable
              as ContactCard,
      isPrimary: null == isPrimary
          ? _self.isPrimary
          : isPrimary // ignore: cast_nullable_to_non_nullable
              as bool,
    ));
  }

  /// Create a copy of Identity
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $ContactCardCopyWith<$Res> get card {
    return $ContactCardCopyWith<$Res>(_self.card, (value) {
      return _then(_self.copyWith(card: value));
    });
  }
}

/// Adds pattern-matching-related methods to [Identity].
extension IdentityPatterns on Identity {
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

  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>(
    TResult Function(_Identity value)? $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _Identity() when $default != null:
        return $default(_that);
      case _:
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

  @optionalTypeArgs
  TResult map<TResult extends Object?>(
    TResult Function(_Identity value) $default,
  ) {
    final _that = this;
    switch (_that) {
      case _Identity():
        return $default(_that);
      case _:
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

  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>(
    TResult? Function(_Identity value)? $default,
  ) {
    final _that = this;
    switch (_that) {
      case _Identity() when $default != null:
        return $default(_that);
      case _:
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

  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>(
    TResult Function(String id, String did, ContactCard card, bool isPrimary)?
        $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _Identity() when $default != null:
        return $default(_that.id, _that.did, _that.card, _that.isPrimary);
      case _:
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

  @optionalTypeArgs
  TResult when<TResult extends Object?>(
    TResult Function(String id, String did, ContactCard card, bool isPrimary)
        $default,
  ) {
    final _that = this;
    switch (_that) {
      case _Identity():
        return $default(_that.id, _that.did, _that.card, _that.isPrimary);
      case _:
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

  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>(
    TResult? Function(String id, String did, ContactCard card, bool isPrimary)?
        $default,
  ) {
    final _that = this;
    switch (_that) {
      case _Identity() when $default != null:
        return $default(_that.id, _that.did, _that.card, _that.isPrimary);
      case _:
        return null;
    }
  }
}

/// @nodoc

class _Identity implements Identity {
  const _Identity(
      {required this.id,
      required this.did,
      required this.card,
      this.isPrimary = false});

  @override
  final String id;
  @override
  final String did;
  @override
  final ContactCard card;
  @override
  @JsonKey()
  final bool isPrimary;

  /// Create a copy of Identity
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  _$IdentityCopyWith<_Identity> get copyWith =>
      __$IdentityCopyWithImpl<_Identity>(this, _$identity);

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _Identity &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.did, did) || other.did == did) &&
            (identical(other.card, card) || other.card == card) &&
            (identical(other.isPrimary, isPrimary) ||
                other.isPrimary == isPrimary));
  }

  @override
  int get hashCode => Object.hash(runtimeType, id, did, card, isPrimary);

  @override
  String toString() {
    return 'Identity(id: $id, did: $did, card: $card, isPrimary: $isPrimary)';
  }
}

/// @nodoc
abstract mixin class _$IdentityCopyWith<$Res>
    implements $IdentityCopyWith<$Res> {
  factory _$IdentityCopyWith(_Identity value, $Res Function(_Identity) _then) =
      __$IdentityCopyWithImpl;
  @override
  @useResult
  $Res call({String id, String did, ContactCard card, bool isPrimary});

  @override
  $ContactCardCopyWith<$Res> get card;
}

/// @nodoc
class __$IdentityCopyWithImpl<$Res> implements _$IdentityCopyWith<$Res> {
  __$IdentityCopyWithImpl(this._self, this._then);

  final _Identity _self;
  final $Res Function(_Identity) _then;

  /// Create a copy of Identity
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $Res call({
    Object? id = null,
    Object? did = null,
    Object? card = null,
    Object? isPrimary = null,
  }) {
    return _then(_Identity(
      id: null == id
          ? _self.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      did: null == did
          ? _self.did
          : did // ignore: cast_nullable_to_non_nullable
              as String,
      card: null == card
          ? _self.card
          : card // ignore: cast_nullable_to_non_nullable
              as ContactCard,
      isPrimary: null == isPrimary
          ? _self.isPrimary
          : isPrimary // ignore: cast_nullable_to_non_nullable
              as bool,
    ));
  }

  /// Create a copy of Identity
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $ContactCardCopyWith<$Res> get card {
    return $ContactCardCopyWith<$Res>(_self.card, (value) {
      return _then(_self.copyWith(card: value));
    });
  }
}

// dart format on
