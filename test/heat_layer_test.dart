import 'package:flutter_test/flutter_test.dart';
import 'package:rubble_canvas/rubble_canvas.dart';
import 'package:rubble_core/rubble_core.dart';

SitePoint p(double x, double y) => SitePoint(Meters(x), Meters(y));

void main() {
  test('each cell keeps the region it was given', () {
    final heat = HeatLayer(
      origin: p(0, 0),
      cell: const Meters(1),
      cols: 3,
      rows: 1,
      regions: const [
        HeatRegion.likely50,
        HeatRegion.likely90,
        HeatRegion.outside,
      ],
    );
    expect(heat.regionOf(0), HeatRegion.likely50);
    expect(heat.regionOf(1), HeatRegion.likely90);
    expect(heat.regionOf(2), HeatRegion.outside);
  });

  test('regions must fill the grid', () {
    expect(
      () => HeatLayer(
        origin: p(0, 0),
        cell: const Meters(1),
        cols: 2,
        rows: 2,
        regions: const [HeatRegion.likely50],
      ),
      throwsArgumentError,
    );
  });

  test('the regions cannot be changed afterwards', () {
    final regions = [HeatRegion.likely50];
    final heat = HeatLayer(
      origin: p(0, 0),
      cell: const Meters(1),
      cols: 1,
      rows: 1,
      regions: regions,
    );
    regions[0] = HeatRegion.outside;
    expect(heat.regionOf(0), HeatRegion.likely50);
  });
}
