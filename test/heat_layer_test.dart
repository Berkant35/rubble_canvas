import 'package:flutter_test/flutter_test.dart';
import 'package:rubble_canvas/rubble_canvas.dart';
import 'package:rubble_core/rubble_core.dart';

SitePoint p(double x, double y) => SitePoint(Meters(x), Meters(y));

void main() {
  test('a cell is in the 50 % region, the 90 % region or neither', () {
    final heat = HeatLayer(
      origin: p(0, 0),
      cell: const Meters(1),
      cols: 2,
      rows: 1,
      values: const [0.7, 0.3],
      threshold50: 0.7,
      threshold90: 0.3,
    );
    expect(heat.regionOf(0), HeatRegion.likely50);
    expect(heat.regionOf(1), HeatRegion.likely90);
    expect(
      HeatLayer(
        origin: p(0, 0),
        cell: const Meters(1),
        cols: 1,
        rows: 1,
        values: const [0],
        threshold50: 1,
        threshold90: 1,
      ).regionOf(0),
      HeatRegion.outside,
    );
  });

  test('values must fill the grid', () {
    expect(
      () => HeatLayer(
        origin: p(0, 0),
        cell: const Meters(1),
        cols: 2,
        rows: 2,
        values: const [1],
        threshold50: 1,
        threshold90: 1,
      ),
      throwsArgumentError,
    );
  });
}
