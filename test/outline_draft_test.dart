import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rubble_canvas/rubble_canvas.dart';
import 'package:rubble_core/rubble_core.dart';

SitePoint p(double x, double y) => SitePoint(Meters(x), Meters(y));

void main() {
  group('CanvasGeometry', () {
    const geometry = CanvasGeometry(halfExtent: Meters(50), pixelsPerMeter: 10);

    test('the workspace centre is the middle of the canvas, north is up', () {
      expect(geometry.canvasSize, const Size(1000, 1000));
      expect(geometry.toCanvas(p(0, 0)), const Offset(500, 500));
      expect(geometry.toCanvas(p(10, 5)), const Offset(600, 450));
    });

    test('canvas and site coordinates round-trip', () {
      final site = p(-12.5, 33.25);
      expect(geometry.toSite(geometry.toCanvas(site)), site);
    });

    test('snapping rounds to the nearest step', () {
      expect(CanvasGeometry.snap(p(1.24, -3.76), const Meters(0.5)), p(1, -4));
      expect(
        CanvasGeometry.snap(p(1.26, 0.25), const Meters(0.5)),
        p(1.5, 0.5),
      );
    });
  });

  group('OutlineDraft', () {
    final square = const OutlineDraft.empty()
        .add(p(0, 0))
        .add(p(10, 0))
        .add(p(10, 10))
        .add(p(0, 10));

    test('corners are added in order and form a polygon', () {
      expect(square.corners, [p(0, 0), p(10, 0), p(10, 10), p(0, 10)]);
      expect(square.problem, isNull);
      expect(square.polygon!.area.value, 100);
    });

    test('fewer than 3 corners is a problem and no polygon', () {
      final two = const OutlineDraft.empty().add(p(0, 0)).add(p(5, 0));
      expect(two.problem, isA<TooFewCorners>());
      expect(two.polygon, isNull);
    });

    test('a crossing outline reports the problem', () {
      final bowTie = const OutlineDraft.empty()
          .add(p(0, 0))
          .add(p(10, 10))
          .add(p(10, 0))
          .add(p(0, 10));
      expect(bowTie.problem, isA<SelfIntersecting>());
    });

    test('a corner is moved, and undo brings it back', () {
      final moved = square.move(2, p(12, 12));
      expect(moved.corners[2], p(12, 12));
      expect(moved.undo().corners[2], p(10, 10));
    });

    test('undo walks back every change, then does nothing', () {
      var draft = square;
      for (var i = 0; i < 4; i++) {
        draft = draft.undo();
      }
      expect(draft.corners, isEmpty);
      expect(draft.undo(), draft);
      expect(draft.canUndo, isFalse);
    });

    test('clear empties the outline and can be undone', () {
      final cleared = square.clear();
      expect(cleared.corners, isEmpty);
      expect(cleared.undo().corners, square.corners);
    });

    test('the corner near a point is found within the tolerance', () {
      expect(square.cornerNear(p(9.6, 10.3), const Meters(0.6)), 2);
      expect(square.cornerNear(p(5, 5), const Meters(0.6)), isNull);
    });

    test('the side near a point is found within the tolerance', () {
      expect(square.edgeNear(p(5, 0.4), const Meters(0.5)), 0);
      expect(square.edgeNear(p(0.3, 5), const Meters(0.5)), 3);
      expect(square.edgeNear(p(5, 5), const Meters(0.5)), isNull);
    });

    test('starts from a stored outline', () {
      final stored = OutlineDraft.from(square.polygon!);
      expect(stored.corners, square.corners);
      expect(stored.canUndo, isFalse);
    });

    test('drafts with the same corners are equal', () {
      expect(
        const OutlineDraft.empty().add(p(1, 1)),
        const OutlineDraft.empty().add(p(1, 1)),
      );
    });
  });
}
