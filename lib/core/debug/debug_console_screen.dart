import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../connection/app_connection_monitor.dart';
import '../connection/app_connection_status.dart';
import '../logging/app_logger.dart';
import '../socket/socket_provider.dart';
import '../socket/traccar_socket_service.dart';
import 'debug_log_entry.dart';
import 'debug_log_store.dart';

/// Internal developer screen: comprehensive observability console.
/// Route is registered only for non-release builds.
class DebugConsoleScreen extends ConsumerStatefulWidget {
  const DebugConsoleScreen({super.key});

  @override
  ConsumerState<DebugConsoleScreen> createState() => _DebugConsoleScreenState();
}

class _DebugConsoleScreenState extends ConsumerState<DebugConsoleScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _logFilter = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 7, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ELMOGPS Debug Console'),
        actions: [
          IconButton(
            tooltip: 'Copy all logs',
            icon: const Icon(Icons.copy_rounded),
            onPressed: _copyAllLogs,
          ),
          IconButton(
            tooltip: 'Clear',
            icon: const Icon(Icons.delete_outline_rounded),
            onPressed: () {
              DebugLogStore.instance.clear();
              AppLogger.navigation('Debug console: logs cleared');
            },
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabAlignment: TabAlignment.start,
          labelStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
          unselectedLabelStyle: const TextStyle(fontSize: 11),
          tabs: const [
            Tab(text: 'Overview'),
            Tab(text: 'Navigation'),
            Tab(text: 'API'),
            Tab(text: 'WebSocket'),
            Tab(text: 'FCM'),
            Tab(text: 'Alerts'),
            Tab(text: 'Performance'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _OverviewTab(),
          _NavigationTab(),
          _ApiTab(filter: _logFilter, onFilterChanged: (v) => setState(() => _logFilter = v)),
          _WebSocketTab(),
          _FcmTab(),
          _AlertsTab(),
          _PerformanceTab(),
        ],
      ),
    );
  }

  Future<void> _copyAllLogs() async {
    final text = DebugLogStore.instance.entries
        .map((e) => e.line)
        .join('\n');
    await Clipboard.setData(ClipboardData(text: text));
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Logs copied')),
      );
    }
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// TAB A: Overview
// ═══════════════════════════════════════════════════════════════════════════════

class _OverviewTab extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final snapshot = ref.watch(appConnectionMonitorProvider);
    final store = DebugLogStore.instance;

    return ListenableBuilder(
      listenable: store,
      builder: (context, _) {
        return ListView(
          padding: const EdgeInsets.all(12),
          children: [
            _StatusCard(
              title: 'Connection Status',
              items: [
                _StatusItem('API', _appStatusLabel(snapshot.appStatus), _appStatusColor(snapshot.appStatus)),
                _StatusItem('WebSocket', _liveStatusLabel(snapshot.liveStatus), _liveStatusColor(snapshot.liveStatus)),
                _StatusItem('FCM', store.fcmTokenRegistered ? 'Ready' : 'Not registered', store.fcmTokenRegistered ? Colors.green : Colors.orange),
                _StatusItem('Alerts', 'Loaded: ${store.alertsLoadedCount} / Unread: ${store.alertsUnreadCount}', Colors.blue),
              ],
            ),
            const SizedBox(height: 8),
            _StatusCard(
              title: 'Navigation',
              items: [
                _StatusItem('Current Route', store.currentRoute ?? '—', null),
                _StatusItem('Previous Route', store.previousRoute ?? '—', null),
              ],
            ),
            const SizedBox(height: 8),
            _StatusCard(
              title: 'Last Error',
              items: [
                _StatusItem('Error', _lastError(store), Colors.red),
              ],
            ),
          ],
        );
      },
    );
  }

  String _lastError(DebugLogStore store) {
    final errors = store.entries.where((e) => e.isError).toList();
    if (errors.isEmpty) return 'None';
    return errors.last.message.length > 100
        ? '${errors.last.message.substring(0, 100)}…'
        : errors.last.message;
  }

  String _appStatusLabel(AppConnectionStatus s) => switch (s) {
        AppConnectionStatus.checking => 'Checking',
        AppConnectionStatus.online => 'Online',
        AppConnectionStatus.offline => 'Offline',
        AppConnectionStatus.serverUnavailable => 'Server Unavailable',
        AppConnectionStatus.unauthorized => 'Unauthorized',
        AppConnectionStatus.error => 'Error',
      };

  Color _appStatusColor(AppConnectionStatus s) => switch (s) {
        AppConnectionStatus.online => Colors.green,
        AppConnectionStatus.offline => Colors.red,
        AppConnectionStatus.serverUnavailable => Colors.orange,
        AppConnectionStatus.unauthorized => Colors.red,
        AppConnectionStatus.checking => Colors.grey,
        AppConnectionStatus.error => Colors.red,
      };

  String _liveStatusLabel(LiveSyncStatus s) => switch (s) {
        LiveSyncStatus.idle => 'Idle',
        LiveSyncStatus.connected => 'Connected',
        LiveSyncStatus.reconnecting => 'Reconnecting',
        LiveSyncStatus.degraded => 'Degraded',
        LiveSyncStatus.disconnected => 'Disconnected',
      };

  Color _liveStatusColor(LiveSyncStatus s) => switch (s) {
        LiveSyncStatus.connected => Colors.green,
        LiveSyncStatus.reconnecting => Colors.orange,
        LiveSyncStatus.degraded => Colors.amber,
        LiveSyncStatus.disconnected => Colors.red,
        LiveSyncStatus.idle => Colors.grey,
      };
}

