// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'update_offers_score_input.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$UpdateOffersScoreInput extends UpdateOffersScoreInput {
  @override
  final int score;
  @override
  final BuiltList<String> mnemonics;

  factory _$UpdateOffersScoreInput([
    void Function(UpdateOffersScoreInputBuilder)? updates,
  ]) => (UpdateOffersScoreInputBuilder()..update(updates))._build();

  _$UpdateOffersScoreInput._({required this.score, required this.mnemonics})
    : super._();
  @override
  UpdateOffersScoreInput rebuild(
    void Function(UpdateOffersScoreInputBuilder) updates,
  ) => (toBuilder()..update(updates)).build();

  @override
  UpdateOffersScoreInputBuilder toBuilder() =>
      UpdateOffersScoreInputBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is UpdateOffersScoreInput &&
        score == other.score &&
        mnemonics == other.mnemonics;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, score.hashCode);
    _$hash = $jc(_$hash, mnemonics.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'UpdateOffersScoreInput')
          ..add('score', score)
          ..add('mnemonics', mnemonics))
        .toString();
  }
}

class UpdateOffersScoreInputBuilder
    implements Builder<UpdateOffersScoreInput, UpdateOffersScoreInputBuilder> {
  _$UpdateOffersScoreInput? _$v;

  int? _score;
  int? get score => _$this._score;
  set score(int? score) => _$this._score = score;

  ListBuilder<String>? _mnemonics;
  ListBuilder<String> get mnemonics =>
      _$this._mnemonics ??= ListBuilder<String>();
  set mnemonics(ListBuilder<String>? mnemonics) =>
      _$this._mnemonics = mnemonics;

  UpdateOffersScoreInputBuilder() {
    UpdateOffersScoreInput._defaults(this);
  }

  UpdateOffersScoreInputBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _score = $v.score;
      _mnemonics = $v.mnemonics.toBuilder();
      _$v = null;
    }
    return this;
  }

  @override
  void replace(UpdateOffersScoreInput other) {
    _$v = other as _$UpdateOffersScoreInput;
  }

  @override
  void update(void Function(UpdateOffersScoreInputBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  UpdateOffersScoreInput build() => _build();

  _$UpdateOffersScoreInput _build() {
    _$UpdateOffersScoreInput _$result;
    try {
      _$result =
          _$v ??
          _$UpdateOffersScoreInput._(
            score: BuiltValueNullFieldError.checkNotNull(
              score,
              r'UpdateOffersScoreInput',
              'score',
            ),
            mnemonics: mnemonics.build(),
          );
    } catch (_) {
      late String _$failedField;
      try {
        _$failedField = 'mnemonics';
        mnemonics.build();
      } catch (e) {
        throw BuiltValueNestedFieldError(
          r'UpdateOffersScoreInput',
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
