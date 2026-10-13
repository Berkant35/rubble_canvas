@Tags(['golden'])
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rubble_canvas/rubble_canvas.dart';
import 'package:rubble_core/rubble_core.dart';

SitePoint p(double x, double y) => SitePoint(Meters(x), Meters(y));

const _light = RubbleCanvasStyle(
  background: Color(0xFFF7F8FB),
  gridMinor: Color(0xFFE3E7EF),
  gridMajor: Color(0xFFC3CAD9),
  outline: Color(0xFF1F4FD1),
  corner: Color(0xFF1F4FD1),
  highlight: Color(0xFFD9480F),
  label: TextStyle(fontSize: 12, color: Color(0xFF111827)),
  labelBackground: Color(0xFFFFFFFF),
);

const _dark = RubbleCanvasStyle(
  background: Color(0xFF0E1525),
  gridMinor: Color(0xFF1C2740),
  gridMajor: Color(0xFF33456A),
  outline: Color(0xFF8DB2FF),
  corner: Color(0xFF8DB2FF),
  highlight: Color(0xFFFFA36B),
  label: TextStyle(fontSize: 12, color: Color(0xFFE6EBF5)),
  labelBackground: Color(0xFF0E1525),
);

final _lShape = const OutlineDraft.empty()
    .add(p(-8, -6))
    .add(p(8, -6))
    .add(p(8, 0))
    .add(p(0, 0))
    .add(p(0, 6))
    .add(p(-8, 6));

Widget _frame(Widget child) => MaterialApp(
  debugShowCheckedModeBanner: false,
  home: Center(
    child: RepaintBoundary(
      key: const ValueKey('golden'),
      child: SizedBox.square(dimension: 320, child: child),
    ),
  ),
);

void main() {
  for (final (name, style) in [('light', _light), ('dark', _dark)]) {
    testWidgets('editor with an L-shaped outline ($name)', (tester) async {
      await tester.pumpWidget(
        _frame(
          OutlineEditor(
            draft: _lShape,
            onChanged: (_) {},
            style: style,
            lengthLabel: (m) => '${m.value.toStringAsFixed(1)} m',
            semanticLabel: 'outline',
            scale: 1.1,
          ),
        ),
      );
      await expectLater(
        find.byKey(const ValueKey('golden')),
        matchesGoldenFile('editor_$name.png'),
      );
    });
  }

  testWidgets('edge picker with the second side selected', (tester) async {
    await tester.pumpWidget(
      _frame(
        EdgePicker(
          outline: _lShape.polygon!,
          selected: 1,
          onSelected: (_) {},
          style: _light,
          lengthLabel: (m) => '${m.value.toStringAsFixed(1)} m',
          semanticLabel: 'sides',
        ),
      ),
    );
    await expectLater(
      find.byKey(const ValueKey('golden')),
      matchesGoldenFile('edge_picker.png'),
    );
  });

  testWidgets('site map with heard, not heard and measuring points', (
    tester,
  ) async {
    await tester.pumpWidget(
      _frame(
        SiteMap(
          outline: _lShape.polygon!,
          points: [
            MapPoint(at: p(-10, -8), kind: MapPointKind.heard),
            MapPoint(at: p(10, -8), kind: MapPointKind.notHeard),
            MapPoint(at: p(10, 8), kind: MapPointKind.measuring),
          ],
          style: _light,
          semanticLabel: 'map',
        ),
      ),
    );
    await expectLater(
      find.byKey(const ValueKey('golden')),
      matchesGoldenFile('site_map.png'),
    );
  });

  testWidgets('site map with probability regions and a suggested point', (
    tester,
  ) async {
    // A blob of probability in the south-west part of the L: 50 % core, 90 % ring.
    const cols = 32;
    const rows = 24;
    final regions = <HeatRegion>[
      for (var r = 0; r < rows; r++)
        for (var c = 0; c < cols; c++)
          () {
            final dx = c - 8.0;
            final dy = r - 6.0;
            final d2 = dx * dx + dy * dy;
            return d2 < 20
                ? HeatRegion.likely50
                : (d2 < 60 ? HeatRegion.likely90 : HeatRegion.outside);
          }(),
    ];
    await tester.pumpWidget(
      _frame(
        SiteMap(
          outline: _lShape.polygon!,
          points: [
            MapPoint(at: p(-10, -8), kind: MapPointKind.heard),
            MapPoint(at: p(10, -8), kind: MapPointKind.notHeard),
            MapPoint(at: p(-10, 8), kind: MapPointKind.suggested),
            MapPoint(at: p(-6, 4), kind: MapPointKind.found),
          ],
          style: _light,
          semanticLabel: 'map',
          heat: HeatLayer(
            origin: p(-8, -6),
            cell: const Meters(0.5),
            cols: cols,
            rows: rows,
            regions: regions,
          ),
        ),
      ),
    );
    await expectLater(
      find.byKey(const ValueKey('golden')),
      matchesGoldenFile('site_map_heat.png'),
    );
  });

  testWidgets(
    'site map: signal labels warm with strength, and the likely spot with its circle',
    (tester) async {
      await tester.pumpWidget(
        _frame(
          SiteMap(
            outline: _lShape.polygon!,
            points: [
              MapPoint(
                at: p(-10, -8),
                kind: MapPointKind.heard,
                label: '−62',
                strength: 0.95,
              ),
              MapPoint(
                at: p(0, -8),
                kind: MapPointKind.heard,
                label: '−88',
                strength: 0.3,
              ),
              MapPoint(at: p(10, -8), kind: MapPointKind.notHeard),
            ],
            likely: (centre: p(-5, -3), radius: const Meters(2.5)),
            style: _light,
            semanticLabel: 'map',
          ),
        ),
      );
      await expectLater(
        find.byKey(const ValueKey('golden')),
        matchesGoldenFile('site_map_likely.png'),
      );
    },
  );
}
