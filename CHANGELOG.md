## 1.0.0

### Initial Release

ReviewKit is a complete Flutter solution for intelligently managing Google Play and App Store in-app reviews. Built with MVVM architecture and zero hardcoded defaults — you control everything.

#### Features

- **Native Review API** — Google Play & App Store integration with graceful error handling
- **Fluent Builder Config** — Explicitly set every condition via `ReviewConfig.builder()`. Nothing is enforced unless you set it
- **Smart Eligibility Engine** — Launch count, time conditions, session requirements, event thresholds, and cooldown rules
- **Custom Rule Callbacks** — Add your own eligibility conditions inline with `CustomReviewRule`
- **Review Reason Logging** — See exactly why `maybeRequestReview()` returned false
- **Event Tracking** — Built-in persistent event system with per-event thresholds
- **Automatic Counters** — Opt-in tracking of launches, sessions, and usage time
- **Configurable Cooldowns** — Prevent over-requesting with post-review and post-redirect cooldowns
- **Debug Mode** — Diagnostics screen (`ReviewDebugScreen`) showing all state
- **Statistics API** — Full read access to counters, dates, and eligibility
- **Reset Utilities** — Reset all or individual counters for testing
- **Pluggable Storage** — `ReviewStorage` interface with `SharedPreferencesStorage` (default), `InMemoryStorage`, or custom implementations
- **Privacy-First** — Fully offline. No analytics, no cloud storage, no network requests. Zero unnecessary dependencies
- **MVVM Architecture** — Clean separation of models, services, rules, and ViewModel
- **Platform Support** — Android and iOS only
