import 'package:flutter/rendering.dart';
import 'package:rubble_canvas/src/rubble_canvas_style.dart';
import 'package:rubble_core/rubble_core.dart';

/// The outline: sides (the closing side once there are three corners), corner handles and a length
/// label on every side.
class OutlinePainter extends CustomPainter {
  /// Paints [corners] through [project]; sizes are divided by [zoom] so they look the same at any zoom.
  const OutlinePainter({
    required this.corners,
    required this.project,
    required this.style,
    required this.lengthLabel,
    this.scale = 1,
    this.zoom = 1,
    this.highlightedEdge,
    this.showCorners = true,
  });

  /// Corners in drawing order.
  final List<SitePoint> corners;

  /// Site metres → canvas pixels.
  final Offset Function(SitePoint) project;

  /// Colours and label text.
  final RubbleCanvasStyle style;

  /// Text of a side's length (already multiplied by [scale]).
  final String Function(Meters) lengthLabel;

  /// Multiplier for drawn lengths (`ScaleSet`).
  final double scale;

  /// Current zoom of the view.
  final double zoom;

  /// Side drawn in the highlight colour, if any.
  final int? highlightedEdge;

  /// Whether to draw corner handles.
  final bool showCorners;

  /// Visual radius of a corner handle in screen pixels.
  static const cornerRadius = 9.0;

  @override
  void paint(Canvas canvas, Size size) {
    final sides = corners.length >= 3 ? corners.length : corners.length - 1;
    for (var i = 0; i < sides; i++) {
      final a = corners[i];
      final b = corners[(i + 1) % corners.length];
      canvas.drawLine(
        project(a),
        project(b),
        Paint()
          ..color = i == highlightedEdge ? style.highlight : style.outline
          ..strokeWidth = (i == highlightedEdge ? 5 : 3) / zoom
          ..strokeCap = StrokeCap.round,
      );
      _label(
        canvas,
        lengthLabel(Meters(a.distanceTo(b).value * scale)),
        (project(a) + project(b)) / 2,
      );
    }
    if (!showCorners) return;
    for (final corner in corners) {
      canvas
        ..drawCircle(
          project(corner),
          cornerRadius / zoom,
          Paint()..color = style.corner,
        )
        ..drawCircle(
          project(corner),
          cornerRadius / zoom,
          Paint()
            ..color = style.labelBackground
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2 / zoom,
        );
    }
  }

  void _label(Canvas canvas, String text, Offset at) {
    final painter = TextPainter(
      text: TextSpan(
        text: text,
        style: style.label.copyWith(
          fontSize: (style.label.fontSize ?? 14) / zoom,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    final pad = 3 / zoom;
    final box = Rect.fromCenter(
      center: at,
      width: painter.width + 2 * pad,
      height: painter.height + 2 * pad,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(box, Radius.circular(4 / zoom)),
      Paint()..color = style.labelBackground,
    );
    painter
      ..paint(canvas, box.topLeft + Offset(pad, pad))
      ..dispose();
  }

  @override
  bool shouldRepaint(OutlinePainter oldDelegate) =>
      oldDelegate.corners != corners ||
      oldDelegate.style != style ||
      oldDelegate.scale != scale ||
      oldDelegate.zoom != zoom ||
      oldDelegate.highlightedEdge != highlightedEdge ||
      oldDelegate.showCorners != showCorners;
}
