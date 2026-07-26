import 'review_storage.dart';

/// Ephemeral in-memory implementation of [ReviewStorage].
///
/// All data is lost when the app process terminates. Useful for:
/// - Testing and development
/// - Apps that implement their own persistence layer
/// - Reducing package dependency footprint
///
/// For production use with persistent storage, use [SharedPreferencesStorage].
class InMemoryStorage implements ReviewStorage {
  int _launchCount = 0;
  int _sessionCount = 0;
  int _usageDuration = 0;
  DateTime? _installDate;
  DateTime? _firstLaunchDate;
  DateTime? _lastReviewRequestDate;
  DateTime? _lastStoreRedirectDate;
  String? _lastAppVersion;
  DateTime? _lastAppUpdateDate;
  bool _requestedThisSession = false;
  Map<String, int> _events = {};

  @override
  int getLaunchCount() => _launchCount;

  @override
  Future<void> setLaunchCount(int count) async {
    _launchCount = count;
  }

  @override
  int getSessionCount() => _sessionCount;

  @override
  Future<void> setSessionCount(int count) async {
    _sessionCount = count;
  }

  @override
  int getUsageDuration() => _usageDuration;

  @override
  Future<void> setUsageDuration(int seconds) async {
    _usageDuration = seconds;
  }

  @override
  DateTime? getInstallDate() => _installDate;

  @override
  Future<void> setInstallDate(DateTime date) async {
    _installDate = date;
  }

  @override
  DateTime? getFirstLaunchDate() => _firstLaunchDate;

  @override
  Future<void> setFirstLaunchDate(DateTime date) async {
    _firstLaunchDate = date;
  }

  @override
  DateTime? getLastReviewRequestDate() => _lastReviewRequestDate;

  @override
  Future<void> setLastReviewRequestDate(DateTime date) async {
    _lastReviewRequestDate = date;
  }

  @override
  Future<void> clearLastReviewRequestDate() async {
    _lastReviewRequestDate = null;
  }

  @override
  DateTime? getLastStoreRedirectDate() => _lastStoreRedirectDate;

  @override
  Future<void> setLastStoreRedirectDate(DateTime date) async {
    _lastStoreRedirectDate = date;
  }

  @override
  Future<void> clearLastStoreRedirectDate() async {
    _lastStoreRedirectDate = null;
  }

  @override
  String? getLastAppVersion() => _lastAppVersion;

  @override
  Future<void> setLastAppVersion(String version) async {
    _lastAppVersion = version;
  }

  @override
  DateTime? getLastAppUpdateDate() => _lastAppUpdateDate;

  @override
  Future<void> setLastAppUpdateDate(DateTime date) async {
    _lastAppUpdateDate = date;
  }

  @override
  bool getRequestedThisSession() => _requestedThisSession;

  @override
  Future<void> setRequestedThisSession(bool value) async {
    _requestedThisSession = value;
  }

  @override
  Map<String, int> getEvents() => Map.from(_events);

  @override
  Future<void> setEvents(Map<String, int> events) async {
    _events = Map.from(events);
  }

  @override
  Future<void> incrementEvent(String eventName) async {
    _events[eventName] = (_events[eventName] ?? 0) + 1;
  }

  @override
  Future<void> resetEvents() async {
    _events = {};
  }

  @override
  Future<void> resetAll() async {
    _launchCount = 0;
    _sessionCount = 0;
    _usageDuration = 0;
    _installDate = null;
    _firstLaunchDate = null;
    _lastReviewRequestDate = null;
    _lastStoreRedirectDate = null;
    _lastAppVersion = null;
    _lastAppUpdateDate = null;
    _requestedThisSession = false;
    _events = {};
  }
}
