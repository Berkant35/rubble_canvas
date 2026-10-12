import 'package:flutter/foundation.dart';
import 'package:rubble_core/rubble_core.dart';

/// Which probability region a cell belongs to.
enum HeatRegion {
  /// In the smallest area holding 50 % of the probability: the most likely area.
  likely50,

  /// In the 90 % area but not the 50 % one.
  likely90,

  /// Outside both.
  outside,
}

/// The 50 % and 90 % probability regions on a grid over the site — drawn as regions, never as a single
/// point. Kept free of any engine type: the app converts its map into this.
@immutable
final class HeatLayer {
  /// Creates a layer; [regions] are row by row from the south (index = row × cols + col).
  HeatLayer({
    required this.origin,
    required this.cell,
    required this.cols,
    required this.rows,
    required List<HeatRegion> regions,
  }) : _regions = List.unmodifiable(regions) {
    if (regions.length != cols * rows) {
      throw ArgumentError.value(
        regions.length,
        'regions',
        'must be cols × rows',
      );
    }
  }

  /// South-west corner of the grid.
  final SitePoint origin;

  /// Cell size.
  final Meters cell;

  /// Cells west → east.
  final int cols;

  /// Cells south → north.
  final int rows;

  final List<HeatRegion> _regions;

  /// Number of cells.
  int get length => _regions.length;

  /// The region of cell [index].
  HeatRegion regionOf(int index) => _regions[index];
}
