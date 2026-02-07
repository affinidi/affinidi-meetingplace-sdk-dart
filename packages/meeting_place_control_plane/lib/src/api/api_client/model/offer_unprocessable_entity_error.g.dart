// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'offer_unprocessable_entity_error.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$OfferUnprocessableEntityError extends OfferUnprocessableEntityError {
  @override
  final String errorCode;
  @override
  final String errorMessage;

  factory _$OfferUnprocessableEntityError([
    void Function(OfferUnprocessableEntityErrorBuilder)? updates,
  ]) => (OfferUnprocessableEntityErrorBuilder()..update(updates))._build();

  _$OfferUnprocessableEntityError._({
    required this.errorCode,
    required this.errorMessage,
  }) : super._();
  @override
  OfferUnprocessableEntityError rebuild(
    void Function(OfferUnprocessableEntityErrorBuilder) updates,
  ) => (toBuilder()..update(updates)).build();

  @override
  OfferUnprocessableEntityErrorBuilder toBuilder() =>
      OfferUnprocessableEntityErrorBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is OfferUnprocessableEntityError &&
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
    return (newBuiltValueToStringHelper(r'OfferUnprocessableEntityError')
          ..add('errorCode', errorCode)
          ..add('errorMessage', errorMessage))
        .toString();
  }
}

class OfferUnprocessableEntityErrorBuilder
    implements
        Builder<
          OfferUnprocessableEntityError,
          OfferUnprocessableEntityErrorBuilder
        > {
  _$OfferUnprocessableEntityError? _$v;

  String? _errorCode;
  String? get errorCode => _$this._errorCode;
  set errorCode(String? errorCode) => _$this._errorCode = errorCode;

  String? _errorMessage;
  String? get errorMessage => _$this._errorMessage;
  set errorMessage(String? errorMessage) => _$this._errorMessage = errorMessage;

  OfferUnprocessableEntityErrorBuilder() {
    OfferUnprocessableEntityError._defaults(this);
  }

  OfferUnprocessableEntityErrorBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _errorCode = $v.errorCode;
      _errorMessage = $v.errorMessage;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(OfferUnprocessableEntityError other) {
    _$v = other as _$OfferUnprocessableEntityError;
  }

  @override
  void update(void Function(OfferUnprocessableEntityErrorBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  OfferUnprocessableEntityError build() => _build();

  _$OfferUnprocessableEntityError _build() {
    final _$result =
        _$v ??
        _$OfferUnprocessableEntityError._(
          errorCode: BuiltValueNullFieldError.checkNotNull(
            errorCode,
            r'OfferUnprocessableEntityError',
            'errorCode',
          ),
          errorMessage: BuiltValueNullFieldError.checkNotNull(
            errorMessage,
            r'OfferUnprocessableEntityError',
            'errorMessage',
          ),
        );
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
