import 'package:flutter/rendering.dart';
import 'package:rubble_canvas/src/canvas_geometry.dart';
import 'package:rubble_canvas/src/rubble_canvas_style.dart';

/// The metric grid: a line every metre, a stronger one every 5 m.
class SiteGridPainter extends CustomPainter {
  /// Paints the grid of [geometry]; line widths are divided by [zoom] so they look the same at any zoom.
  const SiteGridPainter({
    required this.geometry,
    required this.style,
    this.zoom = 1,
  });

  /// The workspace.
  final CanvasGeometry geometry;

  /// Colours.
  final RubbleCanvasStyle style;

  /// Current zoom of the view.
  final double zoom;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, Paint()..color = style.background);
    final minor = Paint()
      ..color = style.gridMinor
      ..strokeWidth = 1 / zoom;
    final major = Paint()
      ..color = style.gridMajor
      ..strokeWidth = 1.5 / zoom;
    final metres = (2 * geometry.halfExtent.value).round();
    for (var m = 0; m <= metres; m++) {
      final at = m * geometry.pixelsPerMeter;
      final paint = (m - geometry.halfExtent.value.round()) % 5 == 0
          ? major
          : minor;
      canvas
        ..drawLine(Offset(at, 0), Offset(at, size.height), paint)
        ..drawLine(Offset(0, at), Offset(size.width, at), paint);
    }
  }

  @override
  bool shouldRepaint(SiteGridPainter oldDelegate) =>
      oldDelegate.geometry != geometry ||
      oldDelegate.style != style ||
      oldDelegate.zoom != zoom;
}
