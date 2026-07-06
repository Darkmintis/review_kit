import '../models/review_config.dart';
import '../services/review_storage.dart';
import 'review_rule.dart';

/// Evaluates launch-count eligibility.
///
/// Requires that the number of app launches is within the configured bounds.
/// Skips evaluation if [ReviewConfig.minLaunches] and [ReviewConfig.maxLaunches]
/// are both null.
class LaunchRule extends ReviewRule {
  @override
  String get name => 'Launch Count';

  @override
  bool evaluate(ReviewConfig config, ReviewStorage storage) {
    final launches = storage.getLaunchCount();

    if (config.minLaunches != null && launches < config.minLaunches!) {
      return false;
    }
    if (config.maxLaunches != null && launches > config.maxLaunches!) {
      return false;
    }

    return true;
  }

  @override
  String getFailureReason(ReviewConfig config, ReviewStorage storage) {
    final launches = storage.getLaunchCount();
    if (config.minLaunches != null && launches < config.minLaunches!) {
      return 'App launches: $launches/${config.minLaunches}';
    }
    if (config.maxLaunches != null && launches > config.maxLaunches!) {
      return 'App launches $launches exceeds max ${config.maxLaunches}';
    }
    return '';
  }
}
