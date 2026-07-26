/// Lifecycle callback events emitted by [ReviewViewModel].
///
/// Register handlers via [ReviewViewModel.on]:
///
/// ```dart
/// ReviewViewModel.instance.on(
///   callback: ReviewKitCallback.reviewRequested,
///   handler: (_) => print('Review requested'),
/// );
/// ```
enum ReviewKitCallback {
  /// The native review API was invoked successfully.
  ///
  /// Note: the OS may still suppress the dialog due to quota limits.
  reviewRequested,

  /// The native review API is not available on this device.
  reviewUnavailable,

  /// The review request was skipped (ineligible or unavailable).
  reviewSkipped,

  /// The user is eligible for a review request.
  eligible,

  /// The user is not eligible for a review request.
  /// The handler receives a [ReviewReason] with details.
  ineligible,

  /// The user was redirected to the store listing.
  storeOpened,
}
