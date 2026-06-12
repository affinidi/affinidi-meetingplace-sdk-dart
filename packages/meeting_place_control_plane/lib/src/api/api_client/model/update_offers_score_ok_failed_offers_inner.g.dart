// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'update_offers_score_ok_failed_offers_inner.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$UpdateOffersScoreOKFailedOffersInner
    extends UpdateOffersScoreOKFailedOffersInner {
  @override
  final String? mnemonic;
  @override
  final String? reason;

  factory _$UpdateOffersScoreOKFailedOffersInner([
    void Function(UpdateOffersScoreOKFailedOffersInnerBuilder)? updates,
  ]) =>
      (UpdateOffersScoreOKFailedOffersInnerBuilder()..update(updates))._build();

  _$UpdateOffersScoreOKFailedOffersInner._({this.mnemonic, this.reason})
    : super._();
  @override
  UpdateOffersScoreOKFailedOffersInner rebuild(
    void Function(UpdateOffersScoreOKFailedOffersInnerBuilder) updates,
  ) => (toBuilder()..update(updates)).build();

  @override
  UpdateOffersScoreOKFailedOffersInnerBuilder toBuilder() =>
      UpdateOffersScoreOKFailedOffersInnerBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is UpdateOffersScoreOKFailedOffersInner &&
        mnemonic == other.mnemonic &&
        reason == other.reason;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, mnemonic.hashCode);
    _$hash = $jc(_$hash, reason.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'UpdateOffersScoreOKFailedOffersInner')
          ..add('mnemonic', mnemonic)
          ..add('reason', reason))
        .toString();
  }
}

class UpdateOffersScoreOKFailedOffersInnerBuilder
    implements
        Builder<
          UpdateOffersScoreOKFailedOffersInner,
          UpdateOffersScoreOKFailedOffersInnerBuilder
        > {
  _$UpdateOffersScoreOKFailedOffersInner? _$v;

  String? _mnemonic;
  String? get mnemonic => _$this._mnemonic;
  set mnemonic(String? mnemonic) => _$this._mnemonic = mnemonic;

  String? _reason;
  String? get reason => _$this._reason;
  set reason(String? reason) => _$this._reason = reason;

  UpdateOffersScoreOKFailedOffersInnerBuilder() {
    UpdateOffersScoreOKFailedOffersInner._defaults(this);
  }

  UpdateOffersScoreOKFailedOffersInnerBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _mnemonic = $v.mnemonic;
      _reason = $v.reason;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(UpdateOffersScoreOKFailedOffersInner other) {
    _$v = other as _$UpdateOffersScoreOKFailedOffersInner;
  }

  @override
  void update(
    void Function(UpdateOffersScoreOKFailedOffersInnerBuilder)? updates,
  ) {
    if (updates != null) updates(this);
  }

  @override
  UpdateOffersScoreOKFailedOffersInner build() => _build();

  _$UpdateOffersScoreOKFailedOffersInner _build() {
    final _$result =
        _$v ??
        _$UpdateOffersScoreOKFailedOffersInner._(
          mnemonic: mnemonic,
          reason: reason,
        );
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
