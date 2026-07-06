import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/review_config.dart';
import '../models/review_eligibility.dart';
import '../models/review_statistics.dart';
import '../models/review_reason.dart';
import '../services/review_storage.dart';
import '../services/shared_preferences_storage.dart';
import '../services/platform_service.dart';
import '../services/native_review_service.dart';
import '../rules/review_rule.dart';
import '../rules/rule_engine.dart';

/// Callback events emitted by [ReviewViewModel].
///
/// Register handlers via [ReviewViewModel.on] to react to review lifecycle
/// events.
///
/// ```dart
/// ReviewViewModel.instance.on(
///   callback: ReviewKitCallback.reviewRequested,
///   handler: (_) => print('Review shown!'),
/// );
/// ```
enum ReviewKitCallback {
  /// A review request was successfully shown to the user.
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

/// The central ViewModel for the ReviewKit package.
///
/// Implements the MVVM pattern as a singleton [ChangeNotifier]. Coordinates
/// between the configuration, rule engine, storage, and native review API.
///
/// ## Usage
///
/// ```dart
/// // 1. Initialize with config, rules, and optional custom storage
/// await ReviewViewModel.instance.init(
///   config: myConfig,
///   rules: [LaunchRule(), TimeRule(), ...],
///   appVersion: '1.2.3',              // optional version tracking
///   storage: MyCustomStorage(),       // optional custom storage
/// );
///
/// // 2. Track events and sessions
/// ReviewViewModel.instance.trackEvent('purchase_made');
/// ReviewViewModel.instance.startSession();
///
/// // 3. Request a review (only if all rules pass)
/// await ReviewViewModel.instance.maybeRequestReview();
/// ```
class ReviewViewModel extends ChangeNotifier {
  static final ReviewViewModel _instance = ReviewViewModel._internal();

  /// The singleton instance of ReviewViewModel.
  static ReviewViewModel get instance => _instance;

  late final ReviewStorage _storage;
  final PlatformService _platformService = PlatformService();
  final NativeReviewService _nativeService = NativeReviewService();
  late final RuleEngine _ruleEngine;

  ReviewConfig _config = ReviewConfig.builder().build();
  bool _initialized = false;
  ReviewEligibility? _lastEligibility;
  ReviewReason? _lastReason;
  bool _isRequesting = false;
  bool _sessionActive = false;
  Timer? _sessionTimer;
  int _sessionElapsed = 0;

  final Map<ReviewKitCallback, List<void Function(dynamic)>> _callbacks = {};

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
  /// Must be called once before using any other methods.
  ///
  /// [config] — your [ReviewConfig] built with [ReviewConfig.builder].
  /// [rules] — explicit list of [ReviewRule] instances to evaluate.
  /// [storage] — optional custom storage backend. Defaults to
  ///   [SharedPreferencesStorage] for persistent on-device storage.
  ///   Pass [InMemoryStorage] for ephemeral/testing usage.
  /// [appVersion] — optional current app version string (e.g. `"1.2.3"`).
  ///   When provided, ReviewKit detects version changes and records the
  ///   update date for time-based eligibility rules.
  ///
  /// ```dart
  /// await ReviewViewModel.instance.init(
  ///   config: ReviewConfig.builder().launches(min: 5).build(),
  ///   rules: [LaunchRule(), CooldownRule()],
  ///   appVersion: '1.0.0',
  /// );
  /// ```
  Future<void> init({
    required ReviewConfig config,
    List<ReviewRule> rules = const [],
    ReviewStorage? storage,
    String? appVersion,
  }) async {
    if (_initialized) return;

    if (storage != null) {
      _storage = storage;
    } else {
      final prefsStorage = SharedPreferencesStorage();
      await prefsStorage.init();
      _storage = prefsStorage;
    }

    _config = config;
    _ruleEngine = RuleEngine(_storage, rules);

    _initialized = true;

    if (appVersion != null) {
      await _checkAppUpdate(appVersion);
    }

    if (_config.autoTrackLaunches == true) {
      await _trackLaunch();
    }
  }

  /// Register a callback handler for a [ReviewKitCallback] event.
  ///
  /// Multiple handlers can be registered for the same event.
  void on({
    required ReviewKitCallback callback,
    required void Function(dynamic) handler,
  }) {
    _callbacks.putIfAbsent(callback, () => []);
    _callbacks[callback]!.add(handler);
  }

  /// Remove a previously registered callback handler.
  ///
  /// If [handler] is null, all handlers for this callback are removed.
  void off({
    required ReviewKitCallback callback,
    void Function(dynamic)? handler,
  }) {
    if (handler != null) {
      _callbacks[callback]?.remove(handler);
    } else {
      _callbacks.remove(callback);
    }
  }

