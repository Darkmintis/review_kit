import '../models/review_config.dart';
import '../services/review_storage.dart';
import 'review_rule.dart';

/// Evaluates time-based eligibility conditions.
///
/// Checks minimum days since install, first launch, last review request,
/// and last app update. Each condition is only evaluated if the corresponding
/// field is set in [ReviewConfig].
class TimeRule extends ReviewRule {
  @override
  String get name => 'Time Conditions';

  @override
  bool evaluate(ReviewConfig config, ReviewStorage storage) {
    final now = DateTime.now();

    if (config.minDaysSinceInstall != null) {
      final installDate = storage.getInstallDate();
      if (installDate != null) {
        final daysSince = now.difference(installDate).inDays;
        if (daysSince < config.minDaysSinceInstall!) return false;
      }
    }

    if (config.minDaysSinceFirstLaunch != null) {
      final firstLaunch = storage.getFirstLaunchDate();
      if (firstLaunch != null) {
        final daysSince = now.difference(firstLaunch).inDays;
        if (daysSince < config.minDaysSinceFirstLaunch!) return false;
      }
    }

    if (config.minDaysSinceLastReview != null) {
      final lastReview = storage.getLastReviewRequestDate();
      if (lastReview != null) {
        final daysSince = now.difference(lastReview).inDays;
        if (daysSince < config.minDaysSinceLastReview!) return false;
      }
    }

    if (config.minDaysSinceLastUpdate != null) {
      final lastUpdate = storage.getLastAppUpdateDate();
      if (lastUpdate != null) {
        final daysSince = now.difference(lastUpdate).inDays;
        if (daysSince < config.minDaysSinceLastUpdate!) return false;
      }
    }

    return true;
  }

  @override
  String getFailureReason(ReviewConfig config, ReviewStorage storage) {
    final now = DateTime.now();
    final reasons = <String>[];

    if (config.minDaysSinceInstall != null) {
      final installDate = storage.getInstallDate();
      if (installDate != null) {
        final daysSince = now.difference(installDate).inDays;
        if (daysSince < config.minDaysSinceInstall!) {
          reasons.add(
              'Days since install: $daysSince/${config.minDaysSinceInstall}');
        }
      }
    }

    if (config.minDaysSinceFirstLaunch != null) {
      final firstLaunch = storage.getFirstLaunchDate();
      if (firstLaunch != null) {
        final daysSince = now.difference(firstLaunch).inDays;
        if (daysSince < config.minDaysSinceFirstLaunch!) {
          reasons.add(
              'Days since first launch: $daysSince/${config.minDaysSinceFirstLaunch}');
        }
      }
    }

    if (config.minDaysSinceLastReview != null) {
      final lastReview = storage.getLastReviewRequestDate();
      if (lastReview != null) {
        final daysSince = now.difference(lastReview).inDays;
        if (daysSince < config.minDaysSinceLastReview!) {
          reasons.add(
              'Days since last review: $daysSince/${config.minDaysSinceLastReview}');
        }
      }
    }

    if (config.minDaysSinceLastUpdate != null) {
      final lastUpdate = storage.getLastAppUpdateDate();
      if (lastUpdate != null) {
        final daysSince = now.difference(lastUpdate).inDays;
        if (daysSince < config.minDaysSinceLastUpdate!) {
          reasons.add(
              'Days since last update: $daysSince/${config.minDaysSinceLastUpdate}');
        }
      }
    }

    return reasons.isNotEmpty ? reasons.join('\n') : '';
  }
}
