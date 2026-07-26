import 'package:flutter_test/flutter_test.dart';
import 'package:in_app_review_kit/in_app_review_kit.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('SharedPreferencesStorage', () {
    late SharedPreferencesStorage storage;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      storage = SharedPreferencesStorage();
      await storage.init();
    });

    test('persists counters and events', () async {
      await storage.setLaunchCount(3);
      await storage.setSessionCount(2);
      await storage.incrementEvent('win');
      await storage.incrementEvent('win');

      expect(storage.getLaunchCount(), 3);
      expect(storage.getSessionCount(), 2);
      expect(storage.getEvents()['win'], 2);
    });

    test('session flag is in-memory and cleared on init', () async {
      await storage.setRequestedThisSession(true);
      expect(storage.getRequestedThisSession(), isTrue);

      // Simulate a new process: new storage instance + init.
      SharedPreferences.setMockInitialValues({
        'review_kit_requested_this_session': true, // legacy key
      });
      final next = SharedPreferencesStorage();
      await next.init();
      expect(next.getRequestedThisSession(), isFalse);

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.containsKey('review_kit_requested_this_session'), isFalse);
    });

    test('clear methods remove dates', () async {
      await storage.setLastReviewRequestDate(DateTime.now());
      await storage.setLastStoreRedirectDate(DateTime.now());
      await storage.clearLastReviewRequestDate();
      await storage.clearLastStoreRedirectDate();
      expect(storage.getLastReviewRequestDate(), isNull);
      expect(storage.getLastStoreRedirectDate(), isNull);
    });
  });
}
