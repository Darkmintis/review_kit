import 'package:flutter/widgets.dart';

import '../models/review_config.dart';
import '../models/review_eligibility.dart';
import '../models/review_kit_callback.dart';
import '../models/review_reason.dart';
import '../models/review_statistics.dart';
import '../rules/default_rules.dart';
import '../rules/review_rule.dart';
import '../rules/rule_engine.dart';
import '../services/callback_dispatcher.dart';
import '../services/native_review_service.dart';
import '../services/platform_service.dart';
import '../services/review_storage.dart';
import '../services/shared_preferences_storage.dart';
import '../services/usage_tracker.dart';
/// The central orchestrator for ReviewKit.
///
/// Singleton [ChangeNotifier] that wires config, [RuleEngine], storage, and
/// the native review API. Usage timing is delegated to [UsageTracker];
/// callbacks to [CallbackDispatcher].
///
/// ## Quick start
///
/// ```dart
/// await ReviewViewModel.instance.init(
///   config: ReviewConfig.builder()
///       .launches(min: 5)
///       .daysSinceInstall(7)
///       .cooldown(daysAfterReview: 60, onePerSession: true)
///       .autoTrack(launches: true, sessions: true, usageTime: true)
///       .build(),
///   appVersion: '1.2.3',
/// );
///
/// await ReviewViewModel.instance.maybeRequestReview();
/// ```
class ReviewViewModel extends ChangeNotifier with WidgetsBindingObserver {
  static final ReviewViewModel _instance = ReviewViewModel._internal();

  /// The singleton instance of ReviewViewModel.
  static ReviewViewModel get instance => _instance;

  late ReviewStorage _storage;
  final PlatformService _platformService = PlatformService();
  final NativeReviewService _nativeService = NativeReviewService();
  final CallbackDispatcher _callbacks = CallbackDispatcher();

  late RuleEngine _ruleEngine;
  UsageTracker? _usageTracker;

  ReviewConfig _config = ReviewConfig.builder().build();
  bool _initialized = false;
  ReviewEligibility? _lastEligibility;
  ReviewReason? _lastReason;
  bool _isRequesting = false;

  /// The current [ReviewConfig].
  ReviewConfig get config => _config;

  /// Whether [init] has been called successfully.
  bool get initialized => _initialized;

  /// Whether a review request is currently in progress.
  bool get isRequesting => _isRequesting;

  /// The result of the last eligibility check, if any.
  ReviewEligibility? get lastEligibility => _lastEligibility;

  /// The detailed reason from the last eligibility check, if any.
  ReviewReason? get lastReason => _lastReason;

  /// Whether the current platform supports in-app reviews.
  bool get isSupported => _platformService.isSupported;

  ReviewViewModel._internal();

  /// Initialize the ReviewKit engine.
  ///
  /// Must be called once before using any other methods. Subsequent calls are
  /// ignored unless [force] is `true` (useful in tests).
  ///
  /// When [rules] is omitted or empty, [defaultReviewRules] is used.
  Future<void> init({
    required ReviewConfig config,
    List<ReviewRule>? rules,
    ReviewStorage? storage,
    String? appVersion,
    bool force = false,
  }) async {
    if (_initialized && !force) return;

    if (_initialized && force) {
      await _tearDown();
    }

    if (storage != null) {
      _storage = storage;
    } else {
      final prefsStorage = SharedPreferencesStorage();
      await prefsStorage.init();
      _storage = prefsStorage;
    }

    // Session flag must never survive process restarts.
    await _storage.setRequestedThisSession(false);

    _config = config;
    final effectiveRules =
        (rules == null || rules.isEmpty) ? defaultReviewRules() : rules;
    _ruleEngine = RuleEngine(_storage, effectiveRules);
    _usageTracker = UsageTracker(_storage);

    WidgetsBinding.instance.addObserver(this);
    _initialized = true;

    if (appVersion != null) {
      await _checkAppUpdate(appVersion);
    }

    if (_config.autoTrackLaunches == true) {
      await _trackLaunch();
    }

    if (_config.autoTrackUsageTime == true) {
      _usageTracker!.startForegroundTracking();
    }
  }

