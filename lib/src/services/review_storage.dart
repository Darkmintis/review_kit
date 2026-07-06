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
  int getLaunchCount();
  Future<void> setLaunchCount(int count);

  int getSessionCount();
  Future<void> setSessionCount(int count);

  int getUsageDuration();
  Future<void> setUsageDuration(int seconds);

  DateTime? getInstallDate();
  Future<void> setInstallDate(DateTime date);

  DateTime? getFirstLaunchDate();
  Future<void> setFirstLaunchDate(DateTime date);

  DateTime? getLastReviewRequestDate();
  Future<void> setLastReviewRequestDate(DateTime date);

  DateTime? getLastStoreRedirectDate();
  Future<void> setLastStoreRedirectDate(DateTime date);

  String? getLastAppVersion();
  Future<void> setLastAppVersion(String version);

  DateTime? getLastAppUpdateDate();
  Future<void> setLastAppUpdateDate(DateTime date);

  bool getRequestedThisSession();
  Future<void> setRequestedThisSession(bool value);

  Map<String, int> getEvents();
  Future<void> setEvents(Map<String, int> events);
  Future<void> incrementEvent(String eventName);
  Future<void> resetEvents();

  Future<void> resetAll();
}
