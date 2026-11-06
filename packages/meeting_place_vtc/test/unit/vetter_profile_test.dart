import 'package:meeting_place_vtc/meeting_place_vtc.dart';
import 'package:test/test.dart';

const _inPerson = [VettingMethod.inPerson];

VetterEvent _event({
  DateTime? start,
  DateTime? end,
  Uri? url,
  VetterLocation? location,
}) => VetterEvent(
  name: 'Kernel Maintainers Meetup 2026',
  startDate: start ?? DateTime.utc(2026, 10, 5),
  endDate: end ?? DateTime.utc(2026, 10, 7),
  url: url,
  location: location,
);

Matcher _refused(String member) => throwsA(
  isA<MeetingPlaceVtcSDKException>()
      .having(
        (e) => e.code,
        'code',
        MeetingPlaceVtcSDKErrorCode.invalidDocument,
      )
      .having((e) => e.message, 'message', contains(member)),
);

void main() {
  group('VetterProfile.toJson', () {
    test('carries a whole profile as the community reads it', () {
      final profile = VetterProfile(
        listed: true,
        displayName: 'Carol M.',
        languages: const ['en', 'de-AT'],
        location: const VetterLocation(country: 'AT', city: 'Vienna'),
        methods: const [VettingMethod.inPerson, VettingMethod.video],
        acceptsDocumentation: const ['passport', 'nationalId', 'none'],
        availability: 'Weekday evenings, CET.',
        contactHint: 'Ask for a ticket at the meetup.',
        events: [
          _event(
            url: Uri.parse('https://meetup.example/2026'),
            location: const VetterLocation(country: 'AT', region: 'Wien'),
          ),
        ],
      );

      expect(profile.toJson(), {
        'listed': true,
        'displayName': 'Carol M.',
        'languages': ['en', 'de-AT'],
        'location': {'country': 'AT', 'city': 'Vienna'},
        'methods': ['inPerson', 'video'],
        'acceptsDocumentation': ['passport', 'nationalId', 'none'],
        'availability': 'Weekday evenings, CET.',
        'contactHint': 'Ask for a ticket at the meetup.',
        'events': [
          {
            'name': 'Kernel Maintainers Meetup 2026',
            'startDate': '2026-10-05',
            'endDate': '2026-10-07',
            'location': {'country': 'AT', 'region': 'Wien'},
            'url': 'https://meetup.example/2026',
          },
        ],
      });
    });

    test('reads back what it wrote', () {
      final profile = VetterProfile(
        listed: true,
        displayName: 'Carol M.',
        languages: const ['en'],
        location: const VetterLocation(country: 'AT', city: 'Vienna'),
        methods: const [VettingMethod.video],
        acceptsDocumentation: const ['passport'],
        contactHint: 'Ask at the meetup.',
        events: [_event(url: Uri.parse('https://meetup.example/2026'))],
      );

      expect(
        VetterProfile.fromJson(profile.toJson()).toJson(),
        profile.toJson(),
      );
    });

    test('starts unlisted, with the required lists empty', () {
      expect(const VetterProfile(methods: _inPerson).toJson(), {
        'listed': false,
        'languages': <String>[],
        'methods': ['inPerson'],
        'acceptsDocumentation': <String>[],
        'events': <Map<String, dynamic>>[],
      });
    });
  });

  group('VetterProfile.check', () {
    test('refuses a profile offering no method, or one twice', () {
      expect(const VetterProfile(methods: []).check, _refused('methods'));
      expect(
        const VetterProfile(
          methods: [VettingMethod.video, VettingMethod.video],
        ).check,
        _refused('methods'),
      );
    });

    test('refuses blank or overlong text', () {
      expect(
        const VetterProfile(methods: _inPerson, displayName: '  ').check,
        _refused('displayName'),
      );
      expect(
        VetterProfile(methods: _inPerson, contactHint: 'x' * 301).check,
        _refused('contactHint'),
      );
      expect(
        VetterProfile(methods: _inPerson, availability: 'x' * 500).check,
        returnsNormally,
      );
    });

    test('refuses what is not a language tag or a documentation class', () {
      expect(
        const VetterProfile(methods: _inPerson, languages: ['english']).check,
        _refused('languages'),
      );
      expect(
        const VetterProfile(
          methods: _inPerson,
          acceptsDocumentation: ['Passport'],
        ).check,
        _refused('acceptsDocumentation'),
      );
    });

    test('refuses a country that is not an upper-case ISO code', () {
      expect(
        const VetterProfile(
          methods: _inPerson,
          location: VetterLocation(country: 'at'),
        ).check,
        _refused('location.country'),
      );
    });

    test('refuses an event ending before it starts or after 31 days', () {
      VetterProfile withEvent(VetterEvent event) =>
          VetterProfile(methods: _inPerson, events: [event]);

      expect(
        withEvent(_event(end: DateTime.utc(2026, 10, 4))).check,
        _refused('events[0].endDate'),
      );
      expect(
        withEvent(_event(end: DateTime.utc(2026, 11, 6))).check,
        _refused('events[0].endDate'),
      );
      expect(
        withEvent(_event(end: DateTime.utc(2026, 11, 5))).check,
        returnsNormally,
      );
    });

    test('refuses an event page that is not https', () {
      expect(
        VetterProfile(
          methods: _inPerson,
          events: [_event(url: Uri.parse('http://meetup.example'))],
        ).check,
        _refused('events[0].url'),
      );
    });

    test('refuses more than 32 events', () {
      expect(
        VetterProfile(
          methods: _inPerson,
          events: List.generate(33, (_) => _event()),
        ).check,
        _refused('events'),
      );
    });
  });
}
