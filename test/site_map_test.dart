import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rubble_canvas/rubble_canvas.dart';
import 'package:rubble_core/rubble_core.dart';

SitePoint p(double x, double y) => SitePoint(Meters(x), Meters(y));

const _style = RubbleCanvasStyle(
  background: Color(0xFFFFFFFF),
  gridMinor: Color(0xFFE0E0E0),
  gridMajor: Color(0xFFBDBDBD),
  outline: Color(0xFF0D47A1),
  corner: Color(0xFF0D47A1),
  highlight: Color(0xFFE65100),
  label: TextStyle(fontSize: 12, color: Color(0xFF000000)),
  labelBackground: Color(0xFFFFFFFF),
);

final _outline = RubblePolygon([p(0, 0), p(10, 0), p(10, 10), p(0, 10)]);

void main() {
  test('the view fits the outline with a margin, north up', () {
    final view = SiteMapView.fit(_outline, const Size(200, 200));
    // 10 m outline + 5 m margin each side = 20 m across 200 px: 10 px per metre.
    expect(view.toScreen(p(5, 5)), const Offset(100, 100));
    expect(view.toScreen(p(-5, 15)), Offset.zero);
    expect(view.toSite(const Offset(150, 50)), p(10, 10));
  });

  testWidgets('a tap reports the site point under the finger, snapped', (
    tester,
  ) async {
    SitePoint? tapped;
    await tester.pumpWidget(
      MaterialApp(
        home: Center(
          child: SizedBox.square(
            dimension: 200,
            child: SiteMap(
              outline: _outline,
              points: const [],
              style: _style,
              semanticLabel: 'map',
              onTap: (point) => tapped = point,
            ),
          ),
        ),
      ),
    );
    final origin = tester.getTopLeft(find.byType(SiteMap));
    // 126 px right of x = −5 m and 74 px below y = 15 m: (7.6, 7.6) m, snapped to (7.5, 7.5).
    await tester.tapAt(origin + const Offset(126, 74));
    expect(tapped, p(7.5, 7.5));
  });

  testWidgets('without onTap the map is read-only', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: SiteMap(
          outline: _outline,
          points: [MapPoint(at: p(2, 2), kind: MapPointKind.heard)],
          style: _style,
          semanticLabel: 'map',
        ),
      ),
    );
    await tester.tap(find.byType(SiteMap));
    expect(tester.takeException(), isNull);
  });

  test('points are equal only with the same label and strength', () {
    const at = SitePoint(Meters(1), Meters(2));
    expect(
      const MapPoint(at: at, kind: MapPointKind.heard, label: '−70'),
      const MapPoint(at: at, kind: MapPointKind.heard, label: '−70'),
    );
    expect(
      const MapPoint(at: at, kind: MapPointKind.heard, strength: 0.2),
      isNot(const MapPoint(at: at, kind: MapPointKind.heard, strength: 0.8)),
    );
  });
}
