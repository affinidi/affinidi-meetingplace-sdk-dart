import 'package:meeting_place_vtc/meeting_place_vtc.dart';
import 'package:test/test.dart';

const _community = 'did:webvh:QmCommunity:dids.example:community';
const _vetter = 'did:webvh:QmVetter:dids.example:vetter';
final _now = DateTime.utc(2026, 11, 6, 9);

VetterTicket _mint({int uses = 1}) => VetterTicket.mint(
  community: _community,
  vetter: _vetter,
  uses: uses,
  now: _now,
);

void main() {
  group('VetterTicket.mint', () {
    test('makes a random ticket, good once for 14 days', () {
      final ticket = _mint();

      expect(ticket.id, matches(RegExp(r'^vt-[0-9a-f]{32}$')));
      expect(ticket.secret, matches(RegExp(r'^[A-Za-z0-9_-]{43}$')));
      expect(
        ticket.code,
        matches(RegExp(r'^[0-9A-HJKMNP-TV-Z]{4}-[0-9A-HJKMNP-TV-Z]{4}$')),
      );
      expect(ticket.usesLeft, 1);
      expect(ticket.expiresAt, _now.add(const Duration(days: 14)));
      expect(_mint().secret, isNot(ticket.secret));
    });

    test('refuses no uses or no validity', () {
      expect(() => _mint(uses: 0), throwsArgumentError);
      expect(
        () => VetterTicket.mint(
          community: _community,
          vetter: _vetter,
          validity: Duration.zero,
        ),
        throwsArgumentError,
      );
    });

    test('shows as tickets an applicant reads back', () {
      final ticket = _mint();

      final scanned = VettingTicket.parse(ticket.scanned.toString())!;
      expect(scanned.toJson(), {
        'ticketId': ticket.id,
        'secret': ticket.secret,
      });
      expect(scanned.community, _community);
      expect(scanned.vetter, _vetter);
      expect(VettingTicket.parse(ticket.spoken.toString())!.toJson(), {
        'code': ticket.code,
      });
    });
  });

  group('VetterTicket.admits', () {
    test('admits its code as typed, and its id with its secret', () {
      final ticket = _mint();
      final typed = ticket.code.toLowerCase().replaceAll('-', ' ');

      expect(ticket.admits({'code': typed}, _now), isTrue);
      expect(ticket.admits(ticket.scanned.toJson(), _now), isTrue);
    });

    test('refuses another code, secret or id', () {
      final ticket = _mint();

      expect(ticket.admits({'code': 'ZZZZ-ZZZZ'}, _now), isFalse);
      expect(
        ticket.admits({'ticketId': ticket.id, 'secret': 'A' * 43}, _now),
        isFalse,
      );
      expect(
        ticket.admits({'ticketId': 'vt-other', 'secret': ticket.secret}, _now),
        isFalse,
      );
      expect(ticket.admits({}, _now), isFalse);
    });

    test('refuses once used up or expired', () {
      final ticket = _mint();

      expect(ticket.spent().admits({'code': ticket.code}, _now), isFalse);
      expect(ticket.admits({'code': ticket.code}, ticket.expiresAt), isFalse);
    });

    test('admits a ticket of several uses until they are spent', () {
      final ticket = _mint(uses: 2).spent();

      expect(ticket.admits({'code': ticket.code}, _now), isTrue);
      expect(ticket.spent().isLive(_now), isFalse);
    });
  });

  test('survives toJson and fromJson', () {
    final ticket = _mint(uses: 3);
    final read = VetterTicket.fromJson(ticket.toJson());

    expect(read.toJson(), ticket.toJson());
    expect(read.expiresAt, ticket.expiresAt);
  });

  test('normaliseVettingCode reads codes the way upstream does', () {
    expect(normaliseVettingCode('k7qf 2m9x'), 'K7QF-2M9X');
    expect(normaliseVettingCode('O1IL-0000'), '0111-0000');
    expect(normaliseVettingCode('K7QF-2M9'), isNull);
    expect(normaliseVettingCode('K7QF-2M9U'), isNull);
  });
}
