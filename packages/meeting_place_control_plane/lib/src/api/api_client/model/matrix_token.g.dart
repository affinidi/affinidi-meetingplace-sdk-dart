// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'matrix_token.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$MatrixToken extends MatrixToken {
  @override
  final String? challengeResponse;
  @override
  final String? homeserver;

  factory _$MatrixToken([void Function(MatrixTokenBuilder)? updates]) =>
      (MatrixTokenBuilder()..update(updates))._build();

  _$MatrixToken._({this.challengeResponse, this.homeserver}) : super._();
  @override
  MatrixToken rebuild(void Function(MatrixTokenBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  MatrixTokenBuilder toBuilder() => MatrixTokenBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is MatrixToken &&
        challengeResponse == other.challengeResponse &&
        homeserver == other.homeserver;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, challengeResponse.hashCode);
    _$hash = $jc(_$hash, homeserver.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'MatrixToken')
          ..add('challengeResponse', challengeResponse)
          ..add('homeserver', homeserver))
        .toString();
  }
}

class MatrixTokenBuilder implements Builder<MatrixToken, MatrixTokenBuilder> {
  _$MatrixToken? _$v;

  String? _challengeResponse;
  String? get challengeResponse => _$this._challengeResponse;
  set challengeResponse(String? challengeResponse) =>
      _$this._challengeResponse = challengeResponse;

  String? _homeserver;
  String? get homeserver => _$this._homeserver;
  set homeserver(String? homeserver) => _$this._homeserver = homeserver;

  MatrixTokenBuilder() {
    MatrixToken._defaults(this);
  }

  MatrixTokenBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _challengeResponse = $v.challengeResponse;
      _homeserver = $v.homeserver;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(MatrixToken other) {
    _$v = other as _$MatrixToken;
  }

  @override
  void update(void Function(MatrixTokenBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  MatrixToken build() => _build();

  _$MatrixToken _build() {
    final _$result =
        _$v ??
        _$MatrixToken._(
          challengeResponse: challengeResponse,
          homeserver: homeserver,
        );
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
