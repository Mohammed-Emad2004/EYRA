import 'package:flutter/foundation.dart';

/// Lightweight, monotonic timing and frame telemetry accumulator for the
/// EYRA AI pipeline.
///
/// Tracks frame progression through the pipeline:
/// - [framesReceived]: every CameraImage delivered by the camera stream.
/// - [framesProcessed]: frames successfully converted into JPEG.
/// - [framesReplaced]: pending frames overwritten by newer frames while
///   the previous frame was in flight (Latest-Frame-Wins behavior).
/// - [framesDropped]: frames intentionally discarded (e.g. conversion failure,
///   HTTP error, timeout).
/// - [framesSent]: HTTP detection requests actually dispatched to the AI server.
/// - [framesCompleted]: HTTP detection requests that completed successfully.
///
/// High-resolution timing metrics ([conversionMs], [base64Ms], [httpMs],
/// [totalClientMs]) are aggregated and logged periodically with avg, min, max,
/// and p95 without polluting per-frame logs.
class PipelineMetrics {
  PipelineMetrics({this.summaryWindowSize = 20});

  final int summaryWindowSize;

  int _framesReceived = 0;
  int _framesProcessed = 0;
  int _framesReplaced = 0;
  int _framesDropped = 0;
  int _framesSent = 0;
  int _framesCompleted = 0;

  // Windowed timing accumulators
  final List<double> _conversionTimes = [];
  final List<double> _base64Times = [];
  final List<double> _httpTimes = [];
  final List<double> _totalTimes = [];

  int get framesReceived => _framesReceived;
  int get framesProcessed => _framesProcessed;
  int get framesReplaced => _framesReplaced;
  int get framesDropped => _framesDropped;
  int get framesSent => _framesSent;
  int get framesCompleted => _framesCompleted;

  List<double> get conversionTimes => List.unmodifiable(_conversionTimes);
  List<double> get base64Times => List.unmodifiable(_base64Times);
  List<double> get httpTimes => List.unmodifiable(_httpTimes);
  List<double> get totalTimes => List.unmodifiable(_totalTimes);

  (double avg, double min, double max, double p95) calcStats(List<double> list) => _calcStats(list);

  void recordFrameReceived() {
    _framesReceived++;
  }

  void recordFrameReplaced() {
    _framesReplaced++;
  }

  void recordFrameDropped() {
    _framesDropped++;
  }

  void recordFrameProcessed() {
    _framesProcessed++;
  }

  void recordFrameSent() {
    _framesSent++;
  }

  void recordCompletedCycle({
    required double conversionMs,
    required double base64Ms,
    required double httpMs,
    required double totalClientMs,
  }) {
    _framesCompleted++;
    _conversionTimes.add(conversionMs);
    _base64Times.add(base64Ms);
    _httpTimes.add(httpMs);
    _totalTimes.add(totalClientMs);

    if (_conversionTimes.length >= summaryWindowSize) {
      logSummary();
      _resetWindow();
    }
  }

  void _resetWindow() {
    _conversionTimes.clear();
    _base64Times.clear();
    _httpTimes.clear();
    _totalTimes.clear();
  }

  (double avg, double min, double max, double p95) _calcStats(List<double> list) {
    if (list.isEmpty) return (0.0, 0.0, 0.0, 0.0);
    double sum = 0;
    double minVal = list[0];
    double maxVal = list[0];
    for (final val in list) {
      sum += val;
      if (val < minVal) minVal = val;
      if (val > maxVal) maxVal = val;
    }
    final sorted = List<double>.from(list)..sort();
    final p95Index = ((sorted.length - 1) * 0.95).round();
    final p95Val = sorted[p95Index];
    return (sum / list.length, minVal, maxVal, p95Val);
  }

  void logSummary() {
    if (_conversionTimes.isEmpty) return;

    final (convAvg, convMin, convMax, convP95) = _calcStats(_conversionTimes);
    final (b64Avg, b64Min, b64Max, b64P95) = _calcStats(_base64Times);
    final (httpAvg, httpMin, httpMax, httpP95) = _calcStats(_httpTimes);
    final (totAvg, totMin, totMax, totP95) = _calcStats(_totalTimes);

    debugPrint(
      '\n═══════════════════════════════════════════════════════════════════\n'
      ' [EYRA CLIENT PIPELINE METRICS] (Window: ${_conversionTimes.length} cycles)\n'
      '   Total Counters: received=$_framesReceived | processed=$_framesProcessed\n'
      '                   replaced=$_framesReplaced | dropped=$_framesDropped\n'
      '                   sent=$_framesSent | completed=$_framesCompleted\n'
      '   Conversion:     avg=${convAvg.toStringAsFixed(1)}ms '
      '(min=${convMin.toStringAsFixed(1)}ms, max=${convMax.toStringAsFixed(1)}ms, p95=${convP95.toStringAsFixed(1)}ms)\n'
      '   Base64 Encode:  avg=${b64Avg.toStringAsFixed(1)}ms '
      '(min=${b64Min.toStringAsFixed(1)}ms, max=${b64Max.toStringAsFixed(1)}ms, p95=${b64P95.toStringAsFixed(1)}ms)\n'
      '   HTTP Roundtrip: avg=${httpAvg.toStringAsFixed(1)}ms '
      '(min=${httpMin.toStringAsFixed(1)}ms, max=${httpMax.toStringAsFixed(1)}ms, p95=${httpP95.toStringAsFixed(1)}ms)\n'
      '   Total Client:   avg=${totAvg.toStringAsFixed(1)}ms '
      '(min=${totMin.toStringAsFixed(1)}ms, max=${totMax.toStringAsFixed(1)}ms, p95=${totP95.toStringAsFixed(1)}ms)\n'
      '═══════════════════════════════════════════════════════════════════',
    );
  }
}
