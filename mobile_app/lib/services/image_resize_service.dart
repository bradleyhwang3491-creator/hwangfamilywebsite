import 'dart:typed_data';

import 'package:image/image.dart' as img;

class ResizedImage {
  final Uint8List bytes;
  final String fileName;

  ResizedImage({required this.bytes, required this.fileName});
}

/// Ported from src/lib/imageResize.ts — resizes/compresses to stay under
/// maxBytes (default 5MB), capping the longest side at 2400px.
class ImageResizeService {
  static const _maxBytes = 5 * 1024 * 1024;
  static const _maxDimension = 2400;

  static Future<ResizedImage> resizeToLimit(
    Uint8List bytes,
    String originalName, {
    int maxBytes = _maxBytes,
  }) async {
    if (bytes.length <= maxBytes) {
      return ResizedImage(bytes: bytes, fileName: originalName);
    }

    final decoded = img.decodeImage(bytes);
    if (decoded == null) {
      return ResizedImage(bytes: bytes, fileName: originalName);
    }

    var width = decoded.width;
    var height = decoded.height;
    img.Image working = decoded;
    if (width > _maxDimension || height > _maxDimension) {
      final scale = _maxDimension / (width > height ? width : height);
      width = (width * scale).round();
      height = (height * scale).round();
      working = img.copyResize(decoded, width: width, height: height);
    }

    var quality = 90;
    var out = img.encodeJpg(working, quality: quality);

    while (out.length > maxBytes && quality > 30) {
      quality -= 10;
      out = img.encodeJpg(working, quality: quality);
    }

    while (out.length > maxBytes && width > 400) {
      width = (width * 0.85).round();
      height = (height * 0.85).round();
      working = img.copyResize(working, width: width, height: height);
      out = img.encodeJpg(working, quality: quality);
    }

    final newName = '${originalName.replaceAll(RegExp(r'\.\w+$'), '')}.jpg';
    return ResizedImage(bytes: Uint8List.fromList(out), fileName: newName);
  }
}
