import 'dart:developer';
import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'jpeg_encoder.dart';

/// Bridges Flutter [CameraImage] frames to native platform image encoders.
///
/// On Android, offloads YUV420/NV21 compression to Android OS's native
/// `YuvImage.compressToJpeg` via a dedicated [MethodChannel] running on a
/// single background worker thread.
///
/// IMPORTANT: On Android, failures do NOT fall back to Dart's pixel-by-pixel
/// [JpegEncoder] to prevent blocking the UI isolate. Instead, a failure
/// returns null and the frame is dropped. The Dart fallback is only used
/// on non-Android platforms (such as unit tests and desktop).
class NativeImageConverter {
  NativeImageConverter({MethodChannel? channel})
      : _channel = channel ?? const MethodChannel('com.example.eyra/image_converter');

  final MethodChannel _channel;

  int _convertCount = 0;

  /// Converts a [CameraImage] to JPEG bytes using native Android encoding.
  ///
  /// Returns [Uint8List] with valid JPEG data, or `null` if conversion fails.
  Future<Uint8List?> convertToJpeg(CameraImage image, {int quality = 75}) async {
    if (image.width <= 0 || image.height <= 0 || image.planes.isEmpty) {
      debugPrint('[NATIVE CONVERTER] ERROR type=ArgumentError message=invalid frame dimensions (${image.width}x${image.height}) or empty planes');
      return null;
    }

    _convertCount++;
    final shouldLog = (_convertCount == 1 || _convertCount % 20 == 0);

    if (shouldLog) {
      debugPrint(
        '[NATIVE CONVERTER] BEFORE '
        'width=${image.width} '
        'height=${image.height} '
        'format=${image.format.group} '
        'planes=${image.planes.length}',
      );
    }

    // Android: use native platform channel
    if (defaultTargetPlatform == TargetPlatform.android) {
      final sw = Stopwatch()..start();
      try {
        final Map<String, dynamic> args;

        // Explicit NV21 fast path: MUST verify BOTH format.group == nv21 AND planes.length == 1
        if (image.format.group == ImageFormatGroup.nv21 && image.planes.length == 1) {
          args = <String, dynamic>{
            'nv21Bytes': image.planes[0].bytes,
            'width': image.width,
            'height': image.height,
            'quality': quality,
          };
        } else if (image.planes.length >= 3) {
          // Standard 3-plane YUV_420_888
          final yPlane = image.planes[0];
          final uPlane = image.planes[1];
          final vPlane = image.planes[2];

          args = <String, dynamic>{
            'yBytes': yPlane.bytes,
            'uBytes': uPlane.bytes,
            'vBytes': vPlane.bytes,
            'yRowStride': yPlane.bytesPerRow,
            'uvRowStride': uPlane.bytesPerRow,
            'uvPixelStride': uPlane.bytesPerPixel ?? 1,
            'width': image.width,
            'height': image.height,
            'quality': quality,
          };
        } else {
          debugPrint(
            '[NATIVE CONVERTER] ERROR '
            'type=UnsupportedFormat '
            'message=unsupported format/plane configuration (format=${image.format.group}, planes=${image.planes.length})',
          );
          return null;
        }

        final result = await _channel.invokeMethod<Uint8List>('convertYuvToJpeg', args);
        sw.stop();
        final elapsedMs = sw.elapsedMicroseconds / 1000.0;

        if (result == null || result.isEmpty) {
          debugPrint(
            '[NATIVE CONVERTER] ERROR '
            'type=EmptyResult '
            'message=native returned empty JPEG buffer',
          );
          return null;
        }

        if (shouldLog) {
          debugPrint(
            '[NATIVE CONVERTER] AFTER '
            'jpegBytes=${result.length} '
            'elapsedMs=${elapsedMs.toStringAsFixed(1)}',
          );
        }
        return result;
      } catch (e) {
        sw.stop();
        // Strict requirement: On Android, DO NOT fall back to Dart JpegEncoder.
        // Log diagnostic error and drop frame.
        debugPrint(
          '[NATIVE CONVERTER] ERROR '
          'type=${e.runtimeType} '
          'message=$e',
        );
        return null;
      }
    }

    // Non-Android platforms (e.g. unit tests, desktop emulators):
    // Fall back to software JpegEncoder.
    return JpegEncoder.fromYuv420(image);
  }
}
