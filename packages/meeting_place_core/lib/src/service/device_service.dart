import 'dart:convert';

class DeviceService {
  static String getDeviceTokenForDIDCommNotifications({
    required String recipientDid,
    required String senderDid,
    required String senderPrivateKey,
    required String mediatorDid,
  }) {
    return base64Encode(
      utf8.encode(
        json.encode({
          'recipientDid': recipientDid,
          'agentDid': senderDid,
          'agentPrivateKey': senderPrivateKey,
          'mediatorDid': mediatorDid,
        }),
      ),
    );
  }
}
