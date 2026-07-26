import 'package:flutter/material.dart';
import 'package:in_app_review_kit/in_app_review_kit.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final config = ReviewConfig.builder()
      .launches(min: 3)
      .daysSinceInstall(1)
      .sessions(2)
      .cooldown(daysAfterReview: 7, onePerSession: true)
      .event('task_completed', threshold: 2)
      .autoTrack(launches: true, sessions: true, usageTime: true)
      .debug(true)
      .build();

  await ReviewViewModel.instance.init(
    config: config,
    appVersion: '1.0.0',
  );

  runApp(const ReviewKitExample());
}

class ReviewKitExample extends StatelessWidget {
  const ReviewKitExample({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ReviewKit',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorSchemeSeed: Colors.indigo,
        useMaterial3: true,
      ),
      home: const ReviewDemo(),
    );
  }
}

class ReviewDemo extends StatefulWidget {
  const ReviewDemo({super.key});

  @override
  State<ReviewDemo> createState() => _ReviewDemoState();
}

class _ReviewDemoState extends State<ReviewDemo> {
  final _vm = ReviewViewModel.instance;
  String _status = 'Initializing...';

  @override
  void initState() {
    super.initState();
    _vm.startSession();
    _vm.trackEvent('task_completed');
    _updateStatus();
  }

  @override
  void dispose() {
    _vm.endSession();
    super.dispose();
  }

  void _updateStatus() {
    setState(() {
      _status = _vm.getEligibilityReason().toString();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('ReviewKit'),
        actions: [
          IconButton(
            icon: const Icon(Icons.bug_report),
            tooltip: 'Debug',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const ReviewDebugScreen()),
            ),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Text('Eligibility',
                        style: theme.textTheme.titleMedium),
                    const SizedBox(height: 12),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        _status,
                        style: const TextStyle(fontSize: 13),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                ActionChip(
                  avatar: const Icon(Icons.event),
                  label: const Text('Track Event'),
                  onPressed: () => _vm
                      .trackEvent('task_completed')
                      .then((_) => _updateStatus()),
                ),
                ActionChip(
                  avatar: const Icon(Icons.star),
                  label: const Text('Request Review'),
                  onPressed: () async {
                    final messenger = ScaffoldMessenger.of(context);
                    final result = await _vm.maybeRequestReview();
                    if (!mounted) return;
                    messenger.showSnackBar(
                      SnackBar(
                        content: Text(
                          result ? 'Review requested!' : 'Not available',
                        ),
                      ),
                    );
                    _updateStatus();
                  },
                ),
                ActionChip(
                  avatar: const Icon(Icons.refresh),
                  label: const Text('Refresh'),
                  onPressed: _updateStatus,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
