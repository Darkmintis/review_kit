import '../models/review_config.dart';
import '../services/review_storage.dart';
import 'review_rule.dart';

/// Evaluates session-based eligibility conditions.
///
/// Checks minimum session count and minimum total usage time.
/// Each condition is only evaluated if the corresponding field is set
/// in [ReviewConfig].
class SessionRule extends ReviewRule {
  @override
  String get name => 'Session Conditions';

  @override
  bool evaluate(ReviewConfig config, ReviewStorage storage) {
    if (config.minSessions != null) {
      final sessions = storage.getSessionCount();
      if (sessions < config.minSessions!) return false;
    }

    if (config.minTotalUsageSeconds != null) {
      final usage = storage.getUsageDuration();
      if (usage < config.minTotalUsageSeconds!) return false;
    }

    return true;
  }

  @override
  String getFailureReason(ReviewConfig config, ReviewStorage storage) {
    final reasons = <String>[];

    if (config.minSessions != null) {
      final sessions = storage.getSessionCount();
      if (sessions < config.minSessions!) {
        reasons.add('Sessions: $sessions/${config.minSessions}');
      }
    }

    if (config.minTotalUsageSeconds != null) {
      final usage = storage.getUsageDuration();
      if (usage < config.minTotalUsageSeconds!) {
        final minutes = (usage / 60).round();
        final minMinutes = (config.minTotalUsageSeconds! / 60).round();
        reasons.add('Usage time: ${minutes}m / ${minMinutes}m');
      }
    }

    return reasons.isNotEmpty ? reasons.join('\n') : '';
  }
}
