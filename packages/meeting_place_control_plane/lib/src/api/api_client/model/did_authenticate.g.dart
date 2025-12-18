// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'did_authenticate.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$DidAuthenticate extends DidAuthenticate {
  @override
  final String? challengeResponse;

  factory _$DidAuthenticate([void Function(DidAuthenticateBuilder)? updates]) =>
      (DidAuthenticateBuilder()..update(updates))._build();

  _$DidAuthenticate._({this.challengeResponse}) : super._();
  @override
  DidAuthenticate rebuild(void Function(DidAuthenticateBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  DidAuthenticateBuilder toBuilder() => DidAuthenticateBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is DidAuthenticate &&
        challengeResponse == other.challengeResponse;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, challengeResponse.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(
      r'DidAuthenticate',
    )..add('challengeResponse', challengeResponse)).toString();
  }
}

class DidAuthenticateBuilder
    implements Builder<DidAuthenticate, DidAuthenticateBuilder> {
  _$DidAuthenticate? _$v;

  String? _challengeResponse;
  String? get challengeResponse => _$this._challengeResponse;
  set challengeResponse(String? challengeResponse) =>
      _$this._challengeResponse = challengeResponse;

  DidAuthenticateBuilder() {
    DidAuthenticate._defaults(this);
  }

  DidAuthenticateBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _challengeResponse = $v.challengeResponse;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(DidAuthenticate other) {
    _$v = other as _$DidAuthenticate;
  }

  @override
  void update(void Function(DidAuthenticateBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  DidAuthenticate build() => _build();

  _$DidAuthenticate _build() {
    final _$result =
        _$v ?? _$DidAuthenticate._(challengeResponse: challengeResponse);
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
