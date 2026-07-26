/// Abstract storage interface for ReviewKit.
///
/// Implement this to provide a custom persistence backend. Built-in
/// implementations:
///
/// - [SharedPreferencesStorage] — persistent, production-ready (default)
/// - [InMemoryStorage] — ephemeral, useful for testing
///
/// ```dart
/// class MyCustomStorage implements ReviewStorage {
///   // ... implement all methods
/// }
/// ```
abstract class ReviewStorage {
  /// Current app launch count.
  int getLaunchCount();

  /// Persist the app launch count.
  Future<void> setLaunchCount(int count);

  /// Current session count.
  int getSessionCount();

  /// Persist the session count.
  Future<void> setSessionCount(int count);

  /// Total tracked usage duration in seconds.
  int getUsageDuration();

  /// Persist total usage duration in seconds.
  Future<void> setUsageDuration(int seconds);

  /// First install date, if recorded.
  DateTime? getInstallDate();

  /// Persist the install date.
  Future<void> setInstallDate(DateTime date);

  /// First launch date, if recorded.
  DateTime? getFirstLaunchDate();

  /// Persist the first launch date.
  Future<void> setFirstLaunchDate(DateTime date);

  /// Last successful review API invocation date, if any.
  DateTime? getLastReviewRequestDate();

  /// Persist the last review request date.
  Future<void> setLastReviewRequestDate(DateTime date);

  /// Clears the last review request date (used by cooldown resets).
  Future<void> clearLastReviewRequestDate();

  /// Last store listing redirect date, if any.
  DateTime? getLastStoreRedirectDate();

  /// Persist the last store redirect date.
  Future<void> setLastStoreRedirectDate(DateTime date);

  /// Clears the last store redirect date (used by cooldown resets).
  Future<void> clearLastStoreRedirectDate();

  /// Last known app version string.
  String? getLastAppVersion();

  /// Persist the last known app version.
  Future<void> setLastAppVersion(String version);

  /// Date when an app update was last detected.
  DateTime? getLastAppUpdateDate();

  /// Persist the last app update date.
  Future<void> setLastAppUpdateDate(DateTime date);

  /// Whether a review was already requested in the current process session.
  ///
  /// Implementations should keep this **in-memory only** so it resets on
  /// every cold start.
  bool getRequestedThisSession();

  /// Update the in-memory session request flag.
  Future<void> setRequestedThisSession(bool value);

  /// Snapshot of custom event counters.
  Map<String, int> getEvents();

  /// Replace all custom event counters.
  Future<void> setEvents(Map<String, int> events);

  /// Increment a named custom event by one.
  Future<void> incrementEvent(String eventName);

  /// Clear all custom event counters.
  Future<void> resetEvents();

  /// Clear all persisted review state.
  Future<void> resetAll();
}
