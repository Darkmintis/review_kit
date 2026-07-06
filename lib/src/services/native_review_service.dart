import 'package:in_app_review/in_app_review.dart';
import 'platform_service.dart';

/// Wraps the [InAppReview] native plugin with platform-aware error handling.
///
/// Provides safe access to the native review API with graceful fallbacks
/// on unsupported platforms or when the API is unavailable.
class NativeReviewService {
  final InAppReview _inAppReview = InAppReview.instance;
  final PlatformService _platformService = PlatformService();

  /// Checks whether the native review dialog is available on this device.
  ///
  /// Returns `false` on unsupported platforms or when the API throws.
  Future<bool> isAvailable() async {
    if (!_platformService.isSupported) return false;
    try {
      return await _inAppReview.isAvailable();
    } catch (_) {
      return false;
    }
  }

  /// Attempts to show the native in-app review dialog.
  ///
  /// Returns `true` if the review was successfully requested.
  /// Returns `false` if the API is unavailable or throws.
  Future<bool> requestReview() async {
    try {
      if (await isAvailable()) {
        await _inAppReview.requestReview();
        return true;
      }
      return false;
    } catch (_) {
      return false;
    }
  }

  /// Opens the platform's store listing page for the app.
  ///
  /// [iosAppId] is required for iOS to open the correct App Store page.
  /// On Android, the Play Store listing is opened automatically.
  Future<void> openStoreListing({
    String androidAppId = '',
    String iosAppId = '',
  }) async {
    try {
      await _inAppReview.openStoreListing(
        appStoreId: iosAppId,
        microsoftStoreId: null,
      );
    } catch (_) {}
  }
}
