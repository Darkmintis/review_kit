import '../models/review_config.dart';
import '../services/review_storage.dart';
import 'review_rule.dart';

/// Evaluates cooldown-based eligibility.
///
/// Prevents review requests during cooldown periods after a previous request
/// or store redirect. Also enforces the one-request-per-session limit.
///
/// Each condition is only evaluated if the corresponding field is set
/// in [ReviewConfig].
class CooldownRule extends ReviewRule {
  @override
  String get name => 'Cooldown';

  @override
  bool evaluate(ReviewConfig config, ReviewStorage storage) {
    final now = DateTime.now();

    if (config.oneRequestPerSession == true &&
        storage.getRequestedThisSession()) {
      return false;
    }

    if (config.cooldownDaysAfterReview != null) {
      final lastReview = storage.getLastReviewRequestDate();
      if (lastReview != null) {
        final daysSince = now.difference(lastReview).inDays;
        if (daysSince < config.cooldownDaysAfterReview!) return false;
      }
    }

    if (config.cooldownDaysAfterStoreRedirect != null) {
      final lastRedirect = storage.getLastStoreRedirectDate();
      if (lastRedirect != null) {
        final daysSince = now.difference(lastRedirect).inDays;
        if (daysSince < config.cooldownDaysAfterStoreRedirect!) return false;
      }
    }

    return true;
  }

  @override
  String getFailureReason(ReviewConfig config, ReviewStorage storage) {
    final reasons = <String>[];
    final now = DateTime.now();

    if (config.oneRequestPerSession == true &&
        storage.getRequestedThisSession()) {
      reasons.add('Already requested in this session');
    }

    if (config.cooldownDaysAfterReview != null) {
      final lastReview = storage.getLastReviewRequestDate();
      if (lastReview != null) {
        final daysSince = now.difference(lastReview).inDays;
        if (daysSince < config.cooldownDaysAfterReview!) {
          final remaining = config.cooldownDaysAfterReview! - daysSince;
          reasons.add('Cooldown after review: $remaining days remaining');
        }
      }
    }

    if (config.cooldownDaysAfterStoreRedirect != null) {
      final lastRedirect = storage.getLastStoreRedirectDate();
      if (lastRedirect != null) {
        final daysSince = now.difference(lastRedirect).inDays;
        if (daysSince < config.cooldownDaysAfterStoreRedirect!) {
          final remaining =
              config.cooldownDaysAfterStoreRedirect! - daysSince;
          reasons.add(
              'Cooldown after store redirect: $remaining days remaining');
        }
      }
    }

    return reasons.isNotEmpty ? reasons.join('\n') : '';
  }
}
