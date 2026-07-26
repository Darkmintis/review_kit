/// ReviewKit (`in_app_review_kit`) — smart in-app review management for Flutter.
///
/// ## Layout
///
/// ```
/// lib/
/// ├── in_app_review_kit.dart     # Public barrel (import this)
/// └── src/
///     ├── models/                # Immutable config & result types
///     ├── rules/                 # Eligibility rules + RuleEngine
///     ├── services/              # Storage, platform, native API, trackers
///     ├── viewmodels/            # ReviewViewModel orchestrator
///     └── views/                 # ReviewDebugScreen
/// ```
///
/// Import only the barrel — never import `src/` paths from app code.
library;

// Models
export 'src/models/review_config.dart';
export 'src/models/review_eligibility.dart';
export 'src/models/review_kit_callback.dart';
export 'src/models/review_reason.dart';
export 'src/models/review_statistics.dart';

// Storage
export 'src/services/review_storage.dart';
export 'src/services/in_memory_storage.dart';
export 'src/services/shared_preferences_storage.dart';

// Rules
export 'src/rules/review_rule.dart';
export 'src/rules/default_rules.dart';
export 'src/rules/launch_rule.dart';
export 'src/rules/time_rule.dart';
export 'src/rules/session_rule.dart';
export 'src/rules/event_rule.dart';
export 'src/rules/cooldown_rule.dart';

// ViewModel + debug UI
export 'src/viewmodels/review_viewmodel.dart';
export 'src/views/debug_screen.dart';
