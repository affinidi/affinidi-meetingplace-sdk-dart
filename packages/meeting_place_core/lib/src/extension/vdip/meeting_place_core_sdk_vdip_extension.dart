import '../../../meeting_place_core.dart';

extension MeetingPlaceCoreSdkVdipExtension on MeetingPlaceCoreSDK {
  VdipExtension get vdip {
    final extension = tryExtension<VdipExtension>();
    if (extension != null) {
      return extension;
    }

    registerExtension<VdipExtension>(VdipExtension(sdk: this));
    return getExtension<VdipExtension>();
  }
}
