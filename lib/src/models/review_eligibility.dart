/// The result of an eligibility check.
///
/// Contains the overall eligibility status along with lists of passed and
/// failed rules and their diagnostic messages.
class ReviewEligibility {
  /// Whether the user is eligible to be asked for a review.
  final bool eligible;

  /// Names of rules that passed evaluation.
  final List<String> passedRules;

  /// Names of rules that failed evaluation.
  final List<String> failedRules;

  /// Human-readable failure reasons for debugging.
  ///
  /// Each entry describes why a specific condition was not met
  /// (e.g. "App launches: 3/5").
  final List<String> reasons;

  const ReviewEligibility({
    required this.eligible,
    this.passedRules = const [],
    this.failedRules = const [],
    this.reasons = const [],
  });
}
