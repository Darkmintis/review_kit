import 'dart:io';

/// Supported platforms for in-app reviews.
enum ReviewPlatform {
  /// Google Play Store (Android 5.0+).
  android,

  /// Apple App Store (iOS 10.3+).
  ios,

  /// Unsupported platform.
  unsupported,
}

/// Detects the current platform and determines review API availability.
class PlatformService {
  /// The detected platform for the current device.
  ReviewPlatform get platform {
    if (Platform.isAndroid) return ReviewPlatform.android;
    if (Platform.isIOS) return ReviewPlatform.ios;
    return ReviewPlatform.unsupported;
  }

  /// Whether the current platform supports in-app reviews.
  bool get isSupported => platform != ReviewPlatform.unsupported;
}
