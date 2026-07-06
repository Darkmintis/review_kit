/// Immutable configuration for review eligibility rules.
///
/// Use [ReviewConfig.builder] to construct instances. Every field is nullable;
/// only conditions explicitly set via the builder are enforced by the rule engine.
///
/// ```dart
/// final config = ReviewConfig.builder()
///     .launches(min: 5, max: 10)
///     .daysSinceInstall(7)
///     .build();
/// ```
class ReviewConfig {
  /// Minimum app launches required before asking for a review.
  final int? minLaunches;

  /// Maximum app launches after which the review request is suppressed.
  final int? maxLaunches;

  /// Minimum days since the app was first installed.
  final int? minDaysSinceInstall;

  /// Minimum days since the user first launched the app.
  final int? minDaysSinceFirstLaunch;

  /// Minimum days since the last review request was made.
  final int? minDaysSinceLastReview;

  /// Minimum days since the last app update.
  final int? minDaysSinceLastUpdate;

  /// Minimum number of sessions before review is eligible.
  final int? minSessions;

  /// Minimum total usage time in seconds before review is eligible.
  final int? minTotalUsageSeconds;

  /// Cooldown period in days after a review request before another can be made.
  final int? cooldownDaysAfterReview;

  /// Cooldown period in days after a store redirect before a review can be requested.
  final int? cooldownDaysAfterStoreRedirect;

  /// Whether to allow only one review request per session.
  final bool? oneRequestPerSession;

  /// Enables debug mode for diagnostic output and [ReviewDebugScreen].
  final bool? debugMode;

  /// Automatically track app launches when [ReviewViewModel] is initialized.
  final bool? autoTrackLaunches;

  /// Automatically track sessions when [ReviewViewModel.startSession] is called.
  final bool? autoTrackSessions;

  /// Automatically track usage time during sessions.
  final bool? autoTrackUsageTime;

  /// Per-event thresholds. Maps event names to the minimum count required.
  ///
  /// Example: `{'purchase_made': 3, 'level_completed': 5}`
  final Map<String, int>? eventThresholds;

  const ReviewConfig._({
    this.minLaunches,
    this.maxLaunches,
    this.minDaysSinceInstall,
    this.minDaysSinceFirstLaunch,
    this.minDaysSinceLastReview,
    this.minDaysSinceLastUpdate,
    this.minSessions,
    this.minTotalUsageSeconds,
    this.cooldownDaysAfterReview,
    this.cooldownDaysAfterStoreRedirect,
    this.oneRequestPerSession,
    this.debugMode,
    this.autoTrackLaunches,
    this.autoTrackSessions,
    this.autoTrackUsageTime,
    this.eventThresholds,
  });

  /// Creates a new [ReviewConfigBuilder] for fluent configuration.
  static ReviewConfigBuilder builder() => ReviewConfigBuilder();
}

/// Fluent builder for [ReviewConfig].
///
/// Every method is optional. Only properties explicitly set will be enforced
/// by the rule engine. Call [build] to produce the immutable [ReviewConfig].
///
/// ```dart
/// final config = ReviewConfig.builder()
///     .launches(min: 3)
///     .daysSinceInstall(7)
///     .cooldown(daysAfterReview: 60)
///     .build();
/// ```
class ReviewConfigBuilder {
  int? _minLaunches;
  int? _maxLaunches;
  int? _minDaysSinceInstall;
  int? _minDaysSinceFirstLaunch;
  int? _minDaysSinceLastReview;
  int? _minDaysSinceLastUpdate;
  int? _minSessions;
  int? _minTotalUsageSeconds;
  int? _cooldownDaysAfterReview;
  int? _cooldownDaysAfterStoreRedirect;
  bool? _oneRequestPerSession;
  bool? _debugMode;
  bool? _autoTrackLaunches;
  bool? _autoTrackSessions;
  bool? _autoTrackUsageTime;
  Map<String, int>? _eventThresholds;

  /// Set minimum (and optional maximum) app launches before review is eligible.
  ///
  /// [min] — minimum launches required. [max] — optional upper bound.
  ReviewConfigBuilder launches({int? min, int? max}) {
    _minLaunches = min;
    _maxLaunches = max;
    return this;
  }

