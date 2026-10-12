import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';

/// Colours and text of the canvas. The app builds it from its theme (this package has no design-system
/// dependency).
@immutable
final class RubbleCanvasStyle {
  /// Creates a style.
  const RubbleCanvasStyle({
    required this.background,
    required this.gridMinor,
    required this.gridMajor,
    required this.outline,
    required this.corner,
    required this.highlight,
    required this.label,
    required this.labelBackground,
  });

  /// Behind the grid.
  final Color background;

  /// 1 m grid lines.
  final Color gridMinor;

  /// 5 m grid lines.
  final Color gridMajor;

  /// The outline's sides.
  final Color outline;

  /// Corner handles.
  final Color corner;

  /// A selected side.
  final Color highlight;

  /// Side-length labels.
  final TextStyle label;

  /// Behind side-length labels, so they stay readable over the grid.
  final Color labelBackground;
}
