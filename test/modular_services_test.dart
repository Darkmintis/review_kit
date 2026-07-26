import 'package:flutter_test/flutter_test.dart';
import 'package:in_app_review_kit/src/services/callback_dispatcher.dart';
import 'package:in_app_review_kit/src/services/usage_tracker.dart';
import 'package:in_app_review_kit/in_app_review_kit.dart';

void main() {
  group('CallbackDispatcher', () {
    test('on / emit / off', () {
      final bus = CallbackDispatcher();
      final seen = <Object?>[];

      void handler(dynamic data) => seen.add(data);
      bus.on(ReviewKitCallback.eligible, handler);
      bus.emit(ReviewKitCallback.eligible, 'ok');
      expect(seen, ['ok']);

      bus.off(ReviewKitCallback.eligible, handler);
      bus.emit(ReviewKitCallback.eligible, 'again');
      expect(seen, ['ok']);
    });
  });

  group('UsageTracker', () {
    test('startSession increments count when requested', () async {
      final storage = InMemoryStorage();
      final tracker = UsageTracker(storage);

      final started = await tracker.startSession(
        trackSessionCount: true,
        trackUsageTime: false,
      );
      expect(started, isTrue);
      expect(storage.getSessionCount(), 1);
      expect(tracker.isSessionActive, isTrue);

      await tracker.endSession(trackUsageTime: false);
      expect(tracker.isSessionActive, isFalse);
      tracker.dispose();
    });

    test('second startSession is ignored while active', () async {
      final storage = InMemoryStorage();
      final tracker = UsageTracker(storage);

      await tracker.startSession(
        trackSessionCount: true,
        trackUsageTime: false,
      );
      final again = await tracker.startSession(
        trackSessionCount: true,
        trackUsageTime: false,
      );
      expect(again, isFalse);
      expect(storage.getSessionCount(), 1);
      tracker.dispose();
    });
  });
}
