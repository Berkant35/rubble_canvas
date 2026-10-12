## 0.3.0
- `HeatLayer`: the 50 % / 90 % region of every grid cell, drawn by `SiteMap` as two regions
  (never a single point); `MapPointKind.suggested`; optional `RubbleCanvasStyle.region` colour.

## 0.2.0
- `SiteMap`: the outline fitted to a box with a 5 m margin, measurement points (heard, not heard,
  measuring), tap to report a site point (0.5 m snap); `SiteMapView` fit transform.

## 0.1.0
- Metric grid and rubble outline editor (`OutlineEditor`): tap to add, drag to move, pan and
  zoom, 0.5 m snapping, side lengths; `OutlineDraft` with undo and validation; `EdgePicker`.
