import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:rubble_core/rubble_core.dart';

/// The outline being drawn: corners in order plus the history for undo. Immutable — every change
/// returns a new draft.
@immutable
final class OutlineDraft {
  /// An empty draft.
  const OutlineDraft.empty() : corners = const [], _history = const [];

  /// A draft starting from a stored outline (nothing to undo).
  OutlineDraft.from(RubblePolygon outline)
    : corners = outline.corners,
      _history = const [];

  const OutlineDraft._(this.corners, this._history);

  /// Corners in drawing order.
  final List<SitePoint> corners;

  /// Earlier corner lists, oldest first.
  final List<List<SitePoint>> _history;

  /// Whether [undo] changes anything.
  bool get canUndo => _history.isNotEmpty;

  OutlineDraft _next(List<SitePoint> corners) => OutlineDraft._(
    List.unmodifiable(corners),
    List.unmodifiable([..._history, this.corners]),
  );

  /// Adds [corner] after the last one; a corner on top of an existing one changes nothing.
  OutlineDraft add(SitePoint corner) =>
      corners.contains(corner) ? this : _next([...corners, corner]);

  /// Moves corner [index] to [to].
  OutlineDraft move(int index, SitePoint to) =>
      _next([...corners]..[index] = to);

  /// Removes every corner (undoable).
  OutlineDraft clear() => corners.isEmpty ? this : _next(const []);

  /// The draft before the last change.
  OutlineDraft undo() => canUndo
      ? OutlineDraft._(
          _history.last,
          List.unmodifiable(_history.sublist(0, _history.length - 1)),
        )
      : this;

  /// What is wrong with the outline, or null when it is a valid rubble outline.
  PolygonProblem? get problem => RubblePolygon.validate(corners);

  /// The outline, or null while [problem] is not null.
  RubblePolygon? get polygon => problem == null ? RubblePolygon(corners) : null;

  /// The nearest corner within [tolerance] of [point], or null.
  int? cornerNear(SitePoint point, Meters tolerance) => _nearest(
    corners.length,
    (i) => corners[i].distanceTo(point).value,
    tolerance,
  );

  /// The nearest side (from corner `i` to the next) within [tolerance] of [point], or null. The closing
  /// side counts once there are three corners.
  int? edgeNear(SitePoint point, Meters tolerance) {
    final sides = corners.length >= 3 ? corners.length : corners.length - 1;
    return _nearest(
      math.max(sides, 0),
      (i) => _distanceToSegment(
        point,
        corners[i],
        corners[(i + 1) % corners.length],
      ),
      tolerance,
    );
  }

  static int? _nearest(
    int count,
    double Function(int) distance,
    Meters tolerance,
  ) {
    int? best;
    var bestDistance = tolerance.value;
    for (var i = 0; i < count; i++) {
      final d = distance(i);
      if (d <= bestDistance) {
        best = i;
        bestDistance = d;
      }
    }
    return best;
  }

  static double _distanceToSegment(SitePoint p, SitePoint a, SitePoint b) {
    final (abx, aby) = (b.x.value - a.x.value, b.y.value - a.y.value);
    final lengthSquared = abx * abx + aby * aby;
    final t = lengthSquared == 0
        ? 0.0
        : (((p.x.value - a.x.value) * abx + (p.y.value - a.y.value) * aby) /
                  lengthSquared)
              .clamp(0.0, 1.0);
    final closest = SitePoint(
      Meters(a.x.value + t * abx),
      Meters(a.y.value + t * aby),
    );
    return closest.distanceTo(p).value;
  }

  @override
  bool operator ==(Object other) =>
      other is OutlineDraft &&
      listEquals(other.corners, corners) &&
      other._history.length == _history.length;

  /// Same corners and the same number of steps to undo: a corner moved away and back is a different
  /// draft, so listeners rebuild and undo keeps walking back.
  @override
  int get hashCode => Object.hash(Object.hashAll(corners), _history.length);
}
