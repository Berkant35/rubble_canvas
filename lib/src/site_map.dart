import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:rubble_canvas/src/canvas_geometry.dart';
import 'package:rubble_canvas/src/heat_layer.dart';
import 'package:rubble_canvas/src/outline_painter.dart';
import 'package:rubble_canvas/src/rubble_canvas_style.dart';
import 'package:rubble_core/rubble_core.dart';

/// The outline fitted into a box with [margin] around it (points are measured around the rubble),
/// north up.
@immutable
final class SiteMapView {
  /// The view of [outline] in a box of [size].
  factory SiteMapView.fit(
    RubblePolygon outline,
    Size size, {
    Meters margin = const Meters(5),
  }) {
    final b = outline.bounds;
    final minX = b.min.x.value - margin.value;
    final maxY = b.max.y.value + margin.value;
    final width = b.max.x.value - b.min.x.value + 2 * margin.value;
    final height = b.max.y.value - b.min.y.value + 2 * margin.value;
    final scale = math.min(size.width / width, size.height / height);
    return SiteMapView._(
      pxPerMetre: scale,
      left: minX - (size.width / scale - width) / 2,
      top: maxY + (size.height / scale - height) / 2,
    );
  }

  const SiteMapView._({
    required this.pxPerMetre,
    required this.left,
    required this.top,
  });

  /// Screen pixels per metre.
  final double pxPerMetre;

  /// Site x at the left edge of the box.
  final double left;

  /// Site y at the top edge of the box.
  final double top;

  /// Where [point] is drawn.
  Offset toScreen(SitePoint point) => Offset(
    (point.x.value - left) * pxPerMetre,
    (top - point.y.value) * pxPerMetre,
  );

  /// The site point under [offset].
  SitePoint toSite(Offset offset) => SitePoint(
    Meters(left + offset.dx / pxPerMetre),
    Meters(top - offset.dy / pxPerMetre),
  );
}

/// What a point on the map shows.
enum MapPointKind {
  /// Measured, the target was heard.
  heard,

  /// Measured, the target was not heard (still information — rule 3).
  notHeard,

  /// Being measured now.
  measuring,

  /// Suggested as the next most informative spot.
  suggested,
}

/// A point to draw on the map.
@immutable
final class MapPoint {
  /// Creates a point.
  const MapPoint({required this.at, required this.kind});

  /// Where.
  final SitePoint at;

  /// What it shows.
  final MapPointKind kind;

  @override
  bool operator ==(Object other) =>
      other is MapPoint && other.at == at && other.kind == kind;

  @override
  int get hashCode => Object.hash(at, kind);
}

/// The outline and the measurement points around it; with [onTap], a tap reports the site point
/// under the finger (snapped to 0.5 m) — "measure where I stand".
class SiteMap extends StatelessWidget {
  /// Creates the map.
  const SiteMap({
    required this.outline,
    required this.points,
    required this.style,
    required this.semanticLabel,
    this.onTap,
    this.heat,
    super.key,
  });

  /// The probability regions to draw under the outline, if any.
  final HeatLayer? heat;

  /// The rubble outline.
  final RubblePolygon outline;

  /// Points to draw.
  final List<MapPoint> points;

  /// Colours.
  final RubbleCanvasStyle style;

  /// What a screen reader hears.
  final String semanticLabel;

  /// Receives a tapped site point; null makes the map read-only.
  final ValueChanged<SitePoint>? onTap;

  @override
  Widget build(BuildContext context) => Semantics(
    label: semanticLabel,
    child: LayoutBuilder(
      builder: (context, constraints) {
        final size = constraints.biggest;
        final view = SiteMapView.fit(outline, size);
        final onTap = this.onTap;
        return GestureDetector(
          onTapUp: onTap == null
              ? null
              : (details) => onTap(
                  CanvasGeometry.snap(
                    view.toSite(details.localPosition),
                    const Meters(0.5),
                  ),
                ),
          child: CustomPaint(
            size: size,
            painter: _SiteMapPainter(
              view: view,
              outline: outline,
              points: points,
              style: style,
              heat: heat,
            ),
          ),
        );
      },
    ),
  );
}

