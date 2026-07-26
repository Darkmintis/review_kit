import 'package:flutter/foundation.dart';

/// Supported platforms for in-app reviews.
enum ReviewPlatform {
  /// Google Play Store (Android 5.0+).
  android,

  /// Apple App Store (iOS 10.3+).
  ios,

  /// Unsupported platform (web, desktop, etc.).
  unsupported,
}

/// Detects the current platform and determines review API availability.
///
/// Uses [defaultTargetPlatform] instead of `dart:io` so the package can be
/// imported safely in multi-platform apps (including web).
class PlatformService {
  /// The detected platform for the current device.
  ReviewPlatform get platform {
    if (kIsWeb) return ReviewPlatform.unsupported;
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return ReviewPlatform.android;
      case TargetPlatform.iOS:
        return ReviewPlatform.ios;
      default:
        return ReviewPlatform.unsupported;
    }
  }

  /// Whether the current platform supports in-app reviews.
  bool get isSupported => platform != ReviewPlatform.unsupported;
}
