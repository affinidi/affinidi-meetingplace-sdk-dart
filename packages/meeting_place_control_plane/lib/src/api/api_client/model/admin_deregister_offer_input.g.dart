// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'admin_deregister_offer_input.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$AdminDeregisterOfferInput extends AdminDeregisterOfferInput {
  @override
  final String mnemonic;

  factory _$AdminDeregisterOfferInput([
    void Function(AdminDeregisterOfferInputBuilder)? updates,
  ]) => (AdminDeregisterOfferInputBuilder()..update(updates))._build();

  _$AdminDeregisterOfferInput._({required this.mnemonic}) : super._();
  @override
  AdminDeregisterOfferInput rebuild(
    void Function(AdminDeregisterOfferInputBuilder) updates,
  ) => (toBuilder()..update(updates)).build();

  @override
  AdminDeregisterOfferInputBuilder toBuilder() =>
      AdminDeregisterOfferInputBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is AdminDeregisterOfferInput && mnemonic == other.mnemonic;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, mnemonic.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(
      r'AdminDeregisterOfferInput',
    )..add('mnemonic', mnemonic)).toString();
  }
}

class AdminDeregisterOfferInputBuilder
    implements
        Builder<AdminDeregisterOfferInput, AdminDeregisterOfferInputBuilder> {
  _$AdminDeregisterOfferInput? _$v;

  String? _mnemonic;
  String? get mnemonic => _$this._mnemonic;
  set mnemonic(String? mnemonic) => _$this._mnemonic = mnemonic;

  AdminDeregisterOfferInputBuilder() {
    AdminDeregisterOfferInput._defaults(this);
  }

  AdminDeregisterOfferInputBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _mnemonic = $v.mnemonic;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(AdminDeregisterOfferInput other) {
    _$v = other as _$AdminDeregisterOfferInput;
  }

  @override
  void update(void Function(AdminDeregisterOfferInputBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  AdminDeregisterOfferInput build() => _build();

  _$AdminDeregisterOfferInput _build() {
    final _$result =
        _$v ??
        _$AdminDeregisterOfferInput._(
          mnemonic: BuiltValueNullFieldError.checkNotNull(
            mnemonic,
            r'AdminDeregisterOfferInput',
            'mnemonic',
          ),
        );
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
