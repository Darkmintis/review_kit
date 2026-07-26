import 'package:flutter_test/flutter_test.dart';
import 'package:in_app_review_kit/in_app_review_kit.dart';
import 'package:in_app_review_kit/src/rules/rule_engine.dart';

void main() {
  late InMemoryStorage storage;

  setUp(() {
    storage = InMemoryStorage();
  });

  group('RuleEngine', () {
    test('eligible when all rules pass', () async {
      final engine = RuleEngine(storage, [LaunchRule(), SessionRule()]);
      final config =
          ReviewConfig.builder().launches(min: 1).sessions(1).build();
      await storage.setLaunchCount(2);
      await storage.setSessionCount(1);

      final result = engine.checkEligibility(config);
      expect(result.eligible, isTrue);
      expect(result.failedRules, isEmpty);
      expect(result.passedRules, hasLength(2));
    });

    test('ineligible lists failed rules and reasons', () async {
      final engine = RuleEngine(storage, [LaunchRule(), EventRule()]);
      final config = ReviewConfig.builder()
          .launches(min: 5)
          .event('buy', threshold: 1)
          .build();
      await storage.setLaunchCount(1);

      final result = engine.checkEligibility(config);
      expect(result.eligible, isFalse);
      expect(result.failedRules, contains('Launch Count'));
      expect(result.failedRules, contains('Custom Events'));
      expect(result.reasons, isNotEmpty);

      final reason = engine.getEligibilityReason(config);
      expect(reason.eligible, isFalse);
      expect(reason.details, isNotEmpty);
    });

    test('empty rule list is always eligible', () {
      final engine = RuleEngine(storage, []);
      final result = engine.checkEligibility(ReviewConfig.builder().build());
      expect(result.eligible, isTrue);
    });
  });

  group('InMemoryStorage', () {
    test('round-trips counters, dates, and events', () async {
      await storage.setLaunchCount(4);
      await storage.setSessionCount(2);
      await storage.setUsageDuration(90);
      final now = DateTime.now();
      await storage.setInstallDate(now);
      await storage.incrementEvent('win');
      await storage.incrementEvent('win');

      expect(storage.getLaunchCount(), 4);
      expect(storage.getSessionCount(), 2);
      expect(storage.getUsageDuration(), 90);
      expect(storage.getInstallDate(), now);
      expect(storage.getEvents()['win'], 2);

      await storage.clearLastReviewRequestDate();
      expect(storage.getLastReviewRequestDate(), isNull);

      await storage.resetAll();
      expect(storage.getLaunchCount(), 0);
      expect(storage.getEvents(), isEmpty);
    });

    test('requestedThisSession is mutable in memory', () async {
      expect(storage.getRequestedThisSession(), isFalse);
      await storage.setRequestedThisSession(true);
      expect(storage.getRequestedThisSession(), isTrue);
      await storage.resetAll();
      expect(storage.getRequestedThisSession(), isFalse);
    });
  });

  group('ReviewConfig builder', () {
    test('only set fields are non-null', () {
      final config = ReviewConfig.builder()
          .launches(min: 3, max: 10)
          .daysSinceInstall(7)
          .cooldown(daysAfterReview: 60, onePerSession: true)
          .event('a', threshold: 2)
          .autoTrack(launches: true)
          .debug(true)
          .build();

      expect(config.minLaunches, 3);
      expect(config.maxLaunches, 10);
      expect(config.minDaysSinceInstall, 7);
      expect(config.minSessions, isNull);
      expect(config.cooldownDaysAfterReview, 60);
      expect(config.oneRequestPerSession, isTrue);
      expect(config.eventThresholds?['a'], 2);
      expect(config.autoTrackLaunches, isTrue);
      expect(config.debugMode, isTrue);
    });
  });

  group('ReviewReason', () {
    test('formats eligible and ineligible states', () {
      const ok = ReviewReason(
        eligible: true,
        summary: 'All conditions met',
      );
      expect(ok.toString(), contains('Eligible'));
      expect(ok.toString(), contains('All conditions met'));
      expect(ok.toString(), isNot(contains('•')));

      const bad = ReviewReason(
        eligible: false,
        summary: 'Some conditions not met',
        details: ['App launches: 1/5'],
      );
      expect(bad.toString(), contains('Not Eligible'));
      expect(bad.toString(), contains('• App launches: 1/5'));
    });
  });
}
