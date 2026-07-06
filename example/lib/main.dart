/// ReviewKit Example App
///
/// Demonstrates complete setup and usage of the in_app_review_kit package.
/// Shows fluent builder config, rules, event tracking, session management,
/// debug screen, and custom storage options in action.
library;

import 'package:flutter/material.dart';
import 'package:in_app_review_kit/in_app_review_kit.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // --- 1. Build your configuration ---
  // Only conditions you explicitly set are enforced.
  final config = ReviewConfig.builder()
      .launches(min: 3)
      .daysSinceInstall(1)
      .sessions(2)
      .cooldown(daysAfterReview: 7, onePerSession: true)
      .event('task_completed', threshold: 2)
      .event('purchase_made', threshold: 1)
      .autoTrack(launches: true, sessions: true, usageTime: true)
      .debug(true)
      .build();

  // --- 2. Choose your rules ---
  // Built-in rules + custom rules with inline callbacks.
  final rules = [
    LaunchRule(),
    TimeRule(),
    SessionRule(),
    EventRule(),
    CooldownRule(),
    CustomReviewRule(
      name: 'Has Network',
      onEvaluate: (_, __) => true,
      reason: (_, __) => 'No network connection',
    ),
  ];

  // --- 3. Initialize ReviewViewModel ---
  // Pass appVersion to auto-detect updates for time-based rules.
  // Pass InMemoryStorage for ephemeral storage (data lost on restart).
  // By default uses SharedPreferencesStorage for persistent storage.
  await ReviewViewModel.instance.init(
    config: config,
    rules: rules,
    appVersion: '1.0.0',
    // storage: InMemoryStorage(),  // uncomment for ephemeral mode
  );

  // --- 4. Register callbacks ---
  ReviewViewModel.instance.on(
    callback: ReviewKitCallback.reviewRequested,
    handler: (_) => debugPrint('✅ Review was shown to the user'),
  );
  ReviewViewModel.instance.on(
    callback: ReviewKitCallback.ineligible,
    handler: (reason) => debugPrint('❌ Not eligible:\n$reason'),
  );
  ReviewViewModel.instance.on(
    callback: ReviewKitCallback.reviewUnavailable,
    handler: (_) => debugPrint('⚠️  Native review API unavailable'),
  );

  runApp(const ReviewKitExampleApp());
}

class ReviewKitExampleApp extends StatelessWidget {
  const ReviewKitExampleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ReviewKit Example',
      theme: ThemeData(
        colorSchemeSeed: Colors.blue,
        useMaterial3: true,
      ),
      home: const HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final _vm = ReviewViewModel.instance;
  String _status = 'Initializing...';
  int _events = 0;

  @override
  void initState() {
    super.initState();
    _vm.addListener(_onVmChange);
    _vm.startSession();
    _vm.trackEvent('app_opened');
    _updateStatus();
  }

  @override
  void dispose() {
    _vm.endSession();
    _vm.removeListener(_onVmChange);
    super.dispose();
  }

  void _onVmChange() => _updateStatus();

  void _updateStatus() {
    final reason = _vm.getEligibilityReason();
    setState(() {
      _status = reason.toString();
      _events = _vm.getEvents().values.fold(0, (a, b) => a + b);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ReviewKit Example'),
        actions: [
          IconButton(
            icon: const Icon(Icons.bug_report),
            tooltip: 'Debug Screen',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const ReviewDebugScreen(),
              ),
            ),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    const Text(
                      'Eligibility Status',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        _status,
                        style: const TextStyle(
                          fontSize: 13,
                          fontFamily: 'monospace',
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                _buildButton(
                  'Track Event',
                  Icons.event,
                  () => _vm
                      .trackEvent('task_completed')
                      .then((_) => _updateStatus()),
                ),
                _buildButton(
                  'Make Purchase',
                  Icons.shopping_cart,
                  () => _vm
                      .trackEvent('purchase_made')
                      .then((_) => _updateStatus()),
                ),
                _buildButton(
                  'Request Review',
                  Icons.star,
                  () async {
                    final messenger = ScaffoldMessenger.of(context);
                    final result = await _vm.maybeRequestReview();
                    if (!mounted) return;
                    messenger.showSnackBar(
                      SnackBar(
                        content: Text(
                          result
                              ? 'Review requested!'
                              : 'Review not available',
                        ),
                      ),
                    );
                  },
                ),
                _buildButton(
                  'Check Eligibility',
                  Icons.checklist,
                  () => _updateStatus(),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildStat('Events', '$_events'),
                    _buildStat(
                        'Launches', '${_vm.getStatistics().launchCount}'),
                    _buildStat(
                        'Sessions', '${_vm.getStatistics().sessionCount}'),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildButton(String label, IconData icon, VoidCallback onPressed) {
    return ActionChip(
      avatar: Icon(icon),
      label: Text(label),
      onPressed: onPressed,
    );
  }

  Widget _buildStat(String label, String value) {
    return Column(
      children: [
        Text(value,
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
        Text(label, style: const TextStyle(color: Colors.grey)),
      ],
    );
  }
}
