import 'cooldown_rule.dart';
import 'event_rule.dart';
import 'launch_rule.dart';
import 'review_rule.dart';
import 'session_rule.dart';
import 'time_rule.dart';

/// Default built-in rules used when [ReviewViewModel.init] is called without
/// an explicit rules list.
///
/// Rules whose config fields are unset are no-ops, so this set is safe for
/// every configuration.
List<ReviewRule> defaultReviewRules() => [
      LaunchRule(),
      TimeRule(),
      SessionRule(),
      EventRule(),
      CooldownRule(),
    ];
