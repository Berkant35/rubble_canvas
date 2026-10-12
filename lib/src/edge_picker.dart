import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:rubble_canvas/src/outline_draft.dart';
import 'package:rubble_canvas/src/outline_painter.dart';
import 'package:rubble_canvas/src/rubble_canvas_style.dart';
import 'package:rubble_core/rubble_core.dart';

/// The outline fitted to the box, read-only; tap a side to select it (for the scale step).
class EdgePicker extends StatelessWidget {
  /// Creates the picker for [outline] with side [selected] highlighted.
  const EdgePicker({
    required this.outline,
    required this.selected,
    required this.onSelected,
    required this.style,
    required this.lengthLabel,
    required this.semanticLabel,
    this.scale = 1,
    super.key,
  });

  /// The outline.
  final RubblePolygon outline;

  /// The highlighted side (from corner `i` to the next).
  final int selected;

  /// Receives the tapped side.
  final ValueChanged<int> onSelected;

  /// Colours and label text.
  final RubbleCanvasStyle style;

  /// Text of a side's length.
  final String Function(Meters) lengthLabel;

  /// What a screen reader hears.
  final String semanticLabel;

  /// Multiplier for drawn lengths.
  final double scale;

  /// Room around the outline for the length labels, which sit centred on the sides.
  static const _padding = 56.0;

  /// How close to a side a tap must land, in pixels.
  static const _touchRadius = 24.0;

  @override
  Widget build(BuildContext context) => Semantics(
    label: semanticLabel,
    child: LayoutBuilder(
      builder: (context, constraints) {
        final size = constraints.biggest;
        final bounds = outline.bounds;
        final width = math.max(bounds.max.x.value - bounds.min.x.value, 0.1);
        final height = math.max(bounds.max.y.value - bounds.min.y.value, 0.1);
        final pxPerMetre = math.min(
          (size.width - 2 * _padding) / width,
          (size.height - 2 * _padding) / height,
        );
        final left = (size.width - width * pxPerMetre) / 2;
        final top = (size.height - height * pxPerMetre) / 2;
        Offset project(SitePoint p) => Offset(
          left + (p.x.value - bounds.min.x.value) * pxPerMetre,
          top + (bounds.max.y.value - p.y.value) * pxPerMetre,
        );
        SitePoint unproject(Offset o) => SitePoint(
          Meters(bounds.min.x.value + (o.dx - left) / pxPerMetre),
          Meters(bounds.max.y.value - (o.dy - top) / pxPerMetre),
        );
        return GestureDetector(
          onTapUp: (details) {
            final side = OutlineDraft.from(outline).edgeNear(
              unproject(details.localPosition),
              Meters(_touchRadius / pxPerMetre),
            );
            if (side != null) onSelected(side);
          },
          child: CustomPaint(
            size: size,
            painter: OutlinePainter(
              corners: outline.corners,
              project: project,
              style: style,
              lengthLabel: lengthLabel,
              scale: scale,
              highlightedEdge: selected,
              showCorners: false,
            ),
          ),
        );
      },
    ),
  );
}
