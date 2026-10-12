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

/// Probabilities on a grid over the site, with the 50 % and 90 % thresholds — drawn as regions, never
/// as a single point. Kept free of any engine type: the app converts its map into this.
@immutable
final class HeatLayer {
  /// Creates a layer; [values] are row by row from the south (index = row × cols + col).
  HeatLayer({
    required this.origin,
    required this.cell,
    required this.cols,
    required this.rows,
    required List<double> values,
    required this.threshold50,
    required this.threshold90,
  }) : values = List.unmodifiable(values) {
    if (values.length != cols * rows) {
      throw ArgumentError.value(values.length, 'values', 'must be cols × rows');
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

  /// Probability per cell.
  final List<double> values;

  /// Cells with at least this probability are in the 50 % region.
  final double threshold50;

  /// Cells with at least this probability are in the 90 % region.
  final double threshold90;

  /// The region of cell [index]; a cell with probability 0 is never in a region.
  HeatRegion regionOf(int index) {
    final v = values[index];
    if (v <= 0) return HeatRegion.outside;
    if (v >= threshold50) return HeatRegion.likely50;
    if (v >= threshold90) return HeatRegion.likely90;
    return HeatRegion.outside;
  }
}
