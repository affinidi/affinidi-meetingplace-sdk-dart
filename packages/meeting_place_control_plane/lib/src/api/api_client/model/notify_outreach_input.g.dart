// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'notify_outreach_input.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$NotifyOutreachInput extends NotifyOutreachInput {
  @override
  final String mnemonic;
  @override
  final String senderInfo;

  factory _$NotifyOutreachInput([
    void Function(NotifyOutreachInputBuilder)? updates,
  ]) => (NotifyOutreachInputBuilder()..update(updates))._build();

  _$NotifyOutreachInput._({required this.mnemonic, required this.senderInfo})
    : super._();
  @override
  NotifyOutreachInput rebuild(
    void Function(NotifyOutreachInputBuilder) updates,
  ) => (toBuilder()..update(updates)).build();

  @override
  NotifyOutreachInputBuilder toBuilder() =>
      NotifyOutreachInputBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is NotifyOutreachInput &&
        mnemonic == other.mnemonic &&
        senderInfo == other.senderInfo;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, mnemonic.hashCode);
    _$hash = $jc(_$hash, senderInfo.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'NotifyOutreachInput')
          ..add('mnemonic', mnemonic)
          ..add('senderInfo', senderInfo))
        .toString();
  }
}

class NotifyOutreachInputBuilder
    implements Builder<NotifyOutreachInput, NotifyOutreachInputBuilder> {
  _$NotifyOutreachInput? _$v;

  String? _mnemonic;
  String? get mnemonic => _$this._mnemonic;
  set mnemonic(String? mnemonic) => _$this._mnemonic = mnemonic;

  String? _senderInfo;
  String? get senderInfo => _$this._senderInfo;
  set senderInfo(String? senderInfo) => _$this._senderInfo = senderInfo;

  NotifyOutreachInputBuilder() {
    NotifyOutreachInput._defaults(this);
  }

  NotifyOutreachInputBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _mnemonic = $v.mnemonic;
      _senderInfo = $v.senderInfo;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(NotifyOutreachInput other) {
    _$v = other as _$NotifyOutreachInput;
  }

  @override
  void update(void Function(NotifyOutreachInputBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  NotifyOutreachInput build() => _build();

  _$NotifyOutreachInput _build() {
    final _$result =
        _$v ??
        _$NotifyOutreachInput._(
          mnemonic: BuiltValueNullFieldError.checkNotNull(
            mnemonic,
            r'NotifyOutreachInput',
            'mnemonic',
          ),
          senderInfo: BuiltValueNullFieldError.checkNotNull(
            senderInfo,
            r'NotifyOutreachInput',
            'senderInfo',
          ),
        );
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
