## 0.6.0
- `SiteMap(circles:)`: a circle around a measured point in its own colour (`MapCircle`).
- `SiteMap(measure:)`: a dashed, labelled distance line with a ringed end mark (`MapMeasure`).
- `MapPoint.color`: a measured point in the colour of its circle.

## 0.5.0
- Measured points are diamonds (never mistaken for the outline's round corners); a heard point warms from
  blue to orange with `MapPoint.strength` and can show a `label` (its signal).
- `SiteMap(likely:)`: the most likely spot as a crosshair with its dashed 50 % circle (`LikelySpot`).

## 0.4.0
- `MapPointKind.found`: where the phone was actually found (a cross, unlike every measured dot).

## 0.3.0
- `HeatLayer`: the 50 % / 90 % region of every grid cell, drawn by `SiteMap` as two regions
  (never a single point); `MapPointKind.suggested`; optional `RubbleCanvasStyle.region` colour.

## 0.2.0
- `SiteMap`: the outline fitted to a box with a 5 m margin, measurement points (heard, not heard,
  measuring), tap to report a site point (0.5 m snap); `SiteMapView` fit transform.

## 0.1.0
- Metric grid and rubble outline editor (`OutlineEditor`): tap to add, drag to move, pan and
  zoom, 0.5 m snapping, side lengths; `OutlineDraft` with undo and validation; `EdgePicker`.
