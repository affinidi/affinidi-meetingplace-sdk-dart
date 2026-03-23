import 'package:meeting_place_chat/meeting_place_chat.dart';
import 'package:test/test.dart';

void main() {
  tearDown(() {
    ChatSDK.enableAutomaticDownload();
  });

  test('automatic download is enabled by default', () {
    expect(ChatSDK.isAutomaticDownloadEnabled(), isTrue);
  });

  test('disableAutomaticDownload turns automatic download off', () {
    ChatSDK.disableAutomaticDownload();

    expect(ChatSDK.isAutomaticDownloadEnabled(), isFalse);
  });

  test('enableAutomaticDownload turns automatic download back on', () {
    ChatSDK.disableAutomaticDownload();

    ChatSDK.enableAutomaticDownload();

    expect(ChatSDK.isAutomaticDownloadEnabled(), isTrue);
  });
}
