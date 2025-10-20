// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'get_oob_ok.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$GetOobOK extends GetOobOK {
  @override
  final String didcommMessage;
  @override
  final String mediatorDid;
  @override
  final String mediatorEndpoint;
  @override
  final String mediatorWSSEndpoint;

  factory _$GetOobOK([void Function(GetOobOKBuilder)? updates]) =>
      (GetOobOKBuilder()..update(updates))._build();

  _$GetOobOK._(
      {required this.didcommMessage,
      required this.mediatorDid,
      required this.mediatorEndpoint,
      required this.mediatorWSSEndpoint})
      : super._();
  @override
  GetOobOK rebuild(void Function(GetOobOKBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  GetOobOKBuilder toBuilder() => GetOobOKBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is GetOobOK &&
        didcommMessage == other.didcommMessage &&
        mediatorDid == other.mediatorDid &&
        mediatorEndpoint == other.mediatorEndpoint &&
        mediatorWSSEndpoint == other.mediatorWSSEndpoint;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, didcommMessage.hashCode);
    _$hash = $jc(_$hash, mediatorDid.hashCode);
    _$hash = $jc(_$hash, mediatorEndpoint.hashCode);
    _$hash = $jc(_$hash, mediatorWSSEndpoint.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'GetOobOK')
          ..add('didcommMessage', didcommMessage)
          ..add('mediatorDid', mediatorDid)
          ..add('mediatorEndpoint', mediatorEndpoint)
          ..add('mediatorWSSEndpoint', mediatorWSSEndpoint))
        .toString();
  }
}

class GetOobOKBuilder implements Builder<GetOobOK, GetOobOKBuilder> {
  _$GetOobOK? _$v;

  String? _didcommMessage;
  String? get didcommMessage => _$this._didcommMessage;
  set didcommMessage(String? didcommMessage) =>
      _$this._didcommMessage = didcommMessage;

  String? _mediatorDid;
  String? get mediatorDid => _$this._mediatorDid;
  set mediatorDid(String? mediatorDid) => _$this._mediatorDid = mediatorDid;

  String? _mediatorEndpoint;
  String? get mediatorEndpoint => _$this._mediatorEndpoint;
  set mediatorEndpoint(String? mediatorEndpoint) =>
      _$this._mediatorEndpoint = mediatorEndpoint;

  String? _mediatorWSSEndpoint;
  String? get mediatorWSSEndpoint => _$this._mediatorWSSEndpoint;
  set mediatorWSSEndpoint(String? mediatorWSSEndpoint) =>
      _$this._mediatorWSSEndpoint = mediatorWSSEndpoint;

  GetOobOKBuilder() {
    GetOobOK._defaults(this);
  }

  GetOobOKBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _didcommMessage = $v.didcommMessage;
      _mediatorDid = $v.mediatorDid;
      _mediatorEndpoint = $v.mediatorEndpoint;
      _mediatorWSSEndpoint = $v.mediatorWSSEndpoint;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(GetOobOK other) {
    _$v = other as _$GetOobOK;
  }

  @override
  void update(void Function(GetOobOKBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  GetOobOK build() => _build();

  _$GetOobOK _build() {
    final _$result = _$v ??
        _$GetOobOK._(
          didcommMessage: BuiltValueNullFieldError.checkNotNull(
              didcommMessage, r'GetOobOK', 'didcommMessage'),
          mediatorDid: BuiltValueNullFieldError.checkNotNull(
              mediatorDid, r'GetOobOK', 'mediatorDid'),
          mediatorEndpoint: BuiltValueNullFieldError.checkNotNull(
              mediatorEndpoint, r'GetOobOK', 'mediatorEndpoint'),
          mediatorWSSEndpoint: BuiltValueNullFieldError.checkNotNull(
              mediatorWSSEndpoint, r'GetOobOK', 'mediatorWSSEndpoint'),
        );
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
