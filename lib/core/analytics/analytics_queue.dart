import 'dart:async';
import 'dart:convert';

import 'package:collection/collection.dart';
import 'package:iptv/core/analytics/analytics_event.dart';
import 'package:iptv/core/analytics/analytics_policy.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Bounded local queue for analytics events.
class AnalyticsQueue {
  AnalyticsQueue({SharedPreferences? prefs}) : _prefs = prefs;

  SharedPreferences? _prefs;
  static const _storageKey = 'hope_tv_analytics_queue_v1';

  final List<AnalyticsEvent> _memory = [];

  Future<void> init() async {
    _prefs ??= await SharedPreferences.getInstance();
    final raw = _prefs!.getString(_storageKey);
    if (raw == null || raw.isEmpty) return;
    try {
      final list = jsonDecode(raw) as List<dynamic>;
      for (final item in list) {
        if (item is! Map<String, dynamic>) continue;
        final name = item['eventName'] as String?;
        final eventId = item['eventId'] as String?;
        final occurredAt = item['occurredAt'] as String?;
        if (name == null || eventId == null || occurredAt == null) continue;
        final match = AnalyticsEventName.values
            .where((e) => e.value == name)
            .firstOrNull;
        if (match == null) continue;
        _memory.add(AnalyticsEvent(
          eventId: eventId,
          name: match,
          occurredAt: DateTime.parse(occurredAt).toUtc(),
          schemaVersion: item['schemaVersion'] as int? ?? 1,
          platform: item['platform'] as String?,
          appVersion: item['appVersion'] as String?,
          installationIdHash: item['installationIdHash'] as String?,
          properties: Map<String, Object?>.from(
            (item['properties'] as Map?)?.cast<String, Object?>() ?? {},
          ),
        ));
      }
    } catch (_) {
      await _prefs!.remove(_storageKey);
    }
  }

  Future<void> enqueue(AnalyticsEvent event) async {
    if (_memory.length >= AnalyticsPolicy.maxQueueSize) {
      _memory.removeAt(0);
    }
    _memory.add(event);
    await _persist();
  }

  List<AnalyticsEvent> drainBatch({int max = AnalyticsPolicy.maxBatchSize}) {
    if (_memory.isEmpty) return [];
    final count = max.clamp(1, _memory.length);
    final batch = _memory.sublist(0, count);
    _memory.removeRange(0, count);
    // ignore: unawaited_futures
    _persist();
    return batch;
  }

  int get length => _memory.length;

  Future<void> _persist() async {
    _prefs ??= await SharedPreferences.getInstance();
    final encoded = jsonEncode(_memory.map((e) => e.toJson()).toList());
    await _prefs!.setString(_storageKey, encoded);
  }
}