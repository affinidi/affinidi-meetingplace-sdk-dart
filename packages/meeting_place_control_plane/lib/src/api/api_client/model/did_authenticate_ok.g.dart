// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'did_authenticate_ok.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$DidAuthenticateOK extends DidAuthenticateOK {
  @override
  final String? accessToken;
  @override
  final String? accessExpiresAt;
  @override
  final String? refreshToken;
  @override
  final String? refreshExpiresAt;

  factory _$DidAuthenticateOK([
    void Function(DidAuthenticateOKBuilder)? updates,
  ]) => (DidAuthenticateOKBuilder()..update(updates))._build();

  _$DidAuthenticateOK._({
    this.accessToken,
    this.accessExpiresAt,
    this.refreshToken,
    this.refreshExpiresAt,
  }) : super._();
  @override
  DidAuthenticateOK rebuild(void Function(DidAuthenticateOKBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  DidAuthenticateOKBuilder toBuilder() =>
      DidAuthenticateOKBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is DidAuthenticateOK &&
        accessToken == other.accessToken &&
        accessExpiresAt == other.accessExpiresAt &&
        refreshToken == other.refreshToken &&
        refreshExpiresAt == other.refreshExpiresAt;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, accessToken.hashCode);
    _$hash = $jc(_$hash, accessExpiresAt.hashCode);
    _$hash = $jc(_$hash, refreshToken.hashCode);
    _$hash = $jc(_$hash, refreshExpiresAt.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'DidAuthenticateOK')
          ..add('accessToken', accessToken)
          ..add('accessExpiresAt', accessExpiresAt)
          ..add('refreshToken', refreshToken)
          ..add('refreshExpiresAt', refreshExpiresAt))
        .toString();
  }
}

class DidAuthenticateOKBuilder
    implements Builder<DidAuthenticateOK, DidAuthenticateOKBuilder> {
  _$DidAuthenticateOK? _$v;

  String? _accessToken;
  String? get accessToken => _$this._accessToken;
  set accessToken(String? accessToken) => _$this._accessToken = accessToken;

  String? _accessExpiresAt;
  String? get accessExpiresAt => _$this._accessExpiresAt;
  set accessExpiresAt(String? accessExpiresAt) =>
      _$this._accessExpiresAt = accessExpiresAt;

  String? _refreshToken;
  String? get refreshToken => _$this._refreshToken;
  set refreshToken(String? refreshToken) => _$this._refreshToken = refreshToken;

  String? _refreshExpiresAt;
  String? get refreshExpiresAt => _$this._refreshExpiresAt;
  set refreshExpiresAt(String? refreshExpiresAt) =>
      _$this._refreshExpiresAt = refreshExpiresAt;

  DidAuthenticateOKBuilder() {
    DidAuthenticateOK._defaults(this);
  }

  DidAuthenticateOKBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _accessToken = $v.accessToken;
      _accessExpiresAt = $v.accessExpiresAt;
      _refreshToken = $v.refreshToken;
      _refreshExpiresAt = $v.refreshExpiresAt;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(DidAuthenticateOK other) {
    _$v = other as _$DidAuthenticateOK;
  }

  @override
  void update(void Function(DidAuthenticateOKBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  DidAuthenticateOK build() => _build();

  _$DidAuthenticateOK _build() {
    final _$result =
        _$v ??
        _$DidAuthenticateOK._(
          accessToken: accessToken,
          accessExpiresAt: accessExpiresAt,
          refreshToken: refreshToken,
          refreshExpiresAt: refreshExpiresAt,
        );
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
