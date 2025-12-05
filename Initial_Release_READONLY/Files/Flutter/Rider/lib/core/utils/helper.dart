import 'dart:ui' as ui;
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_svg/svg.dart';
import 'package:ovorideuser/core/helper/string_format_helper.dart';

class Helper {
// Get byte data from asset safely
  static Future<Uint8List?> getBytesFromAsset(String path, int width) async {
    try {
      final ByteData data = await rootBundle.load(path);
      final ui.Codec codec = await ui.instantiateImageCodec(data.buffer.asUint8List(), targetWidth: width, targetHeight: width);
      final ui.FrameInfo frameInfo = await codec.getNextFrame();
      final ByteData? byteData = await frameInfo.image.toByteData(format: ui.ImageByteFormat.png);

      if (byteData == null) return null;

      return byteData.buffer.asUint8List();
    } catch (e) {
      // Optionally log the error: print('Error loading image: $e');
      return null;
    }
  }

  /// Renders an SVG asset into a [Uint8List] image buffer.
  static Future<Uint8List?> getBytesFromSvgAsset(String path, int width, int height) async {
    try {
      // Load SVG content from asset as string
      final String svgString = await rootBundle.loadString(path);

      // Convert SVG string to Picture
      final PictureInfo pictureInfo = await vg.loadPicture(
        SvgStringLoader(svgString),
        null,
      );

      // Convert Picture to Image
      final ui.Image image = await pictureInfo.picture.toImage(width, height);

      // Convert Image to ByteData (Uint8List)
      final ByteData? byteData = await image.toByteData(format: ui.ImageByteFormat.png);

      return byteData?.buffer.asUint8List();
    } catch (e) {
      printE("Error rendering SVG: $e");
      return null;
    }
  }
}
