// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'matrix_challenge_ok.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$MatrixChallengeOK extends MatrixChallengeOK {
  @override
  final String? challenge;

  factory _$MatrixChallengeOK([
    void Function(MatrixChallengeOKBuilder)? updates,
  ]) => (MatrixChallengeOKBuilder()..update(updates))._build();

  _$MatrixChallengeOK._({this.challenge}) : super._();
  @override
  MatrixChallengeOK rebuild(void Function(MatrixChallengeOKBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  MatrixChallengeOKBuilder toBuilder() =>
      MatrixChallengeOKBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is MatrixChallengeOK && challenge == other.challenge;
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
      r'MatrixChallengeOK',
    )..add('challenge', challenge)).toString();
  }
}

class MatrixChallengeOKBuilder
    implements Builder<MatrixChallengeOK, MatrixChallengeOKBuilder> {
  _$MatrixChallengeOK? _$v;

  String? _challenge;
  String? get challenge => _$this._challenge;
  set challenge(String? challenge) => _$this._challenge = challenge;

  MatrixChallengeOKBuilder() {
    MatrixChallengeOK._defaults(this);
  }

  MatrixChallengeOKBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _challenge = $v.challenge;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(MatrixChallengeOK other) {
    _$v = other as _$MatrixChallengeOK;
  }

  @override
  void update(void Function(MatrixChallengeOKBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  MatrixChallengeOK build() => _build();

  _$MatrixChallengeOK _build() {
    final _$result = _$v ?? _$MatrixChallengeOK._(challenge: challenge);
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
