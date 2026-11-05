import 'vetting_statement.dart';

/// How a vetter met the applicant (`VettingMethod`).
enum VettingMethod {
  /// Face to face.
  inPerson,

  /// Over a video call.
  video,

  /// The vetter already knew the applicant.
  priorAcquaintance,
}

/// How a vetter declares they know the applicant (`VettingRelationship`).
enum VettingRelationship {
  /// Not at all before the session.
  none,

  /// From within the community.
  communityColleague,

  /// They work for the same employer.
  sameEmployer,

  /// Family.
  family,

  /// Any other personal tie.
  otherPersonal,
}

/// What a criterion asks of vetting, as its join manifest states it
/// (`VettingRequirements` of `vtc/join-requests/manifest/0.4`).
///
/// An absent optional member means the community imposes no constraint of
/// that kind.
class VettingRequirements {
  /// Creates [VettingRequirements].
  const VettingRequirements({
    required this.statementType,
    required this.minStatements,
    required this.acceptedMethods,
    required this.vetterRole,
    this.minByMethod = const {},
    this.requiredClaims = const [],
    this.optionalClaims = const [],
    this.maxStatementAge,
    this.acceptedDocumentClasses,
    this.maxByDeclaredRelationship = const {},
    this.requireConsistentIdentityCommitment = false,
  });

  /// The predicate a statement must carry, e.g. `…/dtg/vsc/vetted/1`.
  final String statementType;

  /// How many distinct vetters must vouch.
  final int minStatements;

  /// The methods a statement may have been made by.
  final List<VettingMethod> acceptedMethods;

  /// The role a vetter must hold in the community, e.g. `vetter`.
  final String vetterRole;

  /// How many counted statements each method needs at least.
  final Map<VettingMethod, int> minByMethod;

  /// The claims each vetter must have verified, e.g. `name.legal`.
  final List<String> requiredClaims;

  /// The claims a vetter may verify besides.
  final List<String> optionalClaims;

  /// How old a statement may be when the community decides, or null for no
  /// limit beyond its own validity.
  final Duration? maxStatementAge;

  /// The documentation a statement must have relied on, or null for any.
  final List<String>? acceptedDocumentClasses;

  /// How many counted statements may declare each relationship.
  final Map<VettingRelationship, int> maxByDeclaredRelationship;

  /// Whether every statement must carry the same identity commitment.
  final bool requireConsistentIdentityCommitment;

  /// Reads [json], or returns null when this wallet cannot meet it: a
  /// required member missing or malformed, a duration it cannot read, or an
  /// `extCritical` namespace, none of which it understands.
  static VettingRequirements? read(Object? json) {
    if (json is! Map) return null;
    final statementType = json['statementType'];
    final minStatements = json['minStatements'];
    final eligible = json['eligibleVetters'];
    final role = eligible is Map ? eligible['role'] : null;
    final methods = _methods(json['acceptedMethods']);
    final critical = json['extCritical'];
    if (statementType is! String ||
        minStatements is! int ||
        minStatements < 1 ||
        role is! String ||
        methods == null ||
        methods.isEmpty ||
        (critical is List && critical.isNotEmpty)) {
      return null;
    }

    Duration? maxStatementAge;
    if (json['maxStatementAge'] != null) {
      maxStatementAge = parseVettingDuration(json['maxStatementAge']);
      if (maxStatementAge == null) return null;
    }
    final independence = json['independence'];
    return VettingRequirements(
      statementType: statementType,
      minStatements: minStatements,
      acceptedMethods: methods,
      vetterRole: role,
      minByMethod: _counts(json['minByMethod'], VettingMethod.values),
      requiredClaims: _strings(json['requiredClaims']) ?? const [],
      optionalClaims: _strings(json['optionalClaims']) ?? const [],
      maxStatementAge: maxStatementAge,
      acceptedDocumentClasses: _strings(json['acceptedDocumentClasses']),
      maxByDeclaredRelationship: _counts(
        independence is Map ? independence['maxByDeclaredRelationship'] : null,
        VettingRelationship.values,
      ),
      requireConsistentIdentityCommitment:
          independence is Map &&
          independence['requireConsistentIdentityCommitment'] == true,
    );
  }

  static List<VettingMethod>? _methods(Object? json) {
    if (json is! List) return null;
    final byName = VettingMethod.values.asNameMap();
    // A method this wallet does not know is one no statement it holds has.
    return [
      for (final name in json)
        if (byName[name] case final VettingMethod method) method,
    ];
  }

  static List<String>? _strings(Object? json) =>
      json is List ? json.whereType<String>().toList() : null;

  static Map<T, int> _counts<T extends Enum>(Object? json, List<T> values) {
    if (json is! Map) return const {};
    final byName = values.asNameMap();
    return {
      for (final MapEntry(:key, :value) in json.entries)
        if ((byName[key], value) case (final T name, final int count))
          name: count,
    };
  }
}

