// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'update_offers_score_ok.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$UpdateOffersScoreOK extends UpdateOffersScoreOK {
  @override
  final BuiltList<String> updatedOffers;
  @override
  final BuiltList<UpdateOffersScoreOKFailedOffersInner> failedOffers;

  factory _$UpdateOffersScoreOK([
    void Function(UpdateOffersScoreOKBuilder)? updates,
  ]) => (UpdateOffersScoreOKBuilder()..update(updates))._build();

  _$UpdateOffersScoreOK._({
    required this.updatedOffers,
    required this.failedOffers,
  }) : super._();
  @override
  UpdateOffersScoreOK rebuild(
    void Function(UpdateOffersScoreOKBuilder) updates,
  ) => (toBuilder()..update(updates)).build();

  @override
  UpdateOffersScoreOKBuilder toBuilder() =>
      UpdateOffersScoreOKBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is UpdateOffersScoreOK &&
        updatedOffers == other.updatedOffers &&
        failedOffers == other.failedOffers;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, updatedOffers.hashCode);
    _$hash = $jc(_$hash, failedOffers.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'UpdateOffersScoreOK')
          ..add('updatedOffers', updatedOffers)
          ..add('failedOffers', failedOffers))
        .toString();
  }
}

class UpdateOffersScoreOKBuilder
    implements Builder<UpdateOffersScoreOK, UpdateOffersScoreOKBuilder> {
  _$UpdateOffersScoreOK? _$v;

  ListBuilder<String>? _updatedOffers;
  ListBuilder<String> get updatedOffers =>
      _$this._updatedOffers ??= ListBuilder<String>();
  set updatedOffers(ListBuilder<String>? updatedOffers) =>
      _$this._updatedOffers = updatedOffers;

  ListBuilder<UpdateOffersScoreOKFailedOffersInner>? _failedOffers;
  ListBuilder<UpdateOffersScoreOKFailedOffersInner> get failedOffers =>
      _$this._failedOffers ??=
          ListBuilder<UpdateOffersScoreOKFailedOffersInner>();
  set failedOffers(
    ListBuilder<UpdateOffersScoreOKFailedOffersInner>? failedOffers,
  ) => _$this._failedOffers = failedOffers;

  UpdateOffersScoreOKBuilder() {
    UpdateOffersScoreOK._defaults(this);
  }

  UpdateOffersScoreOKBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _updatedOffers = $v.updatedOffers.toBuilder();
      _failedOffers = $v.failedOffers.toBuilder();
      _$v = null;
    }
    return this;
  }

  @override
  void replace(UpdateOffersScoreOK other) {
    _$v = other as _$UpdateOffersScoreOK;
  }

  @override
  void update(void Function(UpdateOffersScoreOKBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  UpdateOffersScoreOK build() => _build();

  _$UpdateOffersScoreOK _build() {
    _$UpdateOffersScoreOK _$result;
    try {
      _$result =
          _$v ??
          _$UpdateOffersScoreOK._(
            updatedOffers: updatedOffers.build(),
            failedOffers: failedOffers.build(),
          );
    } catch (_) {
      late String _$failedField;
      try {
        _$failedField = 'updatedOffers';
        updatedOffers.build();
        _$failedField = 'failedOffers';
        failedOffers.build();
      } catch (e) {
        throw BuiltValueNestedFieldError(
          r'UpdateOffersScoreOK',
          _$failedField,
          e.toString(),
        );
      }
      rethrow;
    }
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
