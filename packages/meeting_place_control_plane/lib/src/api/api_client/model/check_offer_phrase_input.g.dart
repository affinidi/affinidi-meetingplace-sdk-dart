// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'check_offer_phrase_input.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$CheckOfferPhraseInput extends CheckOfferPhraseInput {
  @override
  final String offerPhrase;

  factory _$CheckOfferPhraseInput([
    void Function(CheckOfferPhraseInputBuilder)? updates,
  ]) => (CheckOfferPhraseInputBuilder()..update(updates))._build();

  _$CheckOfferPhraseInput._({required this.offerPhrase}) : super._();
  @override
  CheckOfferPhraseInput rebuild(
    void Function(CheckOfferPhraseInputBuilder) updates,
  ) => (toBuilder()..update(updates)).build();

  @override
  CheckOfferPhraseInputBuilder toBuilder() =>
      CheckOfferPhraseInputBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is CheckOfferPhraseInput && offerPhrase == other.offerPhrase;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, offerPhrase.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(
      r'CheckOfferPhraseInput',
    )..add('offerPhrase', offerPhrase)).toString();
  }
}

class CheckOfferPhraseInputBuilder
    implements Builder<CheckOfferPhraseInput, CheckOfferPhraseInputBuilder> {
  _$CheckOfferPhraseInput? _$v;

  String? _offerPhrase;
  String? get offerPhrase => _$this._offerPhrase;
  set offerPhrase(String? offerPhrase) => _$this._offerPhrase = offerPhrase;

  CheckOfferPhraseInputBuilder() {
    CheckOfferPhraseInput._defaults(this);
  }

  CheckOfferPhraseInputBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _offerPhrase = $v.offerPhrase;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(CheckOfferPhraseInput other) {
    _$v = other as _$CheckOfferPhraseInput;
  }

  @override
  void update(void Function(CheckOfferPhraseInputBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  CheckOfferPhraseInput build() => _build();

  _$CheckOfferPhraseInput _build() {
    final _$result =
        _$v ??
        _$CheckOfferPhraseInput._(
          offerPhrase: BuiltValueNullFieldError.checkNotNull(
            offerPhrase,
            r'CheckOfferPhraseInput',
            'offerPhrase',
          ),
        );
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
