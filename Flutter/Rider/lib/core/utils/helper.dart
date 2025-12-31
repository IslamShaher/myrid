import 'dart:ui' as ui;
import 'package:flutter/material.dart';
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

  /// Creates a modern circular navigation marker icon
  /// [color] - Main circle color
  /// [iconColor] - Icon color inside the circle
  /// [iconType] - Type of icon: 'pickup' (navigation), 'dropoff' (flag), 'live' (location dot)
  /// [size] - Size of the marker (default 32)
  static Future<Uint8List> createCustomCircleMarker({
    required Color color,
    required Color iconColor,
    String iconType = 'pickup', // 'pickup', 'dropoff', 'live'
    int size = 32,
  }) async {
    final pictureRecorder = ui.PictureRecorder();
    final canvas = Canvas(pictureRecorder);
    final sizeF = size.toDouble();
    final center = Offset(sizeF / 2, sizeF / 2);
    final radius = sizeF / 2 - 2;
    
    // Draw outer circle with shadow effect
    final outerPaint = Paint()
      ..color = color.withOpacity(0.15)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, sizeF / 2, outerPaint);
    
    // Draw main circle
    final mainPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, radius, mainPaint);
    
    // Draw white border
    final borderPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5;
    canvas.drawCircle(center, radius, borderPaint);
    
    // Draw icon based on type
    final iconPaint = Paint()
      ..color = iconColor
      ..style = PaintingStyle.fill;
    
    if (iconType == 'pickup') {
      // Draw navigation arrow (upward pointing)
      final path = Path();
      final arrowSize = sizeF * 0.3;
      path.moveTo(center.dx, center.dy - arrowSize);
      path.lineTo(center.dx - arrowSize * 0.6, center.dy);
      path.lineTo(center.dx - arrowSize * 0.3, center.dy);
      path.lineTo(center.dx - arrowSize * 0.3, center.dy + arrowSize * 0.4);
      path.lineTo(center.dx + arrowSize * 0.3, center.dy + arrowSize * 0.4);
      path.lineTo(center.dx + arrowSize * 0.3, center.dy);
      path.lineTo(center.dx + arrowSize * 0.6, center.dy);
      path.close();
      canvas.drawPath(path, iconPaint);
    } else if (iconType == 'dropoff') {
      // Draw flag shape
      final flagSize = sizeF * 0.25;
      // Flag pole
      final polePaint = Paint()
        ..color = iconColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0;
      canvas.drawLine(
        Offset(center.dx, center.dy - flagSize),
        Offset(center.dx, center.dy + flagSize * 0.3),
        polePaint,
      );
      // Flag
      final flagPath = Path();
      flagPath.moveTo(center.dx, center.dy - flagSize);
      flagPath.lineTo(center.dx + flagSize * 0.8, center.dy - flagSize * 0.5);
      flagPath.lineTo(center.dx, center.dy);
      flagPath.close();
      canvas.drawPath(flagPath, iconPaint);
    } else if (iconType == 'live') {
      // Draw location dot (small circle)
      final dotPaint = Paint()
        ..color = iconColor
        ..style = PaintingStyle.fill;
      canvas.drawCircle(center, sizeF * 0.15, dotPaint);
      // Draw outer ring
      final ringPaint = Paint()
        ..color = iconColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0;
      canvas.drawCircle(center, sizeF * 0.25, ringPaint);
    }
    
    final picture = pictureRecorder.endRecording();
    final image = await picture.toImage(size, size);
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    return byteData!.buffer.asUint8List();
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
