// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'create_oob_input.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$CreateOobInput extends CreateOobInput {
  @override
  final String didcommMessage;
  @override
  final String mediatorDid;
  @override
  final String mediatorEndpoint;
  @override
  final String mediatorWSSEndpoint;

  factory _$CreateOobInput([void Function(CreateOobInputBuilder)? updates]) =>
      (CreateOobInputBuilder()..update(updates))._build();

  _$CreateOobInput._(
      {required this.didcommMessage,
      required this.mediatorDid,
      required this.mediatorEndpoint,
      required this.mediatorWSSEndpoint})
      : super._();
  @override
  CreateOobInput rebuild(void Function(CreateOobInputBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  CreateOobInputBuilder toBuilder() => CreateOobInputBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is CreateOobInput &&
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
    return (newBuiltValueToStringHelper(r'CreateOobInput')
          ..add('didcommMessage', didcommMessage)
          ..add('mediatorDid', mediatorDid)
          ..add('mediatorEndpoint', mediatorEndpoint)
          ..add('mediatorWSSEndpoint', mediatorWSSEndpoint))
        .toString();
  }
}

class CreateOobInputBuilder
    implements Builder<CreateOobInput, CreateOobInputBuilder> {
  _$CreateOobInput? _$v;

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

  CreateOobInputBuilder() {
    CreateOobInput._defaults(this);
  }

  CreateOobInputBuilder get _$this {
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
  void replace(CreateOobInput other) {
    _$v = other as _$CreateOobInput;
  }

  @override
  void update(void Function(CreateOobInputBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  CreateOobInput build() => _build();

  _$CreateOobInput _build() {
    final _$result = _$v ??
        _$CreateOobInput._(
          didcommMessage: BuiltValueNullFieldError.checkNotNull(
              didcommMessage, r'CreateOobInput', 'didcommMessage'),
          mediatorDid: BuiltValueNullFieldError.checkNotNull(
              mediatorDid, r'CreateOobInput', 'mediatorDid'),
          mediatorEndpoint: BuiltValueNullFieldError.checkNotNull(
              mediatorEndpoint, r'CreateOobInput', 'mediatorEndpoint'),
          mediatorWSSEndpoint: BuiltValueNullFieldError.checkNotNull(
              mediatorWSSEndpoint, r'CreateOobInput', 'mediatorWSSEndpoint'),
        );
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
