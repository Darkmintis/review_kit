import 'package:flutter_test/flutter_test.dart';
import 'package:in_app_review_kit/in_app_review_kit.dart';

void main() {
  late InMemoryStorage storage;

  setUp(() {
    storage = InMemoryStorage();
  });

  group('LaunchRule', () {
    final rule = LaunchRule();

    test('passes when no launch limits are configured', () {
      final config = ReviewConfig.builder().build();
      expect(rule.evaluate(config, storage), isTrue);
    });

    test('fails when below min launches', () async {
      final config = ReviewConfig.builder().launches(min: 5).build();
      await storage.setLaunchCount(2);
      expect(rule.evaluate(config, storage), isFalse);
      expect(rule.getFailureReason(config, storage), contains('2/5'));
    });

    test('passes when launch count meets minimum', () async {
      final config = ReviewConfig.builder().launches(min: 5).build();
      await storage.setLaunchCount(5);
      expect(rule.evaluate(config, storage), isTrue);
    });

    test('fails when above max launches', () async {
      final config = ReviewConfig.builder().launches(max: 10).build();
      await storage.setLaunchCount(11);
      expect(rule.evaluate(config, storage), isFalse);
    });
  });

  group('TimeRule', () {
    final rule = TimeRule();

    test('fails when install date is missing but required', () {
      final config = ReviewConfig.builder().daysSinceInstall(7).build();
      expect(rule.evaluate(config, storage), isFalse);
      expect(rule.getFailureReason(config, storage), contains('unknown'));
    });

    test('fails when days since install is too low', () async {
      final config = ReviewConfig.builder().daysSinceInstall(7).build();
      await storage.setInstallDate(DateTime.now().subtract(const Duration(days: 2)));
      expect(rule.evaluate(config, storage), isFalse);
    });

    test('passes when days since install is met', () async {
      final config = ReviewConfig.builder().daysSinceInstall(7).build();
      await storage.setInstallDate(DateTime.now().subtract(const Duration(days: 10)));
      expect(rule.evaluate(config, storage), isTrue);
    });

    test('passes minDaysSinceLastReview when never reviewed', () {
      final config = ReviewConfig.builder().daysSinceLastReview(30).build();
      expect(rule.evaluate(config, storage), isTrue);
    });

    test('fails when last review was too recent', () async {
      final config = ReviewConfig.builder().daysSinceLastReview(30).build();
      await storage.setLastReviewRequestDate(
        DateTime.now().subtract(const Duration(days: 5)),
      );
      expect(rule.evaluate(config, storage), isFalse);
    });

    test('passes minDaysSinceLastUpdate when never updated', () {
      final config = ReviewConfig.builder().daysSinceLastUpdate(1).build();
      expect(rule.evaluate(config, storage), isTrue);
    });
  });

  group('SessionRule', () {
    final rule = SessionRule();

    test('fails when below min sessions', () async {
      final config = ReviewConfig.builder().sessions(3).build();
      await storage.setSessionCount(1);
      expect(rule.evaluate(config, storage), isFalse);
    });

    test('fails when below min usage time', () async {
      final config = ReviewConfig.builder().usageTime(600).build();
      await storage.setUsageDuration(100);
      expect(rule.evaluate(config, storage), isFalse);
      expect(rule.getFailureReason(config, storage), contains('Usage time'));
    });

    test('passes when both thresholds are met', () async {
      final config =
          ReviewConfig.builder().sessions(2).usageTime(60).build();
      await storage.setSessionCount(2);
      await storage.setUsageDuration(60);
      expect(rule.evaluate(config, storage), isTrue);
    });
  });

  group('EventRule', () {
    final rule = EventRule();

    test('passes when no thresholds configured', () {
      final config = ReviewConfig.builder().build();
      expect(rule.evaluate(config, storage), isTrue);
    });

    test('fails when event count is below threshold', () async {
      final config =
          ReviewConfig.builder().event('purchase', threshold: 2).build();
      await storage.incrementEvent('purchase');
      expect(rule.evaluate(config, storage), isFalse);
      expect(rule.getFailureReason(config, storage), contains('purchase'));
    });

    test('passes when all event thresholds are met', () async {
      final config = ReviewConfig.builder()
          .event('purchase', threshold: 2)
          .event('level_up', threshold: 1)
          .build();
      await storage.incrementEvent('purchase');
      await storage.incrementEvent('purchase');
      await storage.incrementEvent('level_up');
      expect(rule.evaluate(config, storage), isTrue);
    });
  });

  group('CooldownRule', () {
    final rule = CooldownRule();

    test('blocks when already requested this session', () async {
      final config =
          ReviewConfig.builder().cooldown(onePerSession: true).build();
      await storage.setRequestedThisSession(true);
      expect(rule.evaluate(config, storage), isFalse);
      expect(
        rule.getFailureReason(config, storage),
        contains('Already requested'),
      );
    });

    test('blocks during post-review cooldown', () async {
      final config =
          ReviewConfig.builder().cooldown(daysAfterReview: 60).build();
      await storage.setLastReviewRequestDate(
        DateTime.now().subtract(const Duration(days: 10)),
      );
      expect(rule.evaluate(config, storage), isFalse);
    });

    test('passes after cooldown expires', () async {
      final config =
          ReviewConfig.builder().cooldown(daysAfterReview: 7).build();
      await storage.setLastReviewRequestDate(
        DateTime.now().subtract(const Duration(days: 10)),
      );
      expect(rule.evaluate(config, storage), isTrue);
    });

    test('blocks during store redirect cooldown', () async {
      final config = ReviewConfig.builder()
          .cooldown(daysAfterStoreRedirect: 7)
          .build();
      await storage.setLastStoreRedirectDate(
        DateTime.now().subtract(const Duration(days: 1)),
      );
      expect(rule.evaluate(config, storage), isFalse);
    });
  });

  group('CustomReviewRule', () {
    test('uses onFailureReason callback', () {
      final rule = CustomReviewRule(
        name: 'Premium',
        onEvaluate: (_, __) => false,
        onFailureReason: (_, __) => 'User is not premium',
      );
      final config = ReviewConfig.builder().build();
      expect(rule.evaluate(config, storage), isFalse);
      expect(rule.getFailureReason(config, storage), 'User is not premium');
    });

    test('defaults failure reason from name', () {
      final rule = CustomReviewRule(
        name: 'Opted In',
        onEvaluate: (_, __) => false,
      );
      final config = ReviewConfig.builder().build();
      expect(
        rule.getFailureReason(config, storage),
        'Custom rule "Opted In" failed',
      );
    });
  });
}