  void _emit(ReviewKitCallback callback, [dynamic data]) {
    final handlers = _callbacks[callback];
    if (handlers != null) {
      for (final handler in handlers) {
        handler(data);
      }
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
  ///
  /// If [ReviewConfig.autoTrackSessions] is enabled, increments the session
  /// counter. If [ReviewConfig.autoTrackUsageTime] is enabled, begins tracking
  /// elapsed seconds until [endSession] is called.
  Future<void> startSession() async {
    if (!_initialized || _sessionActive) return;

    _sessionActive = true;
    _sessionElapsed = 0;

    if (_config.autoTrackSessions == true) {
      final sessions = _storage.getSessionCount();
      await _storage.setSessionCount(sessions + 1);
      notifyListeners();
    }

    if (_config.autoTrackUsageTime == true) {
      _sessionTimer = Timer.periodic(const Duration(seconds: 1), (_) {
        _sessionElapsed++;
      });
    }
  }

  /// End the current usage session.
  ///
  /// Flushes elapsed usage time to persistent storage.
  Future<void> endSession() async {
    if (!_sessionActive) return;

    _sessionActive = false;
    _sessionTimer?.cancel();
    _sessionTimer = null;

    if (_config.autoTrackUsageTime == true && _sessionElapsed > 0) {
      final total = _storage.getUsageDuration();
      await _storage.setUsageDuration(total + _sessionElapsed);
      notifyListeners();
    }
  }

  /// Record a custom event.
  ///
  /// Events are stored persistently and can be used with [EventRule] to
  /// require a minimum number of occurrences before review eligibility.
  ///
  /// Example: `trackEvent('purchase_made')`
  Future<void> trackEvent(String eventName) async {
    if (!_initialized) return;
    await _storage.incrementEvent(eventName);
    notifyListeners();
  }

  /// Get all tracked custom events and their counts.
  Map<String, int> getEvents() => _storage.getEvents();

  /// Reset a specific event counter to zero.
  Future<void> resetEvent(String eventName) async {
    final events = _storage.getEvents();
    events.remove(eventName);
    await _storage.setEvents(events);
    notifyListeners();
  }

  /// Manually increment the launch counter.
  Future<void> incrementLaunchCount() async {
    final launches = _storage.getLaunchCount();
    await _storage.setLaunchCount(launches + 1);
    notifyListeners();
  }

  /// Manually increment the session counter.
  Future<void> incrementSessionCount() async {
    final sessions = _storage.getSessionCount();
    await _storage.setSessionCount(sessions + 1);
    notifyListeners();
  }

  /// Run all eligibility rules against the current config and data.
  ///
  /// Returns a [ReviewEligibility] with passed/failed rules and reasons.
  ReviewEligibility checkEligibility() {
    _lastEligibility = _ruleEngine.checkEligibility(_config);
    notifyListeners();
    return _lastEligibility!;
  }

  /// Get a detailed [ReviewReason] explaining the current eligibility state.
  ///
  /// This is the primary way to surface diagnostic information to developers
  /// about why a review was or was not requested.
  ReviewReason getEligibilityReason() {
    _lastReason = _ruleEngine.getEligibilityReason(_config);
    notifyListeners();
    return _lastReason!;
  }

  /// Attempt to request an in-app review, subject to all eligibility rules.
  ///
  /// Returns `true` if the native review dialog was shown.
  /// Returns `false` if:
  /// - Any eligibility rule failed (use [getEligibilityReason] to see why)
  /// - The native review API is unavailable
  /// - A request is already in progress
  ///
  /// This method automatically:
  /// 1. Evaluates all registered rules
  /// 2. Checks native API availability
  /// 3. Records the request date on success
  /// 4. Fires appropriate callbacks
  Future<bool> maybeRequestReview() async {
    if (!_initialized || _isRequesting) return false;

    final eligibility = checkEligibility();

    if (!eligibility.eligible) {
      _lastReason = _ruleEngine.getEligibilityReason(_config);
      _emit(ReviewKitCallback.ineligible, _lastReason);
      _emit(ReviewKitCallback.reviewSkipped, _lastReason);
      return false;
    }

    _emit(ReviewKitCallback.eligible, eligibility);

    final available = await _nativeService.isAvailable();
    if (!available) {
      _emit(ReviewKitCallback.reviewUnavailable);
      _emit(ReviewKitCallback.reviewSkipped);
      return false;
    }

    _isRequesting = true;
    notifyListeners();

    try {
      final success = await _nativeService.requestReview();
      if (success) {
        await _storage.setLastReviewRequestDate(DateTime.now());
        await _storage.setRequestedThisSession(true);
        _emit(ReviewKitCallback.reviewRequested);
        return true;
      } else {
        _emit(ReviewKitCallback.reviewUnavailable);
        _emit(ReviewKitCallback.reviewSkipped);
        return false;
      }
    } finally {
      _isRequesting = false;
      notifyListeners();
    }
  }

  /// Open the platform's store listing page.
  ///
  /// [iosAppId] is required for iOS to open the correct App Store page.
  /// Records the redirect date for cooldown tracking.
  Future<void> openStoreListing({
    String androidAppId = '',
    String iosAppId = '',
  }) async {
    await _nativeService.openStoreListing(
      androidAppId: androidAppId,
      iosAppId: iosAppId,
    );
    await _storage.setLastStoreRedirectDate(DateTime.now());
    _emit(ReviewKitCallback.storeOpened);
  }

  /// Get a complete snapshot of all tracked statistics.
  ReviewStatistics getStatistics() {
    final eligibility = checkEligibility();
    final lastReview = _storage.getLastReviewRequestDate();
    final cooldownActive = _isCooldownActive();
    final cooldownRemaining = cooldownActive ? _getCooldownRemaining() : null;

    return ReviewStatistics(
      launchCount: _storage.getLaunchCount(),
      sessionCount: _storage.getSessionCount(),
      usageDurationSeconds: _storage.getUsageDuration(),
      eventTotals: Map.from(_storage.getEvents()),
      installDate: _storage.getInstallDate(),
      firstLaunchDate: _storage.getFirstLaunchDate(),
      lastReviewRequestDate: lastReview,
      lastStoreRedirectDate: _storage.getLastStoreRedirectDate(),
      lastAppUpdateDate: _storage.getLastAppUpdateDate(),
      cooldownActive: cooldownActive,
      cooldownRemainingDays: cooldownRemaining,
      isEligible: eligibility.eligible,
    );
  }

  bool _isCooldownActive() {
    if (_config.cooldownDaysAfterReview == null) return false;
    final now = DateTime.now();
    final lastReview = _storage.getLastReviewRequestDate();
    if (lastReview != null) {
      final daysSince = now.difference(lastReview).inDays;
      if (daysSince < _config.cooldownDaysAfterReview!) return true;
    }
    return false;
  }

  int? _getCooldownRemaining() {
    if (_config.cooldownDaysAfterReview == null) return null;
    final now = DateTime.now();
    final lastReview = _storage.getLastReviewRequestDate();
    if (lastReview != null) {
      final daysSince = now.difference(lastReview).inDays;
      final remaining = _config.cooldownDaysAfterReview! - daysSince;
      if (remaining > 0) return remaining;
    }
    return null;
  }

  /// Reset all counters, events, dates, and cooldowns.
  Future<void> resetAll() async {
    await _storage.resetAll();
    _lastEligibility = null;
    _lastReason = null;
    notifyListeners();
  }

  /// Reset the launch counter to zero.
  Future<void> resetLaunches() async {
    await _storage.setLaunchCount(0);
    notifyListeners();
  }

  /// Reset the session counter to zero.
  Future<void> resetSessions() async {
    await _storage.setSessionCount(0);
    notifyListeners();
  }

  /// Reset the usage time counter to zero.
  Future<void> resetUsageTime() async {
    await _storage.setUsageDuration(0);
    notifyListeners();
  }

  /// Reset all custom event counters.
  Future<void> resetEvents() async {
    await _storage.resetEvents();
    notifyListeners();
  }

  /// Reset cooldowns so a review can be requested immediately.
  Future<void> resetCooldowns() async {
    await _storage.setLastReviewRequestDate(DateTime(2000));
    await _storage.setRequestedThisSession(false);
    notifyListeners();
  }

  /// Check if the native review API is available on this device.
  Future<bool> isNativeReviewAvailable() => _nativeService.isAvailable();

  /// Update the configuration and optionally the rule set at runtime.
  ///
  /// [config] — the new [ReviewConfig]. [rules] — optional new rule list.
  void updateConfig(ReviewConfig config, {List<ReviewRule>? rules}) {
    _config = config;
    if (rules != null) {
      _ruleEngine = RuleEngine(_storage, rules);
    }
    notifyListeners();
  }

  @override
  void dispose() {
    _sessionTimer?.cancel();
    super.dispose();
  }
}
