// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'matrix_token_ok.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$MatrixTokenOK extends MatrixTokenOK {
  @override
  final String? token;

  factory _$MatrixTokenOK([void Function(MatrixTokenOKBuilder)? updates]) =>
      (MatrixTokenOKBuilder()..update(updates))._build();

  _$MatrixTokenOK._({this.token}) : super._();
  @override
  MatrixTokenOK rebuild(void Function(MatrixTokenOKBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  MatrixTokenOKBuilder toBuilder() => MatrixTokenOKBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is MatrixTokenOK && token == other.token;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, token.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(
      r'MatrixTokenOK',
    )..add('token', token)).toString();
  }
}

class MatrixTokenOKBuilder
    implements Builder<MatrixTokenOK, MatrixTokenOKBuilder> {
  _$MatrixTokenOK? _$v;

  String? _token;
  String? get token => _$this._token;
  set token(String? token) => _$this._token = token;

  MatrixTokenOKBuilder() {
    MatrixTokenOK._defaults(this);
  }

  MatrixTokenOKBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _token = $v.token;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(MatrixTokenOK other) {
    _$v = other as _$MatrixTokenOK;
  }

  @override
  void update(void Function(MatrixTokenOKBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  MatrixTokenOK build() => _build();

  _$MatrixTokenOK _build() {
    final _$result = _$v ?? _$MatrixTokenOK._(token: token);
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