class _SiteMapPainter extends CustomPainter {
  const _SiteMapPainter({
    required this.view,
    required this.outline,
    required this.points,
    required this.style,
    required this.heat,
  });

  final HeatLayer? heat;

  final SiteMapView view;
  final RubblePolygon outline;
  final List<MapPoint> points;
  final RubbleCanvasStyle style;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, Paint()..color = style.background);
    final grid = Paint()
      ..color = style.gridMinor
      ..strokeWidth = 1;
    final step =
        view.pxPerMetre * 5; // a line every 5 m keeps the small map calm
    final first = view.toScreen(
      SitePoint(Meters((view.left / 5).ceil() * 5.0), Meters.zero),
    );
    for (var x = first.dx; x < size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), grid);
    }
    final firstY = view.toScreen(
      SitePoint(Meters.zero, Meters((view.top / 5).floor() * 5.0)),
    );
    for (var y = firstY.dy; y < size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), grid);
    }
    if (heat case final heat?) _paintHeat(canvas, heat);
    final path = Path()
      ..addPolygon([for (final c in outline.corners) view.toScreen(c)], true);
    canvas
      ..drawPath(path, Paint()..color = style.outline.withValues(alpha: 0.08))
      ..drawPath(
        path,
        Paint()
          ..color = style.outline
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3,
      );
    for (final point in points) {
      final at = view.toScreen(point.at);
      const r = OutlinePainter.cornerRadius;
      switch (point.kind) {
        case MapPointKind.heard:
          canvas.drawCircle(at, r, Paint()..color = style.corner);
        case MapPointKind.notHeard:
          canvas.drawCircle(
            at,
            r - 1.5,
            Paint()
              ..color = style.corner
              ..style = PaintingStyle.stroke
              ..strokeWidth = 3,
          );
        case MapPointKind.suggested:
          canvas
            ..drawCircle(
              at,
              r + 4,
              Paint()
                ..color = style.highlight
                ..style = PaintingStyle.stroke
                ..strokeWidth = 3,
            )
            ..drawCircle(at, 3, Paint()..color = style.highlight);
        case MapPointKind.measuring:
          canvas
            ..drawCircle(at, r + 3, Paint()..color = style.highlight)
            ..drawCircle(at, r - 3, Paint()..color = style.labelBackground);
      }
    }
  }

  void _paintHeat(Canvas canvas, HeatLayer heat) {
    final colour = style.region ?? style.highlight;
    final likely = Path();
    final possible = Path();
    final side = heat.cell.value * view.pxPerMetre;
    for (var i = 0; i < heat.length; i++) {
      final region = switch (heat.regionOf(i)) {
        HeatRegion.likely50 => likely,
        HeatRegion.likely90 => possible,
        HeatRegion.outside => null,
      };
      if (region == null) continue;
      final corner = view.toScreen(
        SitePoint(
          Meters(heat.origin.x.value + heat.cell.value * (i % heat.cols)),
          Meters(heat.origin.y.value + heat.cell.value * (i ~/ heat.cols + 1)),
        ),
      );
      // A hair larger than the cell, so neighbours leave no seams; one path per region paints
      // overlaps once.
      region.addRect(
        Rect.fromLTWH(corner.dx, corner.dy, side + 0.5, side + 0.5),
      );
    }
    canvas
      ..drawPath(possible, Paint()..color = colour.withValues(alpha: 0.22))
      ..drawPath(likely, Paint()..color = colour.withValues(alpha: 0.55));
  }

  @override
  bool shouldRepaint(_SiteMapPainter oldDelegate) =>
      oldDelegate.outline != outline ||
      !listEquals(oldDelegate.points, points) ||
      oldDelegate.style != style ||
      oldDelegate.heat != heat ||
      oldDelegate.view.pxPerMetre != view.pxPerMetre;
}
