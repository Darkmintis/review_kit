import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'review_storage.dart';

/// Persistent [ReviewStorage] implementation backed by [SharedPreferences].
///
/// This is the default production-ready storage. All data persists across
/// app restarts and is stored locally on-device with no network access.
///
/// All keys are prefixed with `review_kit_` to avoid collisions.
class SharedPreferencesStorage implements ReviewStorage {
  static const _prefix = 'review_kit_';
  static const _launchCount = '${_prefix}launch_count';
  static const _sessionCount = '${_prefix}session_count';
  static const _usageDuration = '${_prefix}usage_duration';
  static const _installDate = '${_prefix}install_date';
  static const _firstLaunchDate = '${_prefix}first_launch_date';
  static const _lastReviewDate = '${_prefix}last_review_date';
  static const _lastStoreRedirect = '${_prefix}last_store_redirect';
  static const _lastAppVersion = '${_prefix}last_app_version';
  static const _lastAppUpdateDate = '${_prefix}last_app_update_date';
  static const _events = '${_prefix}events';
  // Legacy key — session flag must never persist across process restarts.
  static const _legacyRequestedThisSession =
      '${_prefix}requested_this_session';

  late SharedPreferences _prefs;

  /// In-memory only: one-request-per-session must reset on every app start.
  bool _requestedThisSession = false;

  /// Initialize the SharedPreferences instance. Must be called once before use.
  ///
  /// Also migrates away from the legacy persisted session flag so older
  /// installs do not stay blocked forever after a single review request.
  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
    if (_prefs.containsKey(_legacyRequestedThisSession)) {
      await _prefs.remove(_legacyRequestedThisSession);
    }
    _requestedThisSession = false;
  }

  @override
  int getLaunchCount() => _prefs.getInt(_launchCount) ?? 0;

  @override
  Future<void> setLaunchCount(int count) =>
      _prefs.setInt(_launchCount, count);

  @override
  int getSessionCount() => _prefs.getInt(_sessionCount) ?? 0;

  @override
  Future<void> setSessionCount(int count) =>
      _prefs.setInt(_sessionCount, count);

  @override
  int getUsageDuration() => _prefs.getInt(_usageDuration) ?? 0;

  @override
  Future<void> setUsageDuration(int seconds) =>
      _prefs.setInt(_usageDuration, seconds);

  @override
  DateTime? getInstallDate() {
    final millis = _prefs.getInt(_installDate);
    return millis != null ? DateTime.fromMillisecondsSinceEpoch(millis) : null;
  }

  @override
  Future<void> setInstallDate(DateTime date) =>
      _prefs.setInt(_installDate, date.millisecondsSinceEpoch);

  @override
  DateTime? getFirstLaunchDate() {
    final millis = _prefs.getInt(_firstLaunchDate);
    return millis != null ? DateTime.fromMillisecondsSinceEpoch(millis) : null;
  }

  @override
  Future<void> setFirstLaunchDate(DateTime date) =>
      _prefs.setInt(_firstLaunchDate, date.millisecondsSinceEpoch);

  @override
  DateTime? getLastReviewRequestDate() {
    final millis = _prefs.getInt(_lastReviewDate);
    return millis != null ? DateTime.fromMillisecondsSinceEpoch(millis) : null;
  }

  @override
  Future<void> setLastReviewRequestDate(DateTime date) =>
      _prefs.setInt(_lastReviewDate, date.millisecondsSinceEpoch);

  @override
  Future<void> clearLastReviewRequestDate() => _prefs.remove(_lastReviewDate);

  @override
  DateTime? getLastStoreRedirectDate() {
    final millis = _prefs.getInt(_lastStoreRedirect);
    return millis != null ? DateTime.fromMillisecondsSinceEpoch(millis) : null;
  }

  @override
  Future<void> setLastStoreRedirectDate(DateTime date) =>
      _prefs.setInt(_lastStoreRedirect, date.millisecondsSinceEpoch);

  @override
  Future<void> clearLastStoreRedirectDate() =>
      _prefs.remove(_lastStoreRedirect);

  @override
  String? getLastAppVersion() => _prefs.getString(_lastAppVersion);

  @override
  Future<void> setLastAppVersion(String version) =>
      _prefs.setString(_lastAppVersion, version);

  @override
  DateTime? getLastAppUpdateDate() {
    final millis = _prefs.getInt(_lastAppUpdateDate);
    return millis != null ? DateTime.fromMillisecondsSinceEpoch(millis) : null;
  }

  @override
  Future<void> setLastAppUpdateDate(DateTime date) =>
      _prefs.setInt(_lastAppUpdateDate, date.millisecondsSinceEpoch);

  @override
  bool getRequestedThisSession() => _requestedThisSession;

  @override
  Future<void> setRequestedThisSession(bool value) async {
    _requestedThisSession = value;
  }

  @override
  Map<String, int> getEvents() {
    final raw = _prefs.getString(_events);
    if (raw == null) return {};
    final decoded = jsonDecode(raw) as Map<String, dynamic>;
    return decoded.map((k, v) => MapEntry(k, (v as num).toInt()));
  }

  @override
  Future<void> setEvents(Map<String, int> events) =>
      _prefs.setString(_events, jsonEncode(events));

  @override
  Future<void> incrementEvent(String eventName) {
    final events = getEvents();
    events[eventName] = (events[eventName] ?? 0) + 1;
    return setEvents(events);
  }

  @override
  Future<void> resetEvents() => _prefs.remove(_events);

  @override
  Future<void> resetAll() async {
    final keys = [
      _launchCount,
      _sessionCount,
      _usageDuration,
      _installDate,
      _firstLaunchDate,
      _lastReviewDate,
      _lastStoreRedirect,
      _lastAppVersion,
      _lastAppUpdateDate,
      _events,
      _legacyRequestedThisSession,
    ];
    for (final key in keys) {
      await _prefs.remove(key);
    }
    _requestedThisSession = false;
  }
}
