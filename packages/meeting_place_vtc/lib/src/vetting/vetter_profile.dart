import '../meeting_place_vtc_sdk_exception.dart';
import 'vetting_requirements.dart';

/// Where a vetter meets people, as coarse as they choose: a country,
/// optionally a region, optionally a city. Never a street address.
class VetterLocation {
  /// Creates a [VetterLocation].
  const VetterLocation({required this.country, this.region, this.city});

  /// Reads a location [toJson] wrote.
  factory VetterLocation.fromJson(Map<String, dynamic> json) => VetterLocation(
    country: json['country'] as String,
    region: json['region'] as String?,
    city: json['city'] as String?,
  );

  /// An ISO 3166-1 alpha-2 country code, upper case, e.g. `DE`.
  final String country;

  /// A region, as the vetter writes it.
  final String? region;

  /// A city, as the vetter writes it.
  final String? city;

  /// The location as a profile carries it.
  Map<String, dynamic> toJson() => {
    'country': country,
    'region': ?region,
    'city': ?city,
  };

  void _check(String at) {
    _require(_country.hasMatch(country), '$at.country: not an ISO country');
    _checkText(region, '$at.region', VetterProfile.maxPlaceLength);
    _checkText(city, '$at.city', VetterProfile.maxPlaceLength);
  }
}

/// An event a vetter will attend and vet at.
class VetterEvent {
  /// Creates a [VetterEvent]. Only the calendar dates of [startDate] and
  /// [endDate] count.
  const VetterEvent({
    required this.name,
    required this.startDate,
    required this.endDate,
    this.location,
    this.url,
  });

  /// Reads an event [toJson] wrote.
  factory VetterEvent.fromJson(Map<String, dynamic> json) => VetterEvent(
    name: json['name'] as String,
    startDate: DateTime.parse(json['startDate'] as String),
    endDate: DateTime.parse(json['endDate'] as String),
    location: switch (json['location']) {
      final Map<String, dynamic> location => VetterLocation.fromJson(location),
      _ => null,
    },
    url: switch (json['url']) {
      final String url => Uri.parse(url),
      _ => null,
    },
  );

  /// The event's name, e.g. `Linux Plumbers Conference 2026`.
  final String name;

  /// The event's first day.
  final DateTime startDate;

  /// The event's last day: on or after [startDate], at most
  /// [VetterProfile.maxEventDays] after it.
  final DateTime endDate;

  /// Where the event is.
  final VetterLocation? location;

  /// The event's own https page.
  final Uri? url;

  /// The event as a profile carries it.
  Map<String, dynamic> toJson() => {
    'name': name,
    'startDate': _calendarDate(startDate),
    'endDate': _calendarDate(endDate),
    if (location case final location?) 'location': location.toJson(),
    if (url case final url?) 'url': url.toString(),
  };

  void _check(String at) {
    _checkText(name, '$at.name', VetterProfile.maxEventNameLength);
    final days = _day(endDate).difference(_day(startDate)).inDays;
    _require(days >= 0, '$at.endDate: before startDate');
    _require(
      days <= VetterProfile.maxEventDays,
      '$at.endDate: more than ${VetterProfile.maxEventDays} days after '
      'startDate',
    );
    location?._check('$at.location');
    if (url case final url?) {
      _require(
        url.scheme == 'https' && url.host.isNotEmpty,
        '$at.url: not an https page',
      );
    }
  }
}

/// What a vetter tells applicants about themselves, published to their
/// community with `vtc/vetting/vetters/profile/0.1`. It replaces whatever
/// the community held; [listed] `false` keeps it there but out of the
/// community's listing.
///
/// Everything in it is the vetter's own word: applicants are shown it as
/// theirs, unverified.
class VetterProfile {
  /// Creates a [VetterProfile].
  const VetterProfile({
    required this.methods,
    this.listed = false,
    this.displayName,
    this.languages = const [],
    this.location,
    this.acceptsDocumentation = const [],
    this.availability,
    this.contactHint,
    this.events = const [],
  });

  /// Reads a profile [toJson] wrote, e.g. the one a vetter last published.
  factory VetterProfile.fromJson(Map<String, dynamic> json) => VetterProfile(
    listed: json['listed'] as bool,
    displayName: json['displayName'] as String?,
    languages: (json['languages'] as List<dynamic>).cast<String>(),
    location: switch (json['location']) {
      final Map<String, dynamic> location => VetterLocation.fromJson(location),
      _ => null,
    },
    methods: [
      for (final method in json['methods'] as List<dynamic>)
        VettingMethod.values.byName(method as String),
    ],
    acceptsDocumentation: (json['acceptsDocumentation'] as List<dynamic>)
        .cast<String>(),
    availability: json['availability'] as String?,
    contactHint: json['contactHint'] as String?,
    events: [
      for (final event in json['events'] as List<dynamic>)
        VetterEvent.fromJson(event as Map<String, dynamic>),
    ],
  );

