import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:rubble_canvas/src/canvas_geometry.dart';
import 'package:rubble_canvas/src/outline_draft.dart';
import 'package:rubble_canvas/src/outline_painter.dart';
import 'package:rubble_canvas/src/rubble_canvas_style.dart';
import 'package:rubble_canvas/src/site_grid_painter.dart';
import 'package:rubble_core/rubble_core.dart';

/// Draws the rubble outline on a metric grid: tap empty space to add a corner, drag a corner to move
/// it, drag elsewhere to pan, pinch to zoom. Corners snap to [snapStep].
///
/// Dragging a corner uses raw pointer events and switches panning off while the finger is on the
/// corner, so the view never fights the corner for the same finger.
class OutlineEditor extends StatefulWidget {
  /// Creates the editor for [draft]; every change goes to [onChanged].
  const OutlineEditor({
    required this.draft,
    required this.onChanged,
    required this.style,
    required this.lengthLabel,
    required this.semanticLabel,
    this.geometry = const CanvasGeometry(
      halfExtent: Meters(50),
      pixelsPerMeter: 20,
    ),
    this.scale = 1,
    this.snapStep = const Meters(0.5),
    this.viewSpan,
    this.initialCenter,
    super.key,
  });

  /// The outline being drawn.
  final OutlineDraft draft;

  /// Receives every change (add, move).
  final ValueChanged<OutlineDraft> onChanged;

  /// Colours and label text.
  final RubbleCanvasStyle style;

  /// Text of a side's length.
  final String Function(Meters) lengthLabel;

  /// What a screen reader hears for the canvas (for example corners and perimeter).
  final String semanticLabel;

  /// The workspace.
  final CanvasGeometry geometry;

  /// Multiplier for drawn lengths (`ScaleSet`).
  final double scale;

  /// Corners land on multiples of this.
  final Meters snapStep;

  /// How much of the site the first view shows across its shorter side; by default 30 m or the
  /// outline with a margin.
  final Meters? viewSpan;

  /// Middle of the first view; by default the middle of the outline (or the origin).
  final SitePoint? initialCenter;

  /// How close to a corner a finger must land to grab it, in screen pixels.
  static const touchRadius = 24.0;

  @override
  State<OutlineEditor> createState() => _OutlineEditorState();
}

class _OutlineEditorState extends State<OutlineEditor> {
  final _view = TransformationController();
  var _placed = false;
  int? _pointer;
  int? _corner;
  OutlineDraft? _dragStart;

  CanvasGeometry get _geometry => widget.geometry;

  double get _zoom => _view.value.getMaxScaleOnAxis();

  Meters get _tolerance =>
      Meters(OutlineEditor.touchRadius / (_geometry.pixelsPerMeter * _zoom));

  @override
  void dispose() {
    _view.dispose();
    super.dispose();
  }

  void _placeFirstView(Size viewport) {
    if (_placed) return;
    _placed = true;
    final corners = widget.draft.corners;
    final xs = corners.map((c) => c.x.value);
    final ys = corners.map((c) => c.y.value);
    final center =
        widget.initialCenter ??
        (corners.isEmpty
            ? const SitePoint(Meters.zero, Meters.zero)
            : SitePoint(
                Meters((xs.reduce(math.min) + xs.reduce(math.max)) / 2),
                Meters((ys.reduce(math.min) + ys.reduce(math.max)) / 2),
              ));
    final extent = corners.isEmpty
        ? 0.0
        : math.max(
            xs.reduce(math.max) - xs.reduce(math.min),
            ys.reduce(math.max) - ys.reduce(math.min),
          );
    final span = widget.viewSpan?.value ?? math.max(30.0, extent * 1.3);
    final zoom = viewport.shortestSide / (span * _geometry.pixelsPerMeter);
    final at = _geometry.toCanvas(center);
    _view.value = Matrix4.identity()
      ..translateByDouble(
        viewport.width / 2 - at.dx * zoom,
        viewport.height / 2 - at.dy * zoom,
        0,
        1,
      )
      ..scaleByDouble(zoom, zoom, 1, 1);
  }

  SitePoint _snapped(Offset canvas) =>
      CanvasGeometry.snap(_geometry.toSite(canvas), widget.snapStep);

  void _onTapUp(TapUpDetails details) {
    final site = _geometry.toSite(details.localPosition);
    if (widget.draft.cornerNear(site, _tolerance) != null) return;
    widget.onChanged(widget.draft.add(_snapped(details.localPosition)));
  }

  void _onPointerDown(PointerDownEvent event) {
    if (_pointer != null) {
      // A second finger: stop dragging the corner, let the pinch zoom.
      _endDrag();
      return;
    }
    final corner = widget.draft.cornerNear(
      _geometry.toSite(event.localPosition),
      _tolerance,
    );
    if (corner == null) return;
    setState(() {
      _pointer = event.pointer;
      _corner = corner;
      _dragStart = widget.draft;
    });
  }

  void _onPointerMove(PointerMoveEvent event) {
    final start = _dragStart;
    final corner = _corner;
    if (event.pointer != _pointer || start == null || corner == null) return;
    final next = start.move(corner, _snapped(event.localPosition));
    // Every move starts from the draft before the drag: one undo puts the corner back.
    if (next.corners[corner] != widget.draft.corners[corner]) {
      widget.onChanged(next);
    }
  }

  void _onPointerEnd(PointerEvent event) {
    if (event.pointer == _pointer) _endDrag();
  }

  void _endDrag() => setState(() {
    _pointer = null;
    _corner = null;
    _dragStart = null;
  });

  @override
  Widget build(BuildContext context) => Semantics(
    label: widget.semanticLabel,
    child: LayoutBuilder(
      builder: (context, constraints) {
        _placeFirstView(constraints.biggest);
        return InteractiveViewer(
          transformationController: _view,
          constrained: false,
          minScale: 0.3,
          maxScale: 8,
          boundaryMargin: EdgeInsets.all(constraints.biggest.longestSide),
          panEnabled: _pointer == null,
          child: SizedBox.fromSize(
            size: _geometry.canvasSize,
            child: Listener(
              onPointerDown: _onPointerDown,
              onPointerMove: _onPointerMove,
              onPointerUp: _onPointerEnd,
              onPointerCancel: _onPointerEnd,
              child: GestureDetector(
                onTapUp: _onTapUp,
                child: ListenableBuilder(
                  listenable: _view,
                  builder: (context, _) => CustomPaint(
                    painter: SiteGridPainter(
                      geometry: _geometry,
                      style: widget.style,
                      zoom: _zoom,
                    ),
                    foregroundPainter: OutlinePainter(
                      corners: widget.draft.corners,
                      project: _geometry.toCanvas,
                      style: widget.style,
                      lengthLabel: widget.lengthLabel,
                      scale: widget.scale,
                      zoom: _zoom,
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    ),
  );
}
