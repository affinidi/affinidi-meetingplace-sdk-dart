class CallDeclineSignal {
  /// Emitted on `MeetingPlaceCoreSDK.callDeclineSignals` when a
  /// `ChannelActivity(type: 'call-decline')` event is received from the
  /// control plane.
  ///
  /// The plugin layer subscribes to this stream and emits
  /// `AudioVideoCallStatus.declined` on the active outgoing session.
  const CallDeclineSignal({required this.ownChannelDid});

  /// The caller's own permanent channel DID, matching
  /// `Channel.permanentChannelDid` on the receiving device.
  final String ownChannelDid;
}
