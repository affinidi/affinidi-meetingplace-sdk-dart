// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'update_offers_score_error.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$UpdateOffersScoreError extends UpdateOffersScoreError {
  @override
  final String errorCode;
  @override
  final String errorMessage;

  factory _$UpdateOffersScoreError([
    void Function(UpdateOffersScoreErrorBuilder)? updates,
  ]) => (UpdateOffersScoreErrorBuilder()..update(updates))._build();

  _$UpdateOffersScoreError._({
    required this.errorCode,
    required this.errorMessage,
  }) : super._();
  @override
  UpdateOffersScoreError rebuild(
    void Function(UpdateOffersScoreErrorBuilder) updates,
  ) => (toBuilder()..update(updates)).build();

  @override
  UpdateOffersScoreErrorBuilder toBuilder() =>
      UpdateOffersScoreErrorBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is UpdateOffersScoreError &&
        errorCode == other.errorCode &&
        errorMessage == other.errorMessage;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, errorCode.hashCode);
    _$hash = $jc(_$hash, errorMessage.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'UpdateOffersScoreError')
          ..add('errorCode', errorCode)
          ..add('errorMessage', errorMessage))
        .toString();
  }
}

class UpdateOffersScoreErrorBuilder
    implements Builder<UpdateOffersScoreError, UpdateOffersScoreErrorBuilder> {
  _$UpdateOffersScoreError? _$v;

  String? _errorCode;
  String? get errorCode => _$this._errorCode;
  set errorCode(String? errorCode) => _$this._errorCode = errorCode;

  String? _errorMessage;
  String? get errorMessage => _$this._errorMessage;
  set errorMessage(String? errorMessage) => _$this._errorMessage = errorMessage;

  UpdateOffersScoreErrorBuilder() {
    UpdateOffersScoreError._defaults(this);
  }

  UpdateOffersScoreErrorBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _errorCode = $v.errorCode;
      _errorMessage = $v.errorMessage;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(UpdateOffersScoreError other) {
    _$v = other as _$UpdateOffersScoreError;
  }

  @override
  void update(void Function(UpdateOffersScoreErrorBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  UpdateOffersScoreError build() => _build();

  _$UpdateOffersScoreError _build() {
    final _$result =
        _$v ??
        _$UpdateOffersScoreError._(
          errorCode: BuiltValueNullFieldError.checkNotNull(
            errorCode,
            r'UpdateOffersScoreError',
            'errorCode',
          ),
          errorMessage: BuiltValueNullFieldError.checkNotNull(
            errorMessage,
            r'UpdateOffersScoreError',
            'errorMessage',
          ),
        );
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
