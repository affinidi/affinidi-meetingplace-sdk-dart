import 'package:meeting_place_core/meeting_place_core.dart';
import 'package:meeting_place_core/src/transport/nop_transport.dart';
import 'package:mocktail/mocktail.dart';
import 'package:test/test.dart';

class _MockDidManager extends Mock implements DidManager {}

void main() {
  late NopTransport transport;
  late DidManager didManager;
  late Channel channel;

  setUp(() {
    transport = NopTransport();
    didManager = _MockDidManager();
    channel = Channel(
      offerLink: 'offer-link',
      publishOfferDid: 'did:test:publisher',
      mediatorDid: 'did:test:mediator',
      status: ChannelStatus.inaugurated,
      contactCard: ContactCard(
        did: 'did:test:contact',
        type: 'group',
        contactInfo: const {},
      ),
      type: ChannelType.group,
      transport: ChannelTransport.matrix,
      isConnectionInitiator: true,
      matrixRoomId: '!room:test',
    );
  });

  group('NopTransport channel lifecycle', () {
    test('setupChannel is a no-op that returns an empty room id', () async {
      final roomId = await transport.setupChannel(
        channel: channel,
        didManager: didManager,
      );

      expect(roomId, isEmpty);
    });

    test('joinRoomById preserves the requested room id', () async {
      final roomId = await transport.joinRoomById(
        didManager: didManager,
        roomId: '!joined:test',
      );

      expect(roomId, equals('!joined:test'));
    });

    test('joinChannel returns the channel room id when present', () async {
      final roomId = await transport.joinChannel(
        channel: channel,
        didManager: didManager,
      );

      expect(roomId, equals('!room:test'));
    });

    test('joinChannel falls back to an empty room id when absent', () async {
      channel.matrixRoomId = null;

      final roomId = await transport.joinChannel(
        channel: channel,
        didManager: didManager,
      );

      expect(roomId, isEmpty);
    });
  });
}
