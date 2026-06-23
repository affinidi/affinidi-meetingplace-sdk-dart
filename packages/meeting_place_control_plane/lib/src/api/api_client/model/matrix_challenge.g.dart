// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'matrix_challenge.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$MatrixChallenge extends MatrixChallenge {
  @override
  final String? did;

  factory _$MatrixChallenge([void Function(MatrixChallengeBuilder)? updates]) =>
      (MatrixChallengeBuilder()..update(updates))._build();

  _$MatrixChallenge._({this.did}) : super._();
  @override
  MatrixChallenge rebuild(void Function(MatrixChallengeBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  MatrixChallengeBuilder toBuilder() => MatrixChallengeBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is MatrixChallenge && did == other.did;
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
    return (newBuiltValueToStringHelper(
      r'MatrixChallenge',
    )..add('did', did)).toString();
  }
}

class MatrixChallengeBuilder
    implements Builder<MatrixChallenge, MatrixChallengeBuilder> {
  _$MatrixChallenge? _$v;

  String? _did;
  String? get did => _$this._did;
  set did(String? did) => _$this._did = did;

  MatrixChallengeBuilder() {
    MatrixChallenge._defaults(this);
  }

  MatrixChallengeBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _did = $v.did;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(MatrixChallenge other) {
    _$v = other as _$MatrixChallenge;
  }

  @override
  void update(void Function(MatrixChallengeBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  MatrixChallenge build() => _build();

  _$MatrixChallenge _build() {
    final _$result = _$v ?? _$MatrixChallenge._(did: did);
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