  /// Register a callback handler for a [ReviewKitCallback] event.
  void on({
    required ReviewKitCallback callback,
    required void Function(dynamic) handler,
  }) {
    _callbacks.on(callback, handler);
  }

  /// Remove a previously registered callback handler.
  ///
  /// If [handler] is null, all handlers for this callback are removed.
  void off({
    required ReviewKitCallback callback,
    void Function(dynamic)? handler,
  }) {
    _callbacks.off(callback, handler);
  }

  void _debugLog(String message) {
    if (_config.debugMode == true) {
      debugPrint('[ReviewKit] $message');
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (_config.autoTrackUsageTime != true) return;
    final tracker = _usageTracker;
    if (tracker == null) return;

    if (state == AppLifecycleState.resumed) {
      tracker.onResumed();
    } else if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive ||
        state == AppLifecycleState.hidden ||
        state == AppLifecycleState.detached) {
      tracker.onBackgrounded();
    }
  }

  Future<void> _checkAppUpdate(String currentVersion) async {
    final lastVersion = _storage.getLastAppVersion();
    if (lastVersion != null && lastVersion != currentVersion) {
      await _storage.setLastAppUpdateDate(DateTime.now());
    }
    await _storage.setLastAppVersion(currentVersion);
  }

  Future<void> _trackLaunch() async {
    final launches = _storage.getLaunchCount();
    await _storage.setLaunchCount(launches + 1);

    if (_storage.getFirstLaunchDate() == null) {
      await _storage.setFirstLaunchDate(DateTime.now());
    }
    if (_storage.getInstallDate() == null) {
      await _storage.setInstallDate(DateTime.now());
    }

    notifyListeners();
  }

  /// Start a new usage session.
  Future<void> startSession() async {
    if (!_initialized || _usageTracker == null) return;

    final started = await _usageTracker!.startSession(
      trackSessionCount: _config.autoTrackSessions == true,
      trackUsageTime: _config.autoTrackUsageTime == true,
    );
    if (started && _config.autoTrackSessions == true) {
      notifyListeners();
    }
  }

  /// End the current usage session and flush usage time when enabled.
  Future<void> endSession() async {
    if (_usageTracker == null) return;
    final before = _storage.getUsageDuration();
    await _usageTracker!.endSession(
      trackUsageTime: _config.autoTrackUsageTime == true,
    );
    if (_storage.getUsageDuration() != before) {
      notifyListeners();
    }
  }

  /// Record a custom event (for [EventRule] thresholds).
  Future<void> trackEvent(String eventName) async {
    if (!_initialized) return;
    await _storage.incrementEvent(eventName);
    notifyListeners();
  }

  /// Get all tracked custom events and their counts.
  Map<String, int> getEvents() {
    if (!_initialized) return const {};
    return _storage.getEvents();
  }

  /// Reset a specific event counter to zero.
  Future<void> resetEvent(String eventName) async {
    if (!_initialized) return;
    final events = _storage.getEvents();
    events.remove(eventName);
    await _storage.setEvents(events);
    notifyListeners();
  }

  /// Manually increment the launch counter.
  Future<void> incrementLaunchCount() async {
    if (!_initialized) return;
    final launches = _storage.getLaunchCount();
    await _storage.setLaunchCount(launches + 1);
    notifyListeners();
  }

  /// Manually increment the session counter.
  Future<void> incrementSessionCount() async {
    if (!_initialized) return;
    final sessions = _storage.getSessionCount();
    await _storage.setSessionCount(sessions + 1);
    notifyListeners();
  }

