import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';
import 'package:rubble_core/rubble_core.dart';

/// The square drawing workspace: site metres (x east, y north, origin in the middle) to canvas pixels
/// (x right, y down).
@immutable
final class CanvasGeometry {
  /// A workspace reaching [halfExtent] from the origin in every direction, drawn at [pixelsPerMeter].
  const CanvasGeometry({
    required this.halfExtent,
    required this.pixelsPerMeter,
  });

  /// Distance from the origin to each edge of the workspace.
  final Meters halfExtent;

  /// Canvas pixels per metre before any zoom.
  final double pixelsPerMeter;

  /// Size of the whole workspace in canvas pixels.
  Size get canvasSize => Size.square(2 * halfExtent.value * pixelsPerMeter);

  /// Where [point] is drawn.
  Offset toCanvas(SitePoint point) => Offset(
    (point.x.value + halfExtent.value) * pixelsPerMeter,
    (halfExtent.value - point.y.value) * pixelsPerMeter,
  );

  /// The site point under the canvas position [offset].
  SitePoint toSite(Offset offset) => SitePoint(
    Meters(offset.dx / pixelsPerMeter - halfExtent.value),
    Meters(halfExtent.value - offset.dy / pixelsPerMeter),
  );

  /// [point] rounded to the nearest multiple of [step] (fingers are not precise; 0.5 m is plenty).
  static SitePoint snap(SitePoint point, Meters step) => SitePoint(
    Meters((point.x.value / step.value).round() * step.value),
    Meters((point.y.value / step.value).round() * step.value),
  );
}
