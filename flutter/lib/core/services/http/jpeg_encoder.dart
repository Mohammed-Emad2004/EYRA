import 'dart:typed_data';

import 'package:camera/camera.dart';
import 'package:image/image.dart' as img;

/// Converts a YUV420 [CameraImage] from the Android camera to JPEG bytes
/// using the `image` package's proven encoder.
///
/// Produces a valid baseline JPEG that cv2.imdecode (OpenCV) on the
/// AI server can decode without errors.
class JpegEncoder {
  JpegEncoder._();

  /// Encodes a YUV420 [CameraImage] to JPEG bytes.
  ///
  /// Returns null if encoding fails for any reason.
  static Uint8List? fromYuv420(CameraImage cameraImage) {
    try {
      final width = cameraImage.width;
      final height = cameraImage.height;

      // YUV420 planes: [0]=Y, [1]=U, [2]=V
      final yPlane = cameraImage.planes[0];
      final uPlane = cameraImage.planes[1];
      final vPlane = cameraImage.planes[2];

      final yBytes = yPlane.bytes;
      final uBytes = uPlane.bytes;
      final vBytes = vPlane.bytes;

      final int yRowStride = yPlane.bytesPerRow;
      final int uvRowStride = uPlane.bytesPerRow;
      final int uvPixelStride = uPlane.bytesPerPixel ?? 1;

      // Build an RGB Image from YUV420 data.
      final rgbImage = img.Image(width: width, height: height);

      for (int y = 0; y < height; y++) {
        for (int x = 0; x < width; x++) {
          final int yIndex = y * yRowStride + x;
          final int uvIndex = (y ~/ 2) * uvRowStride + (x ~/ 2) * uvPixelStride;

          final int yVal = yBytes[yIndex];
          final int uVal = uBytes[uvIndex];
          final int vVal = vBytes[uvIndex];

          // YUV → RGB conversion (BT.601).
          int r = (yVal + 1.370705 * (vVal - 128)).round();
          int g = (yVal - 0.337633 * (uVal - 128) - 0.698001 * (vVal - 128))
              .round();
          int b = (yVal + 1.732446 * (uVal - 128)).round();

          r = r.clamp(0, 255);
          g = g.clamp(0, 255);
          b = b.clamp(0, 255);

          rgbImage.setPixelRgb(x, y, r, g, b);
        }
      }

      // Encode to JPEG at quality 75.
      return Uint8List.fromList(img.encodeJpg(rgbImage, quality: 75));
    } catch (_) {
      return null;
    }
  }
}
