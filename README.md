# rubble_canvas

[![CI](https://github.com/Berkant35/rubble_canvas/actions/workflows/ci.yml/badge.svg)](https://github.com/Berkant35/rubble_canvas/actions/workflows/ci.yml)
[![License: Apache 2.0](https://img.shields.io/badge/license-Apache%202.0-blue.svg)](LICENSE)

The drawing canvas of [BeneathSOS](https://github.com/Berkant35/beneathsos): a rescuer sketches the
footprint of a collapsed building on a metric grid, with gloves, in a few taps.

- **`OutlineEditor`** — 1 m grid (5 m major lines); tap to add a corner, drag a corner to move it, drag
  elsewhere to pan, pinch to zoom; corners snap to 0.5 m; every side shows its length.
- **`OutlineDraft`** — the immutable outline being drawn, with undo, nearest corner / side lookup and the
  validation of `rubble_core`'s `RubblePolygon` (too few corners, corners too close, crossing sides,
  no area).
- **`EdgePicker`** — the outline fitted to a box; tap a side to choose it (to correct the scale with one
  real measurement).
- **`CanvasGeometry`**, **`SiteGridPainter`**, **`OutlinePainter`**, **`RubbleCanvasStyle`** — the
  pieces underneath; colours come from the app, the package has no design-system dependency.

```dart
OutlineEditor(
  draft: draft,
  onChanged: (next) => setState(() => draft = next),
  style: style,
  lengthLabel: (m) => '${m.value.toStringAsFixed(1)} m',
  semanticLabel: '4 corners, perimeter 61 m',
)
```

Depends only on Flutter and [`rubble_core`](https://github.com/Berkant35/rubble_core). Licence:
Apache-2.0.
