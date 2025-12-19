// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'create_oob_ok.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$CreateOobOK extends CreateOobOK {
  @override
  final String oobUrl;
  @override
  final String oobId;

  factory _$CreateOobOK([void Function(CreateOobOKBuilder)? updates]) =>
      (CreateOobOKBuilder()..update(updates))._build();

  _$CreateOobOK._({required this.oobUrl, required this.oobId}) : super._();
  @override
  CreateOobOK rebuild(void Function(CreateOobOKBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  CreateOobOKBuilder toBuilder() => CreateOobOKBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is CreateOobOK &&
        oobUrl == other.oobUrl &&
        oobId == other.oobId;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, oobUrl.hashCode);
    _$hash = $jc(_$hash, oobId.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'CreateOobOK')
          ..add('oobUrl', oobUrl)
          ..add('oobId', oobId))
        .toString();
  }
}

class CreateOobOKBuilder implements Builder<CreateOobOK, CreateOobOKBuilder> {
  _$CreateOobOK? _$v;

  String? _oobUrl;
  String? get oobUrl => _$this._oobUrl;
  set oobUrl(String? oobUrl) => _$this._oobUrl = oobUrl;

  String? _oobId;
  String? get oobId => _$this._oobId;
  set oobId(String? oobId) => _$this._oobId = oobId;

  CreateOobOKBuilder() {
    CreateOobOK._defaults(this);
  }

  CreateOobOKBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _oobUrl = $v.oobUrl;
      _oobId = $v.oobId;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(CreateOobOK other) {
    _$v = other as _$CreateOobOK;
  }

  @override
  void update(void Function(CreateOobOKBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  CreateOobOK build() => _build();

  _$CreateOobOK _build() {
    final _$result =
        _$v ??
        _$CreateOobOK._(
          oobUrl: BuiltValueNullFieldError.checkNotNull(
            oobUrl,
            r'CreateOobOK',
            'oobUrl',
          ),
          oobId: BuiltValueNullFieldError.checkNotNull(
            oobId,
            r'CreateOobOK',
            'oobId',
          ),
        );
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