// ═══════════════════════════════════════════════════════════════════════════════
// TAB B: Navigation
// ═══════════════════════════════════════════════════════════════════════════════

class _NavigationTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: DebugLogStore.instance,
      builder: (context, _) {
        final store = DebugLogStore.instance;
        return ListView(
          padding: const EdgeInsets.all(12),
          children: [
            _InfoRow('Current Route', store.currentRoute ?? '—'),
            _InfoRow('Previous Route', store.previousRoute ?? '—'),
            const Divider(),
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: Text('Last 10 Routes', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
            ),
            if (store.navigationHistory.isEmpty)
              const Text('No navigation history yet.', style: TextStyle(fontSize: 12, color: Colors.grey))
            else
              ...store.navigationHistory.map((entry) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2),
                    child: Text(entry, style: const TextStyle(fontFamily: 'monospace', fontSize: 11)),
                  )),
          ],
        );
      },
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// TAB C: API
// ═══════════════════════════════════════════════════════════════════════════════

class _ApiTab extends StatelessWidget {
  const _ApiTab({required this.filter, required this.onFilterChanged});
  final String filter;
  final ValueChanged<String> onFilterChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
          child: TextField(
            decoration: const InputDecoration(
              hintText: 'Filter API logs…',
              isDense: true,
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.search, size: 18),
            ),
            style: const TextStyle(fontSize: 12),
            onChanged: onFilterChanged,
          ),
        ),
        const Divider(height: 1),
        Expanded(
          child: ListenableBuilder(
            listenable: DebugLogStore.instance,
            builder: (context, _) {
              var items = DebugLogStore.instance.apiEntries.reversed.toList();
              if (filter.isNotEmpty) {
                final f = filter.toLowerCase();
                items = items.where((e) => e.message.toLowerCase().contains(f)).toList();
              }
              if (items.isEmpty) {
                return const Center(child: Text('No API calls recorded.'));
              }
              return ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                itemCount: items.length,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (context, i) {
                  final e = items[i];
                  final perf = e.performanceLevel;
                  final color = switch (perf) {
                    PerformanceLevel.criticalSlow => Colors.red,
                    PerformanceLevel.slow => Colors.orange,
                    PerformanceLevel.medium => Colors.amber.shade700,
                    _ => e.isError ? Theme.of(context).colorScheme.error : null,
                  };
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 3),
                    child: SelectableText(
                      e.line,
                      style: TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 10.5,
                        height: 1.3,
                        color: color ?? Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// TAB D: WebSocket
// ═══════════════════════════════════════════════════════════════════════════════

class _WebSocketTab extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final socketService = ref.watch(traccarSocketServiceProvider);
    final diag = socketService.diagnostics;

    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        _StatusCard(
          title: 'WebSocket State',
          items: [
            _StatusItem('Status', diag.statusLabel, _wsColor(diag.connectionState)),
            _StatusItem('Endpoint', diag.endpoint.isNotEmpty ? diag.endpoint : '—', null),
            _StatusItem('Auth Mode', diag.authMode, null),
            _StatusItem('Cookie Present', diag.cookiePresent ? 'Yes' : 'No', null),
            _StatusItem('Last Error', diag.lastError ?? 'None', diag.lastError != null ? Colors.red : Colors.green),
            _StatusItem('HTTP Status', diag.lastHttpStatus?.toString() ?? '—', null),
            _StatusItem('Retry Count', '${diag.retryAttempt}/${diag.maxRetries}', null),
            _StatusItem('Next Retry', diag.nextRetrySeconds > 0 ? '${diag.nextRetrySeconds}s' : '—', null),
            _StatusItem('Last Connected', _formatDateTime(diag.lastConnectedAt), null),
            _StatusItem('Last Error At', _formatDateTime(diag.lastErrorAt), null),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () => _reconnect(context, socketService),
                icon: const Icon(Icons.refresh, size: 16),
                label: const Text('Reconnect Now', style: TextStyle(fontSize: 12)),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => _testSession(context, socketService),
                icon: const Icon(Icons.verified_user, size: 16),
                label: const Text('Test Session', style: TextStyle(fontSize: 12)),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        const Text('WebSocket Logs', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
        const SizedBox(height: 4),
        ListenableBuilder(
          listenable: DebugLogStore.instance,
          builder: (context, _) {
            final wsLogs = DebugLogStore.instance.entries
                .where((e) => e.category == DebugLogCategory.websocket)
                .toList()
                .reversed
                .take(20)
                .toList();
            if (wsLogs.isEmpty) {
              return const Text('No WebSocket logs.', style: TextStyle(fontSize: 12, color: Colors.grey));
            }
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: wsLogs.map((e) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 1),
                    child: SelectableText(
                      e.line,
                      style: TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 10,
                        color: e.isError ? Colors.red : null,
                      ),
                    ),
                  )).toList(),
            );
          },
        ),
      ],
    );
  }

  Color _wsColor(String state) => switch (state) {
        'connected' => Colors.green,
        'connecting' => Colors.blue,
        'reconnecting' => Colors.orange,
        'failed' => Colors.red,
        _ => Colors.grey,
      };

  String _formatDateTime(DateTime? dt) {
    if (dt == null) return '—';
    return '${dt.hour.toString().padLeft(2, '0')}:'
        '${dt.minute.toString().padLeft(2, '0')}:'
        '${dt.second.toString().padLeft(2, '0')}';
  }

  void _reconnect(BuildContext context, TraccarSocketService svc) {
    svc.reconnectNow();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Reconnecting…')),
    );
  }

  Future<void> _testSession(BuildContext context, TraccarSocketService svc) async {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Testing session…')),
    );
    final result = await svc.testSession();
    if (context.mounted) {
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('Session Test Result'),
          content: Text(result['result'] as String? ?? 'Unknown'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK'),
            ),
          ],
        ),
      );
    }
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// TAB E: FCM
// ═══════════════════════════════════════════════════════════════════════════════