/// Reads an ISO 8601 duration as vetting writes it: weeks, days, hours,
/// minutes and seconds, each at most once and in that order (`P120D`,
/// `PT15M`). Years and months have no fixed length, so they are not read.
/// Returns null for anything else.
Duration? parseVettingDuration(Object? value) {
  if (value is! String) return null;
  final match = _durationPattern.firstMatch(value);
  if (match == null || value == 'P' || value.endsWith('T')) return null;
  int part(int group) => int.parse(match.group(group) ?? '0');
  return Duration(
    days: part(1) * 7 + part(2),
    hours: part(3),
    minutes: part(4),
    seconds: part(5),
  );
}

final _durationPattern = RegExp(
  r'^P(?:(\d+)W)?(?:(\d+)D)?(?:T(?:(\d+)H)?(?:(\d+)M)?(?:(\d+)S)?)?$',
);

/// Something an application still lacks.
sealed class VettingNeed {
  const VettingNeed(this.count);

  /// How many more.
  final int count;
}

/// More statements from distinct vetters.
class MoreStatements extends VettingNeed {
  /// Creates a [MoreStatements].
  const MoreStatements(super.count);
}

/// More counted statements made by [method].
class MoreByMethod extends VettingNeed {
  /// Creates a [MoreByMethod].
  const MoreByMethod(this.method, super.count);

  /// The method they must be made by.
  final VettingMethod method;
}

/// How far an applicant's statements go towards a criterion's
/// [VettingRequirements], counted the way the community counts.
///
/// Advisory: the community checks every statement again and decides. A
/// statement counts once per vetter, the newest one kept.
class VettingProgress {
  const VettingProgress._({
    required this.counted,
    required this.needs,
    required this.commitmentsConsistent,
    required this.independent,
  });

  /// Counts [statements] against [requirements] for [communityDid] at [now].
  factory VettingProgress.of({
    required VettingRequirements requirements,
    required String communityDid,
    required List<VettingStatement> statements,
    required DateTime now,
  }) {
    final newestFirst = [...statements]
      ..sort((a, b) => b.validFrom.compareTo(a.validFrom));
    final counted = <VettingStatement>[];
    final vetters = <String>{};
    final byMethod = <VettingMethod, int>{};
    final byRelationship = <VettingRelationship, int>{};

    for (final statement in newestFirst) {
      if (!_counts(statement, requirements, communityDid, now) ||
          !vetters.add(statement.vetterDid)) {
        continue;
      }
      counted.add(statement);
      byMethod.update(statement.method, (n) => n + 1, ifAbsent: () => 1);
      byRelationship.update(
        statement.declaredRelationship,
        (n) => n + 1,
        ifAbsent: () => 1,
      );
    }

    final missing = requirements.minStatements - counted.length;
    return VettingProgress._(
      counted: List.unmodifiable(counted),
      needs: List.unmodifiable([
        if (missing > 0) MoreStatements(missing),
        for (final method in VettingMethod.values)
          if ((requirements.minByMethod[method] ?? 0) - (byMethod[method] ?? 0)
              case final more when more > 0)
            MoreByMethod(method, more),
      ]),
      commitmentsConsistent:
          !requirements.requireConsistentIdentityCommitment ||
          statements.map((s) => s.identityCommitment).toSet().length <= 1,
      independent: requirements.maxByDeclaredRelationship.entries.every(
        (cap) => (byRelationship[cap.key] ?? 0) <= cap.value,
      ),
    );
  }

  /// The statements that count, one per vetter.
  final List<VettingStatement> counted;

  /// What is still missing. Empty when the count and method floors are met.
  final List<VettingNeed> needs;

  /// Whether all statements carry one identity commitment, where the
  /// community asks for that.
  final bool commitmentsConsistent;

  /// Whether no cap on declared relationships is exceeded.
  final bool independent;

  /// Whether the statements meet the requirements, as far as this wallet
  /// can tell.
  bool get satisfied => needs.isEmpty && commitmentsConsistent && independent;

  static bool _counts(
    VettingStatement statement,
    VettingRequirements requirements,
    String communityDid,
    DateTime now,
  ) {
    final documentClasses = requirements.acceptedDocumentClasses;
    final documented =
        documentClasses == null ||
        statement.documentClasses.any(documentClasses.contains) ||
        (statement.method == VettingMethod.priorAcquaintance &&
            statement.documentClasses.isEmpty);
    final maxAge = requirements.maxStatementAge;
    return statement.community == communityDid &&
        requirements.acceptedMethods.contains(statement.method) &&
        documented &&
        requirements.requiredClaims.every(statement.claimsVerified.contains) &&
        (maxAge == null || now.difference(statement.validFrom) <= maxAge);
  }
}
