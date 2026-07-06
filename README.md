# ReviewKit

[![Flutter](https://img.shields.io/badge/Flutter-3.10%2B-blue)](https://flutter.dev)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)

A complete Flutter solution for intelligently managing **Google Play** and **App Store** in-app reviews. Built with **MVVM architecture** and **zero hardcoded defaults** — you control every condition.

## Features

- **Native Review API** — Google Play & App Store integration with graceful fallbacks
- **Fluent Builder Config** — Explicitly set every condition via `ReviewConfig.builder()`. Nothing is enforced unless you set it
- **Smart Eligibility Engine** — Launch count, time, sessions, events, and cooldown rules
- **Custom Rule Callbacks** — Add your own eligibility conditions inline with `CustomReviewRule`
- **Review Reason Logging** — See exactly why `maybeRequestReview()` returned `false`
- **Event Tracking** — Built-in persistent event system with per-event thresholds
- **Automatic Counters** — Opt-in tracking for launches, sessions, and usage time
- **Configurable Cooldowns** — Prevent over-requesting after reviews and store redirects
- **Debug Mode** — Full diagnostics screen (`ReviewDebugScreen`)
- **Statistics API** — Read all counters, dates, and eligibility state
- **Reset Utilities** — Reset counters for testing
- **Privacy-First** — Fully offline, no analytics, no cloud, no network requests
- **MVVM Architecture** — Clean models, services, rules, and ViewModel separation
- **Pluggable Storage** — Default `SharedPreferencesStorage` or bring your own via `ReviewStorage` interface
- **Ephemeral Mode** — Use `InMemoryStorage` for testing or lightweight usage

## Installation

Add to your `pubspec.yaml`:

```yaml
dependencies:
  in_app_review_kit: ^1.0.0
```

Then run:

```bash
flutter pub get
```

## Quick Start

```dart
import 'package:in_app_review_kit/in_app_review_kit.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 1. Build your config — only what you set is enforced
  final config = ReviewConfig.builder()
      .launches(min: 5)
      .daysSinceInstall(7)
      .sessions(3)
      .cooldown(daysAfterReview: 60, onePerSession: true)
      .autoTrack(launches: true, sessions: true, usageTime: true)
      .build();

  // 2. Choose your rules + add custom ones
  final rules = [
    LaunchRule(),
    TimeRule(),
    SessionRule(),
    CooldownRule(),
    CustomReviewRule(
      name: 'User Opt-In',
      onEvaluate: (_, __) => userHasOptedIn,
    ),
  ];

  // 3. Initialize (pass appVersion for update detection)
  await ReviewViewModel.instance.init(
    config: config,
    rules: rules,
    appVersion: '1.0.0',
  );

  // 4. Register callbacks
  ReviewViewModel.instance.on(
    callback: ReviewKitCallback.ineligible,
    handler: (reason) => print('Not eligible: $reason'),
  );

  // 5. Request review (only if all rules pass)
  await ReviewViewModel.instance.maybeRequestReview();
}
```

## Configuration Builder

Every condition is **opt-in**. Only what you explicitly set is enforced.

```dart
final config = ReviewConfig.builder()
    .launches(min: 3, max: 10)        // app launch bounds
    .daysSinceInstall(7)               // min days since install
    .daysSinceFirstLaunch(3)           // min days since first open
    .daysSinceLastReview(30)           // min days between reviews
    .daysSinceLastUpdate(1)            // min days after update
    .sessions(3)                       // min sessions
    .usageTime(600)                    // min total usage (seconds)
    .cooldown(                         // cooldown settings
      daysAfterReview: 60,
      daysAfterStoreRedirect: 7,
      onePerSession: true,
    )
    .event('purchase_made', threshold: 3)   // per-event thresholds
    .autoTrack(launches: true, sessions: true, usageTime: true)
    .debug(true)
    .build();
```

## Built-in Rules

| Rule | Class | What it checks |
|------|-------|----------------|
| Launch Count | `LaunchRule` | `minLaunches` / `maxLaunches` |
| Time Conditions | `TimeRule` | Days since install, first launch, last review, last update |
| Session Conditions | `SessionRule` | Minimum sessions and total usage time |
| Custom Events | `EventRule` | Minimum counts for named events |
| Cooldown | `CooldownRule` | Post-review and post-redirect cooldown periods |

## Custom Rules

Use `CustomReviewRule` for app-specific conditions:

```dart
CustomReviewRule(
  name: 'Network Check',
  onEvaluate: (_, __) => connectivity.isConnected,
  onFailureReason: (_, __) => 'No network connection',
)
```

## Callbacks

```dart
ReviewViewModel.instance.on(
  callback: ReviewKitCallback.reviewRequested,
  handler: (_) => print('Review shown'),
);

ReviewViewModel.instance.on(
  callback: ReviewKitCallback.ineligible,
  handler: (reason) => print('Not eligible:\n$reason'),
);

ReviewViewModel.instance.on(
  callback: ReviewKitCallback.reviewUnavailable,
  handler: (_) => print('API not available'),
);
```

## Event Tracking

```dart
await ReviewViewModel.instance.trackEvent('purchase_made');
final events = ReviewViewModel.instance.getEvents();
```

## Sessions

```dart
await ReviewViewModel.instance.startSession();
// ... user uses the app ...
await ReviewViewModel.instance.endSession();
```

## Debug Screen

Navigate to the built-in debug screen during development:

```dart
Navigator.push(
  context,
  MaterialPageRoute(builder: (_) => const ReviewDebugScreen()),
);
```

Shows eligibility status, all counters, events, dates, and action buttons for resets.

## Statistics

```dart
final stats = ReviewViewModel.instance.getStatistics();
print('Launches: ${stats.launchCount}');
print('Sessions: ${stats.sessionCount}');
print('Eligible: ${stats.isEligible}');
```

## Resets

```dart
await ReviewViewModel.instance.resetAll();
await ReviewViewModel.instance.resetLaunches();
await ReviewViewModel.instance.resetSessions();
await ReviewViewModel.instance.resetEvents();
await ReviewViewModel.instance.resetCooldowns();
```

## Storage

ReviewKit uses a pluggable storage architecture via the `ReviewStorage` interface.

**`SharedPreferencesStorage`** (default) — Persistent on-device storage. Data survives app restarts. Recommended for production.

```dart
// Default — no configuration needed
await ReviewViewModel.instance.init(config: config, rules: rules);
```

**`InMemoryStorage`** — Ephemeral storage. All data is lost when the process terminates. Great for testing or when you have your own persistence layer.

```dart
await ReviewViewModel.instance.init(
  config: config,
  rules: rules,
  storage: InMemoryStorage(),
);
```

**Custom storage** — Implement `ReviewStorage` for a completely custom backend.

```dart
class MyStorage implements ReviewStorage {
  // implement all methods
}
```

## Dependencies

Minimal footprint — only what's needed:
- `in_app_review` — Native Google Play & App Store review API
- `shared_preferences` — Local persistent storage (swappable)
- **Zero analytics, zero network, zero cloud**

## Architecture

```
lib/
├── in_app_review_kit.dart          # Barrel exports
├── src/
│   ├── models/                     # Data models (immutable config, eligibility, etc.)
│   ├── services/                   # Platform detection, storage, native API wrapper
│   ├── rules/                      # Eligibility rules (abstract + built-in + custom)
│   ├── viewmodels/                 # ReviewViewModel (ChangeNotifier singleton)
│   └── views/                      # ReviewDebugScreen
```

## Privacy

- ✅ Fully offline
- ✅ No analytics or telemetry
- ✅ No cloud storage
- ✅ No network requests
- ✅ No user accounts
- ✅ Local storage only (SharedPreferences)

## Platform Support

- Android (Google Play Store, API 21+)
- iOS (App Store, iOS 10.3+)

## License

MIT
