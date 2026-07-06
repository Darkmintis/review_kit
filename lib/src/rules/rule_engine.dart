import '../models/review_config.dart';
import '../models/review_eligibility.dart';
import '../models/review_reason.dart';
import '../services/review_storage.dart';
import 'review_rule.dart';

/// Evaluates a list of [ReviewRule]s against the current [ReviewConfig] and
/// persisted data to determine review eligibility.
///
/// The engine iterates through all registered rules and collects which passed,
/// which failed, and the failure reasons for diagnostics.
class RuleEngine {
  final List<ReviewRule> _rules;
  final ReviewStorage _storage;

  /// Creates a rule engine with an explicit list of rules.
  ///
  /// No default rules are added — the developer provides exactly the rules
  /// they want evaluated.
  RuleEngine(this._storage, this._rules);

  /// Evaluate all rules and return the eligibility result.
  ReviewEligibility checkEligibility(ReviewConfig config) {
    final passed = <String>[];
    final failed = <String>[];
    final reasons = <String>[];

    for (final rule in _rules) {
      if (rule.evaluate(config, _storage)) {
        passed.add(rule.name);
      } else {
        failed.add(rule.name);
        final reason = rule.getFailureReason(config, _storage);
        if (reason.isNotEmpty) reasons.add(reason);
      }
    }

    return ReviewEligibility(
      eligible: failed.isEmpty,
      passedRules: passed,
      failedRules: failed,
      reasons: reasons,
    );
  }

  /// Get a detailed [ReviewReason] explaining the eligibility decision.
  ReviewReason getEligibilityReason(ReviewConfig config) {
    final result = checkEligibility(config);
    return ReviewReason(
      eligible: result.eligible,
      summary: result.eligible
          ? 'All conditions met'
          : 'Some conditions not met',
      details: result.reasons,
    );
  }

  /// Get a map of rule names to their pass/fail status.
  Map<String, bool> getRuleStatuses(ReviewConfig config) {
    final statuses = <String, bool>{};
    for (final rule in _rules) {
      statuses[rule.name] = rule.evaluate(config, _storage);
    }
    return statuses;
  }
}
