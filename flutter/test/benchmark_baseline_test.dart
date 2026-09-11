// ignore_for_file: avoid_print, depend_on_referenced_packages
import 'dart:convert';
import 'dart:typed_data';
import 'package:camera/camera.dart';
import 'package:camera_platform_interface/camera_platform_interface.dart';
import 'package:eyra/core/services/http/jpeg_encoder.dart';
import 'package:flutter_test/flutter_test.dart';

/// Host Dart Microbenchmark
///
/// NOTE: This is a synthetic Dart host/test environment microbenchmark measuring
/// pure CPU execution time of `JpegEncoder.fromYuv420()` on the desktop test runner.
/// It is NOT a substitute for physical Android device measurements.
/// Production BEFORE vs. AFTER baselines must be measured on the actual physical
/// Android hardware.
void main() {
  test('Dart Software JpegEncoder Microbenchmark (Host/Test Runner Only)', () {
    const int width = 640;
    const int height = 480;

    final Uint8List yBytes = Uint8List(width * height);
    for (int i = 0; i < yBytes.length; i++) {
      yBytes[i] = (i % 256);
    }
    final Uint8List uBytes = Uint8List((width ~/ 2) * (height ~/ 2));
    final Uint8List vBytes = Uint8List((width ~/ 2) * (height ~/ 2));
    uBytes.fillRange(0, uBytes.length, 128);
    vBytes.fillRange(0, vBytes.length, 128);

    final planeY = CameraImagePlane(bytes: yBytes, bytesPerRow: width, bytesPerPixel: 1);
    final planeU = CameraImagePlane(bytes: uBytes, bytesPerRow: width ~/ 2, bytesPerPixel: 1);
    final planeV = CameraImagePlane(bytes: vBytes, bytesPerRow: width ~/ 2, bytesPerPixel: 1);

    final cameraImage = CameraImage.fromPlatformInterface(
      CameraImageData(
        format: const CameraImageFormat(ImageFormatGroup.yuv420, raw: 35),
        planes: [planeY, planeU, planeV],
        width: width,
        height: height,
      ),
    );

    // Warm-up
    final warmup = JpegEncoder.fromYuv420(cameraImage);
    expect(warmup, isNotNull);

    // Measure 10 runs of Dart JpegEncoder
    final List<double> durations = [];
    final List<double> b64Durations = [];
    for (int i = 0; i < 10; i++) {
      final sw = Stopwatch()..start();
      final jpeg = JpegEncoder.fromYuv420(cameraImage);
      sw.stop();
      durations.add(sw.elapsedMicroseconds / 1000.0);

      final b64Sw = Stopwatch()..start();
      base64Encode(jpeg!);
      b64Sw.stop();
      b64Durations.add(b64Sw.elapsedMicroseconds / 1000.0);
    }

    final avgConv = durations.reduce((a, b) => a + b) / durations.length;
    final minConv = durations.reduce((a, b) => a < b ? a : b);
    final maxConv = durations.reduce((a, b) => a > b ? a : b);

    final avgB64 = b64Durations.reduce((a, b) => a + b) / b64Durations.length;

    print('\n[BENCHMARK BEFORE - DART YUV->JPEG]');
    print('  Runs: ${durations.length}');
    print('  YUV420->JPEG Avg: ${avgConv.toStringAsFixed(2)}ms (min: ${minConv.toStringAsFixed(2)}ms, max: ${maxConv.toStringAsFixed(2)}ms)');
    print('  Base64 Encode Avg: ${avgB64.toStringAsFixed(2)}ms');
  });
}
