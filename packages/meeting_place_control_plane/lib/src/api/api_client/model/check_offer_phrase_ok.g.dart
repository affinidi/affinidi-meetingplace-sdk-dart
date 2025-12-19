// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'check_offer_phrase_ok.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$CheckOfferPhraseOK extends CheckOfferPhraseOK {
  @override
  final bool isInUse;

  factory _$CheckOfferPhraseOK([
    void Function(CheckOfferPhraseOKBuilder)? updates,
  ]) => (CheckOfferPhraseOKBuilder()..update(updates))._build();

  _$CheckOfferPhraseOK._({required this.isInUse}) : super._();
  @override
  CheckOfferPhraseOK rebuild(
    void Function(CheckOfferPhraseOKBuilder) updates,
  ) => (toBuilder()..update(updates)).build();

  @override
  CheckOfferPhraseOKBuilder toBuilder() =>
      CheckOfferPhraseOKBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is CheckOfferPhraseOK && isInUse == other.isInUse;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, isInUse.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(
      r'CheckOfferPhraseOK',
    )..add('isInUse', isInUse)).toString();
  }
}

class CheckOfferPhraseOKBuilder
    implements Builder<CheckOfferPhraseOK, CheckOfferPhraseOKBuilder> {
  _$CheckOfferPhraseOK? _$v;

  bool? _isInUse;
  bool? get isInUse => _$this._isInUse;
  set isInUse(bool? isInUse) => _$this._isInUse = isInUse;

  CheckOfferPhraseOKBuilder() {
    CheckOfferPhraseOK._defaults(this);
  }

  CheckOfferPhraseOKBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _isInUse = $v.isInUse;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(CheckOfferPhraseOK other) {
    _$v = other as _$CheckOfferPhraseOK;
  }

  @override
  void update(void Function(CheckOfferPhraseOKBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  CheckOfferPhraseOK build() => _build();

  _$CheckOfferPhraseOK _build() {
    final _$result =
        _$v ??
        _$CheckOfferPhraseOK._(
          isInUse: BuiltValueNullFieldError.checkNotNull(
            isInUse,
            r'CheckOfferPhraseOK',
            'isInUse',
          ),
        );
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