  /// Run all eligibility rules against the current config and data.
  ReviewEligibility checkEligibility() {
    _ensureInitialized();
    _lastEligibility = _ruleEngine.checkEligibility(_config);
    notifyListeners();
    return _lastEligibility!;
  }

  /// Get a detailed [ReviewReason] explaining the current eligibility state.
  ReviewReason getEligibilityReason() {
    _ensureInitialized();
    _lastReason = _ruleEngine.getEligibilityReason(_config);
    notifyListeners();
    return _lastReason!;
  }

  /// Attempt to request an in-app review, subject to all eligibility rules.
  ///
  /// Returns `true` if the native review API was invoked successfully.
  /// A `true` result means the OS API was called — stores may still suppress
  /// the dialog due to quotas.
  Future<bool> maybeRequestReview() async {
    if (!_initialized || _isRequesting) return false;

    final eligibility = checkEligibility();

    if (!eligibility.eligible) {
      _lastReason = _ruleEngine.getEligibilityReason(_config);
      _debugLog('Ineligible:\n$_lastReason');
      _callbacks.emit(ReviewKitCallback.ineligible, _lastReason);
      _callbacks.emit(ReviewKitCallback.reviewSkipped, _lastReason);
      return false;
    }

    _callbacks.emit(ReviewKitCallback.eligible, eligibility);

    final available = await _nativeService.isAvailable();
    if (!available) {
      _debugLog('Native review API unavailable');
      _callbacks.emit(ReviewKitCallback.reviewUnavailable);
      _callbacks.emit(ReviewKitCallback.reviewSkipped);
      return false;
    }

    _isRequesting = true;
    notifyListeners();

    try {
      final success = await _nativeService.requestReview();
      if (success) {
        await _storage.setLastReviewRequestDate(DateTime.now());
        await _storage.setRequestedThisSession(true);
        _debugLog('Review API invoked');
        _callbacks.emit(ReviewKitCallback.reviewRequested);
        return true;
      }

      _debugLog('Review API request failed');
      _callbacks.emit(ReviewKitCallback.reviewUnavailable);
      _callbacks.emit(ReviewKitCallback.reviewSkipped);
      return false;
    } finally {
      _isRequesting = false;
      notifyListeners();
    }
  }

  /// Open the platform's store listing page.
  ///
  /// [appStoreId] is required on iOS. On Android the package name is used.
  Future<void> openStoreListing({String appStoreId = ''}) async {
    if (!_initialized) return;
    await _nativeService.openStoreListing(appStoreId: appStoreId);
    await _storage.setLastStoreRedirectDate(DateTime.now());
    _callbacks.emit(ReviewKitCallback.storeOpened);
  }

  /// Get a complete snapshot of all tracked statistics.
  ReviewStatistics getStatistics() {
    _ensureInitialized();
    final eligibility = checkEligibility();

    return ReviewStatistics(
      launchCount: _storage.getLaunchCount(),
      sessionCount: _storage.getSessionCount(),
      usageDurationSeconds: _storage.getUsageDuration(),
      eventTotals: Map.from(_storage.getEvents()),
      installDate: _storage.getInstallDate(),
      firstLaunchDate: _storage.getFirstLaunchDate(),
      lastReviewRequestDate: _storage.getLastReviewRequestDate(),
      lastStoreRedirectDate: _storage.getLastStoreRedirectDate(),
      lastAppUpdateDate: _storage.getLastAppUpdateDate(),
      cooldownActive: _isCooldownActive(),
      cooldownRemainingDays: _getCooldownRemaining(),
      isEligible: eligibility.eligible,
    );
  }