class _FcmTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: DebugLogStore.instance,
      builder: (context, _) {
        final store = DebugLogStore.instance;
        return ListView(
          padding: const EdgeInsets.all(12),
          children: [
            _StatusCard(
              title: 'FCM State',
              items: [
                _StatusItem('Permission', store.fcmPermissionStatus, null),
                _StatusItem('Token Registered', store.fcmTokenRegistered ? 'Yes' : 'No',
                    store.fcmTokenRegistered ? Colors.green : Colors.orange),
                _StatusItem('Last Message Type', store.fcmLastMessageType ?? '—', null),
                _StatusItem('Last Alert ID', store.fcmLastAlertId ?? '—', null),
                _StatusItem('Last Refresh Result', store.fcmLastRefreshResult ?? '—', null),
              ],
            ),
            const SizedBox(height: 12),
            const Text('FCM Logs', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
            const SizedBox(height: 4),
            ...store.entries
                .where((e) => e.category == DebugLogCategory.fcm)
                .toList()
                .reversed
                .take(15)
                .map((e) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 1),
                      child: SelectableText(
                        e.line,
                        style: TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 10,
                          color: e.isError ? Colors.red : null,
                        ),
                      ),
                    )),
          ],
        );
      },
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// TAB F: Alerts
// ═══════════════════════════════════════════════════════════════════════════════

class _AlertsTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: DebugLogStore.instance,
      builder: (context, _) {
        final store = DebugLogStore.instance;
        return ListView(
          padding: const EdgeInsets.all(12),
          children: [
            _StatusCard(
              title: 'Alerts State',
              items: [
                _StatusItem('Loaded Count', '${store.alertsLoadedCount}', null),
                _StatusItem('Unread Count', '${store.alertsUnreadCount}', null),
                _StatusItem('Last Refresh Source', store.alertsLastRefreshSource ?? '—', null),
                _StatusItem('Last Refresh Duration', store.alertsLastRefreshDurationMs != null ? '${store.alertsLastRefreshDurationMs}ms' : '—', null),
                _StatusItem('Last FCM Alert ID', store.alertsLastFcmAlertId ?? '—', null),
              ],
            ),
            const SizedBox(height: 12),
            const Text('Alerts Logs', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
            const SizedBox(height: 4),
            ...store.entries
                .where((e) => e.category == DebugLogCategory.alerts)
                .toList()
                .reversed
                .take(15)
                .map((e) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 1),
                      child: SelectableText(
                        e.line,
                        style: TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 10,
                          color: e.isError ? Colors.red : null,
                        ),
                      ),
                    )),
          ],
        );
      },
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// TAB G: Performance
// ═══════════════════════════════════════════════════════════════════════════════

