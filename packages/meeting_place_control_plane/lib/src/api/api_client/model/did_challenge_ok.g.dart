// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'did_challenge_ok.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$DidChallengeOK extends DidChallengeOK {
  @override
  final String? challenge;

  factory _$DidChallengeOK([void Function(DidChallengeOKBuilder)? updates]) =>
      (DidChallengeOKBuilder()..update(updates))._build();

  _$DidChallengeOK._({this.challenge}) : super._();
  @override
  DidChallengeOK rebuild(void Function(DidChallengeOKBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  DidChallengeOKBuilder toBuilder() => DidChallengeOKBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is DidChallengeOK && challenge == other.challenge;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, challenge.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(
      r'DidChallengeOK',
    )..add('challenge', challenge)).toString();
  }
}

class DidChallengeOKBuilder
    implements Builder<DidChallengeOK, DidChallengeOKBuilder> {
  _$DidChallengeOK? _$v;

  String? _challenge;
  String? get challenge => _$this._challenge;
  set challenge(String? challenge) => _$this._challenge = challenge;

  DidChallengeOKBuilder() {
    DidChallengeOK._defaults(this);
  }

  DidChallengeOKBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _challenge = $v.challenge;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(DidChallengeOK other) {
    _$v = other as _$DidChallengeOK;
  }

  @override
  void update(void Function(DidChallengeOKBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  DidChallengeOK build() => _build();

  _$DidChallengeOK _build() {
    final _$result = _$v ?? _$DidChallengeOK._(challenge: challenge);
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
