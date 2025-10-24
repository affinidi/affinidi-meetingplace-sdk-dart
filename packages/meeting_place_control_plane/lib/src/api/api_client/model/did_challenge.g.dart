// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'did_challenge.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$DidChallenge extends DidChallenge {
  @override
  final String? did;

  factory _$DidChallenge([void Function(DidChallengeBuilder)? updates]) =>
      (DidChallengeBuilder()..update(updates))._build();

  _$DidChallenge._({this.did}) : super._();
  @override
  DidChallenge rebuild(void Function(DidChallengeBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  DidChallengeBuilder toBuilder() => DidChallengeBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is DidChallenge && did == other.did;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, did.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'DidChallenge')..add('did', did))
        .toString();
  }
}

class DidChallengeBuilder
    implements Builder<DidChallenge, DidChallengeBuilder> {
  _$DidChallenge? _$v;

  String? _did;
  String? get did => _$this._did;
  set did(String? did) => _$this._did = did;

  DidChallengeBuilder() {
    DidChallenge._defaults(this);
  }

  DidChallengeBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _did = $v.did;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(DidChallenge other) {
    _$v = other as _$DidChallenge;
  }

  @override
  void update(void Function(DidChallengeBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  DidChallenge build() => _build();

  _$DidChallenge _build() {
    final _$result = _$v ??
        _$DidChallenge._(
          did: did,
        );
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
