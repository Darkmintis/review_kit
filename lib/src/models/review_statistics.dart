/// A snapshot of all tracked statistics at a point in time.
///
/// Returned by [ReviewViewModel.getStatistics]. Provides full visibility into
/// counters, event totals, dates, and cooldown state.
class ReviewStatistics {
  /// Total number of app launches recorded.
  final int launchCount;

  /// Total number of sessions recorded.
  final int sessionCount;

  /// Total usage duration in seconds.
  final int usageDurationSeconds;

  /// Map of custom event names to their current counts.
  final Map<String, int> eventTotals;

  /// When the app was first installed.
  final DateTime? installDate;

  /// When the app was first launched.
  final DateTime? firstLaunchDate;

  /// When the last review request was made.
  final DateTime? lastReviewRequestDate;

  /// When the last store redirect occurred.
  final DateTime? lastStoreRedirectDate;

  /// When the last app update was detected.
  final DateTime? lastAppUpdateDate;

  /// Whether a cooldown is currently active.
  final bool cooldownActive;

  /// Days remaining in the active cooldown, if any.
  final int? cooldownRemainingDays;

  /// Whether the user is currently eligible for a review request.
  final bool isEligible;

  const ReviewStatistics({
    required this.launchCount,
    required this.sessionCount,
    required this.usageDurationSeconds,
    required this.eventTotals,
    this.installDate,
    this.firstLaunchDate,
    this.lastReviewRequestDate,
    this.lastStoreRedirectDate,
    this.lastAppUpdateDate,
    required this.cooldownActive,
    this.cooldownRemainingDays,
    required this.isEligible,
  });
}
