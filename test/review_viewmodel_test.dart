import 'package:flutter_test/flutter_test.dart';
import 'package:in_app_review_kit/in_app_review_kit.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late InMemoryStorage storage;

  setUp(() async {
    storage = InMemoryStorage();
    await ReviewViewModel.instance.resetForTesting();
  });

  tearDown(() async {
    await ReviewViewModel.instance.resetForTesting();
  });

  Future<void> initWith({
    ReviewConfig? config,
    List<ReviewRule>? rules,
  }) {
    return ReviewViewModel.instance.init(
      config: config ??
          ReviewConfig.builder()
              .launches(min: 1)
              .autoTrack(launches: true)
              .build(),
      rules: rules,
      storage: storage,
      force: true,
    );
  }

  group('ReviewViewModel.init', () {
    test('auto-tracks launches and install dates', () async {
      await initWith();
      expect(ReviewViewModel.instance.initialized, isTrue);
      expect(storage.getLaunchCount(), 1);
      expect(storage.getInstallDate(), isNotNull);
      expect(storage.getFirstLaunchDate(), isNotNull);
    });

    test('uses default rules when rules omitted', () async {
      await initWith(
        config: ReviewConfig.builder().launches(min: 5).build(),
      );
      // Launch count is 0 because autoTrack was off → not eligible.
      expect(ReviewViewModel.instance.checkEligibility().eligible, isFalse);

      await storage.setLaunchCount(5);
      expect(ReviewViewModel.instance.checkEligibility().eligible, isTrue);
    });

    test('ignores second init unless force is true', () async {
      await initWith(
        config: ReviewConfig.builder().launches(min: 1).build(),
      );
      await storage.setLaunchCount(0);

      await ReviewViewModel.instance.init(
        config: ReviewConfig.builder().launches(min: 99).build(),
        storage: InMemoryStorage(),
      );

      // Still using first config/storage.
      expect(ReviewViewModel.instance.config.minLaunches, 1);
    });

    test('force re-init replaces config and clears session flag', () async {
      await storage.setRequestedThisSession(true);
      await initWith(
        config: ReviewConfig.builder()
            .cooldown(onePerSession: true)
            .build(),
      );
      expect(storage.getRequestedThisSession(), isFalse);
    });

    test('records app update date on version change', () async {
      await storage.setLastAppVersion('1.0.0');
      await ReviewViewModel.instance.init(
        config: ReviewConfig.builder().build(),
        storage: storage,
        appVersion: '1.1.0',
        force: true,
      );
      expect(storage.getLastAppUpdateDate(), isNotNull);
      expect(storage.getLastAppVersion(), '1.1.0');
    });
  });

  group('ReviewViewModel tracking', () {
    test('trackEvent and getEvents', () async {
      await initWith(config: ReviewConfig.builder().build());
      await ReviewViewModel.instance.trackEvent('purchase');
      await ReviewViewModel.instance.trackEvent('purchase');
      expect(ReviewViewModel.instance.getEvents()['purchase'], 2);

      await ReviewViewModel.instance.resetEvent('purchase');
      expect(ReviewViewModel.instance.getEvents().containsKey('purchase'),
          isFalse);
    });

    test('startSession increments when autoTrackSessions enabled', () async {
      await initWith(
        config: ReviewConfig.builder()
            .autoTrack(sessions: true)
            .build(),
      );
      await ReviewViewModel.instance.startSession();
      expect(storage.getSessionCount(), 1);
      await ReviewViewModel.instance.endSession();
    });
  });

  group('ReviewViewModel.updateConfig', () {
    test('replaces config and rule engine without LateInitializationError',
        () async {
      await initWith(
        config: ReviewConfig.builder().launches(min: 1).build(),
        rules: [LaunchRule()],
      );
      await storage.setLaunchCount(5);

      ReviewViewModel.instance.updateConfig(
        ReviewConfig.builder().launches(min: 10).build(),
        rules: [LaunchRule()],
      );

      expect(ReviewViewModel.instance.config.minLaunches, 10);
      expect(ReviewViewModel.instance.checkEligibility().eligible, isFalse);
    });
  });

  group('ReviewViewModel resets', () {
    test('resetCooldowns clears dates instead of sentinel values', () async {
      await initWith(config: ReviewConfig.builder().build());
      await storage.setLastReviewRequestDate(DateTime.now());
      await storage.setLastStoreRedirectDate(DateTime.now());
      await storage.setRequestedThisSession(true);

      await ReviewViewModel.instance.resetCooldowns();

      expect(storage.getLastReviewRequestDate(), isNull);
      expect(storage.getLastStoreRedirectDate(), isNull);
      expect(storage.getRequestedThisSession(), isFalse);
    });

    test('resetAll clears everything', () async {
      await initWith(
        config: ReviewConfig.builder().autoTrack(launches: true).build(),
      );
      await ReviewViewModel.instance.trackEvent('x');
      await ReviewViewModel.instance.resetAll();
      expect(storage.getLaunchCount(), 0);
      expect(storage.getEvents(), isEmpty);
    });
  });

  group('ReviewViewModel.maybeRequestReview', () {
    test('returns false and emits ineligible when rules fail', () async {
      ReviewReason? seen;
      await initWith(
        config: ReviewConfig.builder().launches(min: 10).build(),
        rules: [LaunchRule()],
      );
      // autoTrack not enabled → 0 launches
      ReviewViewModel.instance.on(
        callback: ReviewKitCallback.ineligible,
        handler: (reason) => seen = reason as ReviewReason,
      );

      final result = await ReviewViewModel.instance.maybeRequestReview();
      expect(result, isFalse);
      expect(seen, isNotNull);
      expect(seen!.eligible, isFalse);
    });

    test('throws from checkEligibility before init', () async {
      expect(
        () => ReviewViewModel.instance.checkEligibility(),
        throwsA(isA<StateError>()),
      );
    });
  });

  group('defaultReviewRules', () {
    test('includes all built-in rules', () {
      final names = defaultReviewRules().map((r) => r.name).toSet();
      expect(names, containsAll([
        'Launch Count',
        'Time Conditions',
        'Session Conditions',
        'Custom Events',
        'Cooldown',
      ]));
    });
  });
}