  bool _isCooldownActive() {
    final now = DateTime.now();

    if (_config.cooldownDaysAfterReview != null) {
      final lastReview = _storage.getLastReviewRequestDate();
      if (lastReview != null &&
          now.difference(lastReview).inDays <
              _config.cooldownDaysAfterReview!) {
        return true;
      }
    }

    if (_config.cooldownDaysAfterStoreRedirect != null) {
      final lastRedirect = _storage.getLastStoreRedirectDate();
      if (lastRedirect != null &&
          now.difference(lastRedirect).inDays <
              _config.cooldownDaysAfterStoreRedirect!) {
        return true;
      }
    }

    if (_config.oneRequestPerSession == true &&
        _storage.getRequestedThisSession()) {
      return true;
    }

    return false;
  }

  int? _getCooldownRemaining() {
    if (_config.cooldownDaysAfterReview == null) return null;
    final lastReview = _storage.getLastReviewRequestDate();
    if (lastReview == null) return null;

    final remaining = _config.cooldownDaysAfterReview! -
        DateTime.now().difference(lastReview).inDays;
    return remaining > 0 ? remaining : null;
  }

  /// Reset all counters, events, dates, and cooldowns.
  Future<void> resetAll() async {
    if (!_initialized) return;
    _usageTracker?.flushForegroundTime();
    await _storage.resetAll();
    _lastEligibility = null;
    _lastReason = null;
    notifyListeners();
  }

  /// Reset the launch counter to zero.
  Future<void> resetLaunches() async {
    if (!_initialized) return;
    await _storage.setLaunchCount(0);
    notifyListeners();
  }

  /// Reset the session counter to zero.
  Future<void> resetSessions() async {
    if (!_initialized) return;
    await _storage.setSessionCount(0);
    notifyListeners();
  }

  /// Reset the usage time counter to zero.
  Future<void> resetUsageTime() async {
    if (!_initialized) return;
    _usageTracker?.clearElapsed();
    await _storage.setUsageDuration(0);
    notifyListeners();
  }

  /// Reset all custom event counters.
  Future<void> resetEvents() async {
    if (!_initialized) return;
    await _storage.resetEvents();
    notifyListeners();
  }

  /// Reset cooldowns so a review can be requested immediately.
  Future<void> resetCooldowns() async {
    if (!_initialized) return;
    await _storage.clearLastReviewRequestDate();
    await _storage.clearLastStoreRedirectDate();
    await _storage.setRequestedThisSession(false);
    notifyListeners();
  }

  /// Check if the native review API is available on this device.
  Future<bool> isNativeReviewAvailable() => _nativeService.isAvailable();

  /// Update the configuration and optionally the rule set at runtime.
  void updateConfig(ReviewConfig config, {List<ReviewRule>? rules}) {
    _ensureInitialized();
    final wasTracking = _config.autoTrackUsageTime == true;
    _config = config;

    if (rules != null) {
      final effectiveRules =
          rules.isEmpty ? defaultReviewRules() : rules;
      _ruleEngine = RuleEngine(_storage, effectiveRules);
    }

    if (wasTracking && config.autoTrackUsageTime != true) {
      _usageTracker?.flushForegroundTime();
    } else if (!wasTracking && config.autoTrackUsageTime == true) {
      _usageTracker?.startForegroundTracking();
    }
    notifyListeners();
  }

  void _ensureInitialized() {
    if (!_initialized) {
      throw StateError(
        'ReviewViewModel has not been initialized. '
        'Call await ReviewViewModel.instance.init(...) first.',
      );
    }
  }

  Future<void> _tearDown() async {
    WidgetsBinding.instance.removeObserver(this);
    _usageTracker?.dispose();
    _usageTracker = null;
    _isRequesting = false;
    _lastEligibility = null;
    _lastReason = null;
    _callbacks.clear();
    _initialized = false;
  }

  /// Releases lifecycle observers and timers without disposing the singleton.
  Future<void> shutdown() async {
    await _tearDown();
  }

  /// Fully resets the singleton for unit tests.
  @visibleForTesting
  Future<void> resetForTesting() async {
    if (_initialized) {
      try {
        await _storage.resetAll();
      } catch (_) {}
    }
    await _tearDown();
  }
}
