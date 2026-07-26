import 'package:flutter/material.dart';
import '../viewmodels/review_viewmodel.dart';
import '../models/review_statistics.dart';

class ReviewDebugScreen extends StatefulWidget {
  const ReviewDebugScreen({super.key});

  @override
  State<ReviewDebugScreen> createState() => _ReviewDebugScreenState();
}

class _ReviewDebugScreenState extends State<ReviewDebugScreen> {
  final _vm = ReviewViewModel.instance;
  ReviewStatistics? _stats;
  String? _eligibilityReason;

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  void _refresh() {
    if (!_vm.initialized) {
      setState(() {
        _stats = null;
        _eligibilityReason = 'ReviewKit not initialized';
      });
      return;
    }
    setState(() {
      _eligibilityReason = _vm.getEligibilityReason().toString();
      _stats = _vm.getStatistics();
    });
  }

  Future<void> _runAction(Future<void> Function() action) async {
    try {
      await action();
    } catch (_) {}
    if (mounted) _refresh();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ReviewKit Debug'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refresh,
          ),
        ],
      ),
      body: _stats == null
          ? Center(
              child: Text(
                _eligibilityReason ?? 'Loading...',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            )
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _buildEligibilityCard(),
                const SizedBox(height: 16),
                _buildCountersCard(),
                const SizedBox(height: 16),
                _buildEventsCard(),
                const SizedBox(height: 16),
                _buildDatesCard(),
                const SizedBox(height: 16),
                _buildActionsCard(),
              ],
            ),
    );
  }

  Widget _buildEligibilityCard() {
    final isEligible = _vm.lastEligibility?.eligible ?? _stats!.isEligible;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Eligibility Status',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(
                  isEligible ? Icons.check_circle : Icons.cancel,
                  color: isEligible ? Colors.green : Colors.red,
                ),
                const SizedBox(width: 8),
                Text(
                  isEligible ? 'Eligible' : 'Not Eligible',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: isEligible ? Colors.green : Colors.red,
                  ),
                ),
              ],
            ),
            if (_vm.lastReason != null) ...[
              const SizedBox(height: 12),
              Text(
                'Reason: ${_vm.lastReason!.summary}',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              if (_vm.lastReason!.details.isNotEmpty) ...[
                const SizedBox(height: 4),
                ..._vm.lastReason!.details.map(
                  (d) => Text('  • $d', style: const TextStyle(fontSize: 12)),
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildCountersCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Counters', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            _buildStatRow('Launches', '${_stats!.launchCount}'),
            _buildStatRow('Sessions', '${_stats!.sessionCount}'),
            _buildStatRow(
              'Usage Time',
              '${(_stats!.usageDurationSeconds / 60).round()}m',
            ),
            _buildStatRow(
              'Cooldown',
              _stats!.cooldownActive
                  ? 'Active (${_stats!.cooldownRemainingDays}d remaining)'
                  : 'None',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEventsCard() {
    final events = _stats!.eventTotals;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Custom Events',
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            if (events.isEmpty)
              const Text('No events recorded',
                  style: TextStyle(color: Colors.grey))
            else
              ...events.entries.map(
                (e) => _buildStatRow(e.key, '${e.value}'),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildDatesCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Dates', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            _buildStatRow('Install Date', _fmtDate(_stats!.installDate)),
            _buildStatRow('First Launch', _fmtDate(_stats!.firstLaunchDate)),
            _buildStatRow(
              'Last Review Request',
              _fmtDate(_stats!.lastReviewRequestDate),
            ),
            _buildStatRow(
              'Last Store Redirect',
              _fmtDate(_stats!.lastStoreRedirectDate),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionsCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Actions', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ActionChip(
                  label: const Text('Reset All'),
                  onPressed: () => _runAction(_vm.resetAll),
                ),
                ActionChip(
                  label: const Text('Reset Launches'),
                  onPressed: () => _runAction(_vm.resetLaunches),
                ),
                ActionChip(
                  label: const Text('Reset Sessions'),
                  onPressed: () => _runAction(_vm.resetSessions),
                ),
                ActionChip(
                  label: const Text('Reset Events'),
                  onPressed: () => _runAction(_vm.resetEvents),
                ),
                ActionChip(
                  label: const Text('Reset Cooldowns'),
                  onPressed: () => _runAction(_vm.resetCooldowns),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 14)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  String _fmtDate(DateTime? date) {
    if (date == null) return 'N/A';
    return '${date.year}-${_pad(date.month)}-${_pad(date.day)}';
  }

  String _pad(int n) => n.toString().padLeft(2, '0');
}
