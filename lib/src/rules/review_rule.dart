import '../models/review_config.dart';
import '../services/review_storage.dart';

/// Base class for all eligibility rules.
///
/// Implement this interface to create custom conditions that are evaluated
/// before a review request is made. Each rule has a [name], an [evaluate]
/// method, and a [getFailureReason] method for diagnostics.
///
/// Built-in implementations:
/// - [LaunchRule]
/// - [TimeRule]
/// - [SessionRule]
/// - [EventRule]
/// - [CooldownRule]
abstract class ReviewRule {
  /// Human-readable name for this rule (e.g., "Launch Count").
  String get name;

  /// Evaluate whether this rule's condition is satisfied.
  ///
  /// [config] — the current [ReviewConfig].
  /// [storage] — access to persisted counters and dates.
  ///
  /// Returns `true` if the condition passes, `false` otherwise.
  bool evaluate(ReviewConfig config, ReviewStorage storage);

  /// Get a human-readable explanation of why this rule failed.
  ///
  /// Only called when [evaluate] returns `false`. Return an empty string
  /// if no specific reason is available.
  String getFailureReason(ReviewConfig config, ReviewStorage storage);
}

/// A rule defined by inline callbacks instead of a concrete class.
///
/// Allows developers to add custom eligibility conditions without creating
/// a new class. Useful for app-specific checks like network status,
/// user preferences, or feature flags.
///
/// ```dart
/// CustomReviewRule(
///   name: 'Network Available',
///   onEvaluate: (_, __) => connectivity.isConnected,
///   onFailureReason: (_, __) => 'No network connection',
/// )
/// ```
class CustomReviewRule extends ReviewRule {
  @override
  final String name;

  /// Callback invoked to evaluate this custom condition.
  final bool Function(ReviewConfig config, ReviewStorage storage) onEvaluate;

  /// Callback invoked to get the failure reason when [onEvaluate] returns false.
  final String Function(ReviewConfig config, ReviewStorage storage)
      onFailureReason;

  /// Creates a custom rule with inline callbacks.
  ///
  /// [name] — a descriptive name for diagnostics.
  /// [onEvaluate] — the condition to check.
  /// [reason] — optional failure reason callback. Defaults to
  /// `'Custom rule "$name" failed'`.
  CustomReviewRule({
    required this.name,
    required this.onEvaluate,
    String Function(ReviewConfig config, ReviewStorage storage)? reason,
  }) : onFailureReason =
            reason ?? ((config, storage) => 'Custom rule "$name" failed');

  @override
  bool evaluate(ReviewConfig config, ReviewStorage storage) =>
      onEvaluate(config, storage);

  @override
  String getFailureReason(ReviewConfig config, ReviewStorage storage) =>
      onFailureReason(config, storage);
}