  /// The most methods a vetter offers.
  static const maxMethods = 3;

  /// The most languages a profile names.
  static const maxLanguages = 16;

  /// The most documentation classes a profile names.
  static const maxDocumentation = 16;

  /// The most events a profile names.
  static const maxEvents = 32;

  /// The most days an event's last day may be after its first.
  static const maxEventDays = 31;

  /// The longest [displayName].
  static const maxDisplayNameLength = 128;

  /// The longest [availability].
  static const maxAvailabilityLength = 500;

  /// The longest [contactHint].
  static const maxContactHintLength = 300;

  /// The longest region or city name.
  static const maxPlaceLength = 128;

  /// The longest event name.
  static const maxEventNameLength = 200;

  /// Whether applicants find the vetter in the community's listing.
  final bool listed;

  /// The name the vetter is listed under.
  final String? displayName;

  /// The languages the vetter holds a session in, as BCP 47 tags, most
  /// preferred first.
  final List<String> languages;

  /// Where the vetter meets people.
  final VetterLocation? location;

  /// The methods the vetter offers: at least one.
  final List<VettingMethod> methods;

  /// The documentation the vetter relies on, in lowerCamelCase, e.g.
  /// `passport`, `nationalId`, `driverLicence`, or `none`.
  final List<String> acceptsDocumentation;

  /// When the vetter is available, in their words.
  final String? availability;

  /// How to get a ticket from the vetter, in their words.
  final String? contactHint;

  /// The events the vetter will vet at.
  final List<VetterEvent> events;

  /// Throws [MeetingPlaceVtcSDKException] with an `invalidDocument` code,
  /// naming the member, when the community would refuse the profile.
  void check() {
    _checkText(displayName, 'displayName', maxDisplayNameLength);
    _checkList(languages, 'languages', maxLanguages);
    for (final language in languages) {
      _require(
        _language.hasMatch(language) && language.length <= _maxLanguageLength,
        'languages: $language',
      );
    }
    location?._check('location');
    _require(methods.isNotEmpty, 'methods: none');
    _checkList(methods, 'methods', maxMethods);
    _checkList(acceptsDocumentation, 'acceptsDocumentation', maxDocumentation);
    for (final documentation in acceptsDocumentation) {
      _require(
        _documentation.hasMatch(documentation),
        'acceptsDocumentation: $documentation',
      );
    }
    _checkText(availability, 'availability', maxAvailabilityLength);
    _checkText(contactHint, 'contactHint', maxContactHintLength);
    _require(events.length <= maxEvents, 'events: more than $maxEvents');
    for (final (i, event) in events.indexed) {
      event._check('events[$i]');
    }
  }

  /// The profile as `vtc/vetting/vetters/profile/0.1` carries it, after
  /// [check].
  Map<String, dynamic> toJson() {
    check();
    return {
      'listed': listed,
      'displayName': ?displayName,
      'languages': languages,
      if (location case final location?) 'location': location.toJson(),
      'methods': [for (final method in methods) method.name],
      'acceptsDocumentation': acceptsDocumentation,
      'availability': ?availability,
      'contactHint': ?contactHint,
      'events': [for (final event in events) event.toJson()],
    };
  }
}

final _country = RegExp(r'^[A-Z]{2}$');
final _language = RegExp(r'^[A-Za-z]{2,3}(-[A-Za-z0-9]{1,8})*$');
final _documentation = RegExp(r'^[a-z][a-zA-Z0-9]{0,63}$');

const _maxLanguageLength = 35;

void _require(bool holds, String reason) {
  if (!holds) throw MeetingPlaceVtcSDKException.invalidDocument(reason);
}

void _checkText(String? text, String at, int maxLength) {
  if (text == null) return;
  _require(text.trim().isNotEmpty, '$at: empty');
  _require(text.runes.length <= maxLength, '$at: longer than $maxLength');
}

void _checkList(List<Object> items, String at, int maxItems) {
  _require(items.length <= maxItems, '$at: more than $maxItems');
  _require(items.toSet().length == items.length, '$at: repeated');
}

DateTime _day(DateTime date) => DateTime.utc(date.year, date.month, date.day);

String _calendarDate(DateTime date) =>
    '${date.year.toString().padLeft(4, '0')}-'
    '${date.month.toString().padLeft(2, '0')}-'
    '${date.day.toString().padLeft(2, '0')}';

/// What the community answered to a published [VetterProfile].
class PublishedVetterProfile {
  /// Creates a [PublishedVetterProfile].
  const PublishedVetterProfile({required this.listed, required this.updatedAt});

  /// Whether the stored profile is in the community's listing.
  final bool listed;

  /// When the community stored it.
  final DateTime updatedAt;
}
