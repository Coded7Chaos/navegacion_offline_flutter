import 'dart:typed_data';
import 'package:camera/camera.dart';
import 'package:image/image.dart' as img;

class ImageUtils {
  
  static img.Image? convertCameraImage(CameraImage cameraImage) {
    if (cameraImage.format.group == ImageFormatGroup.yuv420) {
      return convertYUV420ToImage(cameraImage);
    } else if (cameraImage.format.group == ImageFormatGroup.bgra8888) {
      return convertBGRA8888ToImage(cameraImage);
    } else {
      print("Formato no soportado: ${cameraImage.format.group}");
      return null;
    }
  }

  /// Converts a [CameraImage] in BGRA8888 format to [img.Image] RGB format
  static img.Image convertBGRA8888ToImage(CameraImage cameraImage) {
    return img.Image.fromBytes(
      width: cameraImage.width,
      height: cameraImage.height,
      bytes: cameraImage.planes[0].bytes.buffer,
      order: img.ChannelOrder.bgra,
    );
  }

  /// Converts a [CameraImage] in YUV420 format to [img.Image] RGB format
  static img.Image? convertYUV420ToImage(CameraImage cameraImage) {
    final int width = cameraImage.width;
    final int height = cameraImage.height;

    final int uvRowStride = cameraImage.planes[1].bytesPerRow;
    final int? uvPixelStride = cameraImage.planes[1].bytesPerPixel;

    final img.Image image = img.Image(width: width, height: height);

    for (int w = 0; w < width; w++) {
      for (int h = 0; h < height; h++) {
        final int uvIndex =
            uvPixelStride! * (w / 2).floor() + uvRowStride * (h / 2).floor();
        final int index = h * width + w;

        final y = cameraImage.planes[0].bytes[index];
        final u = cameraImage.planes[1].bytes[uvIndex];
        final v = cameraImage.planes[2].bytes[uvIndex];

        image.setPixelRgb(w, h, _yuv2r(y, u, v), _yuv2g(y, u, v), _yuv2b(y, u, v));
      }
    }
    return image;
  }

  static int _yuv2r(int y, int u, int v) {
    return (y + (1.370705 * (v - 128))).clamp(0, 255).toInt();
  }

  static int _yuv2g(int y, int u, int v) {
    return (y - (0.337633 * (u - 128)) - (0.698001 * (v - 128))).clamp(0, 255).toInt();
  }

  static int _yuv2b(int y, int u, int v) {
    return (y + (1.732446 * (u - 128))).clamp(0, 255).toInt();
  }
  
  /// Prepares the image for the model (Resize to 300x300)
  static List<List<List<int>>> processCameraImage(CameraImage cameraImage, int inputSize) {
      // 1. Convert to RGB Image
      img.Image? converted = convertCameraImage(cameraImage);
      
      if (converted == null) return [];

      // 2. Resize to model input (e.g. 300x300)
      // We use resize which might stretch. 
      // Ideally we should Crop then Resize to maintain aspect ratio, 
      // but for a prototype, stretching is acceptable or we assume center crop.
      img.Image resized = img.copyResize(converted, width: inputSize, height: inputSize);

      // 3. Extract bytes [1, 300, 300, 3]
      List<List<List<int>>> imageMatrix = List.generate(
        inputSize,
        (y) => List.generate(
          inputSize,
          (x) {
            var pixel = resized.getPixel(x, y);
            return [pixel.r.toInt(), pixel.g.toInt(), pixel.b.toInt()];
          },
        ),
      );
      
      return imageMatrix;
  }
}