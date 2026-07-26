/// A detailed explanation of why a review was or was not requested.
///
/// Provides complete transparency into the eligibility decision. Useful for
/// debugging and logging why [ReviewViewModel.maybeRequestReview] returned
/// `false`.
///
/// ```dart
/// final reason = ReviewViewModel.instance.getEligibilityReason();
/// print(reason);
/// // ❌ Not Eligible
/// // Reason:
/// // • App launches: 3/5
/// // • Days since install: 2/7
/// ```
class ReviewReason {
  /// Whether the review request is eligible.
  final bool eligible;

  /// Short summary of the eligibility state.
  ///
  /// e.g. "All conditions met" or "Some conditions not met".
  final String summary;

  /// Detailed failure reasons for each condition that wasn't met.
  ///
  /// Empty list when [eligible] is `true`.
  final List<String> details;

  const ReviewReason({
    required this.eligible,
    required this.summary,
    this.details = const [],
  });

  /// Formats the reason as a human-readable string.
  ///
  /// Example output:
  /// ```
  /// ❌ Not Eligible
  /// Reason:
  /// • App launches: 3/5
  /// ```
  @override
  String toString() {
    final header = eligible ? '✅ Eligible' : '❌ Not Eligible';
    if (eligible || details.isEmpty) {
      return '$header\n$summary';
    }
    final buffer = StringBuffer('$header\n$summary\n');
    for (final detail in details) {
      buffer.writeln('• $detail');
    }
    return buffer.toString().trimRight();
  }
}
