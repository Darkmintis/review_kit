import 'dart:async';

import 'review_storage.dart';

/// Tracks manual sessions and automatic foreground usage time.
///
/// Persists elapsed seconds into [ReviewStorage]. Extracted from the ViewModel
/// so timing logic can evolve without bloating orchestration code.
class UsageTracker {
  final ReviewStorage _storage;

  bool _sessionActive = false;
  Timer? _sessionTimer;
  int _sessionElapsed = 0;

  Timer? _foregroundTimer;
  int _foregroundElapsed = 0;
  bool _isInForeground = false;

  /// Creates a tracker bound to [storage].
  UsageTracker(this._storage);

  /// Whether a manual session started with [startSession] is active.
  bool get isSessionActive => _sessionActive;

  /// Whether the app is currently considered foregrounded for auto tracking.
  bool get isInForeground => _isInForeground;

  /// Begin automatic foreground ticking.
  void startForegroundTracking() {
    _isInForeground = true;
    _startForegroundTimer();
  }

  /// Handle app resume — resume the foreground timer.
  void onResumed() {
    _isInForeground = true;
    _startForegroundTimer();
  }

  /// Handle app background/inactive — flush elapsed foreground time.
  void onBackgrounded() {
    _isInForeground = false;
    flushForegroundTime();
  }

  void _startForegroundTimer() {
    _foregroundTimer?.cancel();
    _foregroundTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      _foregroundElapsed++;
    });
  }

  /// Persist and clear accumulated foreground seconds.
  void flushForegroundTime() {
    _foregroundTimer?.cancel();
    _foregroundTimer = null;

    if (_foregroundElapsed > 0) {
      final total = _storage.getUsageDuration();
      _storage.setUsageDuration(total + _foregroundElapsed);
      _foregroundElapsed = 0;
    }
  }

  /// Start a manual usage session.
  ///
  /// When [trackSessionCount] is true, increments the persisted session
  /// counter. When [trackUsageTime] is true and the app is not already
  /// foreground-tracked, starts a session timer.
  ///
  /// Returns `true` if a new session was started.
  Future<bool> startSession({
    required bool trackSessionCount,
    required bool trackUsageTime,
  }) async {
    if (_sessionActive) return false;

    _sessionActive = true;
    _sessionElapsed = 0;

    if (trackSessionCount) {
      final sessions = _storage.getSessionCount();
      await _storage.setSessionCount(sessions + 1);
    }

    if (trackUsageTime && !_isInForeground) {
      _sessionTimer = Timer.periodic(const Duration(seconds: 1), (_) {
        _sessionElapsed++;
      });
    }

    return true;
  }

  /// End the manual session and flush session usage time when enabled.
  Future<void> endSession({required bool trackUsageTime}) async {
    if (!_sessionActive) return;

    _sessionActive = false;
    _sessionTimer?.cancel();
    _sessionTimer = null;

    if (trackUsageTime && _sessionElapsed > 0) {
      final total = _storage.getUsageDuration();
      await _storage.setUsageDuration(total + _sessionElapsed);
      _sessionElapsed = 0;
    }
  }

  /// Clear in-memory elapsed counters (does not clear persisted storage).
  void clearElapsed() {
    _foregroundElapsed = 0;
    _sessionElapsed = 0;
  }

  /// Cancel timers and reset in-memory session state.
  void dispose() {
    flushForegroundTime();
    _sessionTimer?.cancel();
    _sessionTimer = null;
    _foregroundTimer?.cancel();
    _foregroundTimer = null;
    _sessionActive = false;
    clearElapsed();
    _isInForeground = false;
  }
}