class _PerformanceTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: DebugLogStore.instance,
      builder: (context, _) {
        final store = DebugLogStore.instance;
        final slowReqs = store.slowRequests.reversed.toList();
        final criticalReqs = slowReqs.where((e) => e.performanceLevel == PerformanceLevel.criticalSlow).toList();

        return ListView(
          padding: const EdgeInsets.all(12),
          children: [
            _StatusCard(
              title: 'Dashboard Performance',
              items: [
                _StatusItem('Last Refresh Duration', store.dashboardRefreshDurationMs != null ? '${store.dashboardRefreshDurationMs}ms' : '—', null),
                _StatusItem('Duplicate Warnings', '${store.duplicateRequestWarnings}', store.duplicateRequestWarnings > 0 ? Colors.orange : Colors.green),
              ],
            ),
            const SizedBox(height: 12),
            if (criticalReqs.isNotEmpty) ...[
              const Text('Critical Slow Requests (>8s)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.red)),
              const SizedBox(height: 4),
              ...criticalReqs.take(10).map((e) => _SlowRequestTile(entry: e)),
              const Divider(),
            ],
            const Text('Comparison logs', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
            const SizedBox(height: 4),
            if (store.comparisonEntries.isEmpty)
              const Text(
                'No comparison logs yet. Open vehicle comparison from the map picker.',
                style: TextStyle(fontSize: 12, color: Colors.grey),
              )
            else
              ...store.comparisonEntries.reversed.take(40).map(
                    (e) => _SlowRequestTile(entry: e),
                  ),
            const Divider(),
            const Text('Slow Requests (>3s)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
            const SizedBox(height: 4),
            if (slowReqs.isEmpty)
              const Text('No slow requests recorded.', style: TextStyle(fontSize: 12, color: Colors.grey))
            else
              ...slowReqs.take(20).map((e) => _SlowRequestTile(entry: e)),
          ],
        );
      },
    );
  }
}

class _SlowRequestTile extends StatelessWidget {
  const _SlowRequestTile({required this.entry});
  final DebugLogEntry entry;

  @override
  Widget build(BuildContext context) {
    final perf = entry.performanceLevel;
    final color = switch (perf) {
      PerformanceLevel.criticalSlow => Colors.red,
      PerformanceLevel.slow => Colors.orange,
      PerformanceLevel.medium => Colors.amber.shade700,
      _ => null,
    };
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
            decoration: BoxDecoration(
              color: color?.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(3),
            ),
            child: Text(
              '${entry.durationMs}ms',
              style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: color),
            ),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: SelectableText(
              entry.message,
              style: const TextStyle(fontFamily: 'monospace', fontSize: 10),
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// Shared UI Components
// ═══════════════════════════════════════════════════════════════════════════════

class _StatusCard extends StatelessWidget {
  const _StatusCard({required this.title, required this.items});
  final String title;
  final List<_StatusItem> items;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
            const SizedBox(height: 6),
            ...items.map((item) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: Row(
                    children: [
                      if (item.color != null)
                        Container(
                          width: 8,
                          height: 8,
                          margin: const EdgeInsets.only(right: 6),
                          decoration: BoxDecoration(
                            color: item.color,
                            shape: BoxShape.circle,
                          ),
                        ),
                      SizedBox(
                        width: 120,
                        child: Text(item.label, style: const TextStyle(fontSize: 11, color: Colors.grey)),
                      ),
                      Expanded(
                        child: Text(
                          item.value,
                          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                )),
          ],
        ),
      ),
    );
  }
}

class _StatusItem {
  const _StatusItem(this.label, this.value, this.color);
  final String label;
  final String value;
  final Color? color;
}

class _InfoRow extends StatelessWidget {
  const _InfoRow(this.label, this.value);
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(
            width: 120,
            child: Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
          ),
          Expanded(
            child: Text(value, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, fontFamily: 'monospace')),
          ),
        ],
      ),
    );
  }
}
