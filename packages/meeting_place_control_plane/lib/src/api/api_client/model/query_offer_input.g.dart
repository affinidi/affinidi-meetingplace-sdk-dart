// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'query_offer_input.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$QueryOfferInput extends QueryOfferInput {
  @override
  final String mnemonic;

  factory _$QueryOfferInput([void Function(QueryOfferInputBuilder)? updates]) =>
      (QueryOfferInputBuilder()..update(updates))._build();

  _$QueryOfferInput._({required this.mnemonic}) : super._();
  @override
  QueryOfferInput rebuild(void Function(QueryOfferInputBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  QueryOfferInputBuilder toBuilder() => QueryOfferInputBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is QueryOfferInput && mnemonic == other.mnemonic;
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
      r'QueryOfferInput',
    )..add('mnemonic', mnemonic)).toString();
  }
}

class QueryOfferInputBuilder
    implements Builder<QueryOfferInput, QueryOfferInputBuilder> {
  _$QueryOfferInput? _$v;

  String? _mnemonic;
  String? get mnemonic => _$this._mnemonic;
  set mnemonic(String? mnemonic) => _$this._mnemonic = mnemonic;

  QueryOfferInputBuilder() {
    QueryOfferInput._defaults(this);
  }

  QueryOfferInputBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _mnemonic = $v.mnemonic;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(QueryOfferInput other) {
    _$v = other as _$QueryOfferInput;
  }

  @override
  void update(void Function(QueryOfferInputBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  QueryOfferInput build() => _build();

  _$QueryOfferInput _build() {
    final _$result =
        _$v ??
        _$QueryOfferInput._(
          mnemonic: BuiltValueNullFieldError.checkNotNull(
            mnemonic,
            r'QueryOfferInput',
            'mnemonic',
          ),
        );
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
