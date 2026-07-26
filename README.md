# ReviewKit (`in_app_review_kit`)

[![pub package](https://img.shields.io/pub/v/in_app_review_kit.svg)](https://pub.dev/packages/in_app_review_kit)
[![Flutter](https://img.shields.io/badge/Flutter-3.16%2B-blue)](https://flutter.dev)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)

Intelligently manage **Google Play** and **App Store** in-app reviews in Flutter.
Fluent eligibility rules, event tracking, cooldowns, and a debug screen — with
**zero hardcoded defaults**. You control every condition.

Published on pub.dev as [`in_app_review_kit`](https://pub.dev/packages/in_app_review_kit).

## Why ReviewKit?

Raw `requestReview()` calls get ignored by the OS when overused, annoy users,
and offer no insight into *why* a prompt was skipped. ReviewKit adds a small
eligibility layer so you prompt at the right moment — and can see exactly why
not when you don't.

## Features

- **Native Review API** — Google Play & App Store via `in_app_review`
- **Fluent builder** — Only conditions you set are enforced
- **Smart rules** — Launches, time, sessions, events, cooldowns
- **Custom rules** — Inline `CustomReviewRule` callbacks
- **Clear diagnostics** — Know why `maybeRequestReview()` returned `false`
- **Event tracking** — Persistent per-event thresholds
- **Auto tracking** — Optional launches, sessions, and usage time
- **Debug screen** — `ReviewDebugScreen` for development
- **Pluggable storage** — `SharedPreferences` (default) or `InMemoryStorage`
- **Privacy-first** — Fully offline, no analytics, no network

## Installation

```yaml
dependencies:
  in_app_review_kit: ^1.0.0
```

```bash
flutter pub get
```

## Quick Start

The shortest useful setup — omit `rules` and all built-in rules are applied
automatically (unset config fields are ignored):

```dart
import 'package:in_app_review_kit/in_app_review_kit.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await ReviewViewModel.instance.init(
    config: ReviewConfig.builder()
        .launches(min: 5)
        .daysSinceInstall(7)
        .sessions(3)
        .cooldown(daysAfterReview: 60, onePerSession: true)
        .autoTrack(launches: true, sessions: true, usageTime: true)
        .build(),
    appVersion: '1.0.0',
  );

  runApp(const MyApp());
}

// Later, at a natural moment (e.g. after a success screen):
await ReviewViewModel.instance.maybeRequestReview();
```

### With custom rules

```dart
await ReviewViewModel.instance.init(
  config: config,
  rules: [
    ...defaultReviewRules(),
    CustomReviewRule(
      name: 'User Opt-In',
      onEvaluate: (_, __) => userHasOptedIn,
      onFailureReason: (_, __) => 'User has not opted in',
    ),
  ],
  appVersion: '1.0.0',
);
```

## Configuration Builder

Every condition is **opt-in**. Only what you explicitly set is enforced.

```dart
final config = ReviewConfig.builder()
    .launches(min: 3, max: 10)
    .daysSinceInstall(7)
    .daysSinceFirstLaunch(3)
    .daysSinceLastReview(30)
    .daysSinceLastUpdate(1)
    .sessions(3)
    .usageTime(600) // seconds
    .cooldown(
      daysAfterReview: 60,
      daysAfterStoreRedirect: 7,
      onePerSession: true,
    )
    .event('purchase_made', threshold: 3)
    .autoTrack(launches: true, sessions: true, usageTime: true)
    .debug(true) // verbose debugPrint logs
    .build();
```

## Built-in Rules

| Rule | Class | Checks |
|------|-------|--------|
| Launch Count | `LaunchRule` | `minLaunches` / `maxLaunches` |
| Time | `TimeRule` | Days since install, first launch, last review, last update |
| Session | `SessionRule` | Min sessions and total usage time |
| Events | `EventRule` | Named event thresholds |
| Cooldown | `CooldownRule` | Post-review / post-redirect cooldowns, one-per-session |

When `rules` is omitted, all five are registered via `defaultReviewRules()`.

## Callbacks

```dart
ReviewViewModel.instance.on(
  callback: ReviewKitCallback.reviewRequested,
  handler: (_) => print('Review API invoked'),
);

ReviewViewModel.instance.on(
  callback: ReviewKitCallback.ineligible,
  handler: (reason) => print('Not eligible:\n$reason'),
);

ReviewViewModel.instance.on(
  callback: ReviewKitCallback.reviewUnavailable,
  handler: (_) => print('Native API not available'),
);
```

> **Note:** `reviewRequested` / a `true` return from `maybeRequestReview()` means
> the OS API was called. Google Play and the App Store may still suppress the
> dialog due to quotas.

## Events & Sessions

```dart
await ReviewViewModel.instance.trackEvent('purchase_made');

await ReviewViewModel.instance.startSession();
// ... user uses the app ...
await ReviewViewModel.instance.endSession();
```

## Debug Screen

```dart
Navigator.push(
  context,
  MaterialPageRoute(builder: (_) => const ReviewDebugScreen()),
);
```

## Statistics & Resets

```dart
final stats = ReviewViewModel.instance.getStatistics();
print('Eligible: ${stats.isEligible}');

await ReviewViewModel.instance.resetAll();
await ReviewViewModel.instance.resetCooldowns();
```

## Storage

**`SharedPreferencesStorage`** (default) — persists across restarts.

**`InMemoryStorage`** — ephemeral; great for tests:

```dart
await ReviewViewModel.instance.init(
  config: config,
  storage: InMemoryStorage(),
);
```

Implement `ReviewStorage` for a custom backend.

## Platform Support

| Platform | In-app review |
|----------|----------------|
| Android (API 21+) | Yes |
| iOS (10.3+) | Yes |
| Web / Desktop | Unsupported (safe to import; APIs no-op as unavailable) |

On iOS, pass your numeric App Store ID when opening the listing:

```dart
await ReviewViewModel.instance.openStoreListing(appStoreId: '123456789');
```

> **Note:** `onePerSession` is enforced in memory only and resets each app start.
> A `true` return from `maybeRequestReview()` means the OS API was called; the
> store may still suppress the dialog due to platform quotas.

## Example

See the [`example/`](example/) app for a full interactive demo.

## Architecture

```
lib/
├── in_app_review_kit.dart          # Public barrel — import only this
└── src/
    ├── models/                     # Config, eligibility, stats, callbacks
    ├── rules/                      # ReviewRule + built-ins + RuleEngine
    ├── services/                   # Storage, platform, native API, UsageTracker
    ├── viewmodels/                 # ReviewViewModel (orchestrator)
    └── views/                      # ReviewDebugScreen
```

Internal helpers (`CallbackDispatcher`, `UsageTracker`, `RuleEngine`,
`NativeReviewService`) stay in `src/` and are not part of the public API.

## Privacy

- Fully offline
- No analytics or telemetry
- No network requests from this package
- Local storage only (`SharedPreferences` by default)

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md).

## License

MIT