  /// Minimum days since the app was first installed.
  ReviewConfigBuilder daysSinceInstall(int days) {
    _minDaysSinceInstall = days;
    return this;
  }

  /// Minimum days since the user first launched the app.
  ReviewConfigBuilder daysSinceFirstLaunch(int days) {
    _minDaysSinceFirstLaunch = days;
    return this;
  }

  /// Minimum days since the last review request.
  ReviewConfigBuilder daysSinceLastReview(int days) {
    _minDaysSinceLastReview = days;
    return this;
  }

  /// Minimum days since the last app update.
  ReviewConfigBuilder daysSinceLastUpdate(int days) {
    _minDaysSinceLastUpdate = days;
    return this;
  }

  /// Minimum number of sessions before review is eligible.
  ReviewConfigBuilder sessions(int min) {
    _minSessions = min;
    return this;
  }

  /// Minimum total usage time in seconds before review is eligible.
  ReviewConfigBuilder usageTime(int minSeconds) {
    _minTotalUsageSeconds = minSeconds;
    return this;
  }

  /// Configure cooldown periods.
  ///
  /// [daysAfterReview] — wait this many days after a review request.
  /// [daysAfterStoreRedirect] — wait this many days after a store redirect.
  /// [onePerSession] — limit to one review request per session.
  ReviewConfigBuilder cooldown({
    int? daysAfterReview,
    int? daysAfterStoreRedirect,
    bool? onePerSession,
  }) {
    _cooldownDaysAfterReview = daysAfterReview;
    _cooldownDaysAfterStoreRedirect = daysAfterStoreRedirect;
    _oneRequestPerSession = onePerSession;
    return this;
  }

  /// Add a single event threshold.
  ///
  /// [name] — the event name (e.g. `'purchase_made'`).
  /// [threshold] — the minimum count required.
  ReviewConfigBuilder event(String name, {required int threshold}) {
    _eventThresholds ??= {};
    _eventThresholds![name] = threshold;
    return this;
  }

  /// Set multiple event thresholds at once.
  ///
  /// Merges with any previously set thresholds.
  ReviewConfigBuilder eventThresholds(Map<String, int> thresholds) {
    _eventThresholds = {...?_eventThresholds, ...thresholds};
    return this;
  }

  /// Opt in to automatic tracking.
  ///
  /// [launches] — auto-increment launch count on init.
  /// [sessions] — auto-increment session count on [ReviewViewModel.startSession].
  /// [usageTime] — auto-track elapsed seconds during sessions.
  ReviewConfigBuilder autoTrack({
    bool? launches,
    bool? sessions,
    bool? usageTime,
  }) {
    _autoTrackLaunches = launches;
    _autoTrackSessions = sessions;
    _autoTrackUsageTime = usageTime;
    return this;
  }

  /// Enable debug mode for detailed diagnostics.
  ReviewConfigBuilder debug(bool enabled) {
    _debugMode = enabled;
    return this;
  }

  /// Builds the immutable [ReviewConfig] from the configured values.
  ReviewConfig build() => ReviewConfig._(
        minLaunches: _minLaunches,
        maxLaunches: _maxLaunches,
        minDaysSinceInstall: _minDaysSinceInstall,
        minDaysSinceFirstLaunch: _minDaysSinceFirstLaunch,
        minDaysSinceLastReview: _minDaysSinceLastReview,
        minDaysSinceLastUpdate: _minDaysSinceLastUpdate,
        minSessions: _minSessions,
        minTotalUsageSeconds: _minTotalUsageSeconds,
        cooldownDaysAfterReview: _cooldownDaysAfterReview,
        cooldownDaysAfterStoreRedirect: _cooldownDaysAfterStoreRedirect,
        oneRequestPerSession: _oneRequestPerSession,
        debugMode: _debugMode,
        autoTrackLaunches: _autoTrackLaunches,
        autoTrackSessions: _autoTrackSessions,
        autoTrackUsageTime: _autoTrackUsageTime,
        eventThresholds: _eventThresholds,
      );
}
