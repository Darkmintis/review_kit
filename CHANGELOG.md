## 1.0.0

### Initial Release

ReviewKit (`in_app_review_kit`) — intelligently manage Google Play and App Store
in-app reviews with fluent eligibility rules and zero hardcoded defaults.

#### Features

- Native review API integration (Google Play & App Store)
- Fluent `ReviewConfig.builder()` — only set conditions are enforced
- Built-in rules: launches, time, sessions, events, cooldowns
- `defaultReviewRules()` when you omit the `rules` argument
- Custom inline rules via `CustomReviewRule`
- Diagnostics via `getEligibilityReason()` / callbacks
- Event tracking, optional auto launch/session/usage tracking
- `ReviewDebugScreen` and statistics API
- Pluggable storage (`SharedPreferencesStorage`, `InMemoryStorage`)
- Privacy-first: offline, no analytics

#### Notes

- `oneRequestPerSession` is **in-memory only** (resets on each app start)
- `maybeRequestReview()` returning `true` means the OS API was invoked; the
  store may still suppress the dialog due to quotas
