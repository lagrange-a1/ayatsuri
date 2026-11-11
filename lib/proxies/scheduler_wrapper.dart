// lib/proxies/scheduler_wrapper.dart
import 'dart:async';
import 'package:ayatsuri/scheduler/lib.dart';

/// Scheduler wrapper for Ayatsuri proxy scheduling.
///
/// This class provides a simple interface to interact with the Rust scheduler
/// and maintain smoothed latency metrics for each proxy.
class SchedulerWrapper {
  // Ensure the Rust library is initialized exactly once.
  static Future<void>? _initialization;
  static Scheduler? _scheduler;

  SchedulerWrapper();

  /// Initialize the Rust scheduler (once).
  Future<void> _ensureRustInit() async {
    if (_scheduler != null) return;
    if (_initialization != null) {
      await _initialization;
      return;
    }
    _initialization = Future.sync(() async {
      await schedulerLibInit();
      _scheduler = await Scheduler.newInstance();
    });
    await _initialization;
  }

  // EMA smoothing factor (default 0.2)
  static const double _defaultEmaAlpha = 0.2;

  final Map<String, double> _smoothedLatencies = {};
  final Map<String, BigInt> _proxyIds = {};
  int _nextId = 0;

  /// Update the latency for a proxy, maintaining EMA and adding task to scheduler.
  Future<void> updateLatency(String proxy, int latency) async {
    await _ensureRustInit();
    double smoothed;
    if (_smoothedLatencies.containsKey(proxy)) {
      final old = _smoothedLatencies[proxy]!;
      smoothed = _defaultEmaAlpha * latency + (1 - _defaultEmaAlpha) * old;
    } else {
      smoothed = latency.toDouble();
    }
    _smoothedLatencies[proxy] = smoothed;

    if (!_proxyIds.containsKey(proxy)) {
      _proxyIds[proxy] = BigInt.from(_nextId++);
    }
    final id = _proxyIds[proxy]!;

    await _scheduler!.addTask(
      task: Task(id: id, latency: BigInt.from(smoothed.round())),
    );
  }

  /// Get the best proxy according to the scheduler.
  Future<String?> getBestProxy() async {
    await _ensureRustInit();
    final task = await _scheduler!.nextTask();
    if (task == null) return null;
    for (final entry in _proxyIds.entries) {
      if (entry.value == task.id) return entry.key;
    }
    return null;
  }

  // Optionally, reset state
  void reset() {
    _smoothedLatencies.clear();
    _proxyIds.clear();
    _nextId = 0;
  }
}
