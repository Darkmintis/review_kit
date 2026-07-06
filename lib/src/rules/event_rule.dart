import '../models/review_config.dart';
import '../services/review_storage.dart';
import 'review_rule.dart';

/// Evaluates custom event threshold eligibility.
///
/// Checks that each configured event has reached its minimum count.
/// Uses [ReviewConfig.eventThresholds] to determine requirements.
/// If no thresholds are set, this rule always passes.
class EventRule extends ReviewRule {
  @override
  String get name => 'Custom Events';

  @override
  bool evaluate(ReviewConfig config, ReviewStorage storage) {
    final events = storage.getEvents();
    final thresholds = config.eventThresholds;

    if (thresholds == null || thresholds.isEmpty) return true;

    for (final entry in thresholds.entries) {
      final current = events[entry.key] ?? 0;
      if (current < entry.value) return false;
    }

    return true;
  }

  @override
  String getFailureReason(ReviewConfig config, ReviewStorage storage) {
    final reasons = <String>[];
    final events = storage.getEvents();
    final thresholds = config.eventThresholds;

    if (thresholds == null || thresholds.isEmpty) return '';

    for (final entry in thresholds.entries) {
      final current = events[entry.key] ?? 0;
      if (current < entry.value) {
        reasons.add('Event "${entry.key}": $current/${entry.value}');
      }
    }

    return reasons.isNotEmpty ? reasons.join('\n') : '';
  }
}
