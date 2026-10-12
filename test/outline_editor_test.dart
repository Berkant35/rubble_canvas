import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rubble_canvas/rubble_canvas.dart';
import 'package:rubble_core/rubble_core.dart';

SitePoint p(double x, double y) => SitePoint(Meters(x), Meters(y));

/// 10 px per metre and a 300 px view spanning 30 m: zoom 1, the origin in the middle of the view.
const _geometry = CanvasGeometry(halfExtent: Meters(50), pixelsPerMeter: 10);

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

class _Host extends StatefulWidget {
  const _Host(this.initial, this.changes);
  final OutlineDraft initial;
  final List<OutlineDraft> changes;

  @override
  State<_Host> createState() => _HostState();
}

class _HostState extends State<_Host> {
  late OutlineDraft draft = widget.initial;

  @override
  Widget build(BuildContext context) => MaterialApp(
    home: Center(
      child: SizedBox.square(
        dimension: 300,
        child: OutlineEditor(
          draft: draft,
          geometry: _geometry,
          style: _style,
          viewSpan: const Meters(30),
          initialCenter: const SitePoint(Meters.zero, Meters.zero),
          lengthLabel: (m) => '${m.value.toStringAsFixed(1)} m',
          semanticLabel: 'outline',
          onChanged: (next) {
            widget.changes.add(next);
            setState(() => draft = next);
          },
        ),
      ),
    ),
  );
}

Offset _screen(WidgetTester tester, SitePoint site) =>
    tester.getCenter(find.byType(OutlineEditor)) +
    Offset(site.x.value * 10, -site.y.value * 10);

void main() {
  testWidgets('a tap adds a corner, snapped to half a metre', (tester) async {
    final changes = <OutlineDraft>[];
    await tester.pumpWidget(_Host(const OutlineDraft.empty(), changes));
    await tester.tapAt(_screen(tester, p(2.04, 0.96)));
    await tester.pumpAndSettle();
    expect(changes.single.corners, [p(2, 1)]);
  });

  testWidgets(
    'dragging a corner moves it, the view stays; one undo restores it',
    (tester) async {
      final changes = <OutlineDraft>[];
      final start = const OutlineDraft.empty()
          .add(p(0, 0))
          .add(p(5, 0))
          .add(p(5, 5));
      await tester.pumpWidget(_Host(start, changes));
      final gesture = await tester.startGesture(_screen(tester, p(5, 5)));
      for (var i = 1; i <= 12; i++) {
        await gesture.moveTo(_screen(tester, p(5 + i * 0.5, 5 + i * 0.5)));
        await tester.pump();
      }
      await gesture.up();
      await tester.pumpAndSettle();
      expect(changes.last.corners, [p(0, 0), p(5, 0), p(11, 11)]);
      // The corner stays under the finger only if the view did not pan with it.
      final viewer = tester.widget<InteractiveViewer>(
        find.byType(InteractiveViewer),
      );
      final translation = viewer.transformationController!.value
          .getTranslation();
      expect((translation.x, translation.y), (-350.0, -350.0));
      expect(changes.last.undo().corners, start.corners);
    },
  );

  testWidgets('dragging empty space pans the view and changes nothing', (
    tester,
  ) async {
    final changes = <OutlineDraft>[];
    final start = const OutlineDraft.empty().add(p(0, 0));
    await tester.pumpWidget(_Host(start, changes));
    await tester.dragFrom(_screen(tester, p(-5, -5)), const Offset(80, 40));
    await tester.pumpAndSettle();
    expect(changes, isEmpty);
    // The corner at the origin moved on screen with the view.
    final viewer = tester.widget<InteractiveViewer>(
      find.byType(InteractiveViewer),
    );
    final translation = viewer.transformationController!.value.getTranslation();
    expect(
      translation.x,
      greaterThan(-350 + 40),
    ); // moved right with the finger
  });

  testWidgets('a tap on a corner does not add another', (tester) async {
    final changes = <OutlineDraft>[];
    final start = const OutlineDraft.empty().add(p(0, 0)).add(p(5, 0));
    await tester.pumpWidget(_Host(start, changes));
    await tester.tapAt(_screen(tester, p(5.2, 0.1)));
    await tester.pumpAndSettle();
    expect(changes, isEmpty);
  });

  testWidgets('EdgePicker selects the tapped side', (tester) async {
    int? selected;
    final square = const OutlineDraft.empty()
        .add(p(0, 0))
        .add(p(10, 0))
        .add(p(10, 10))
        .add(p(0, 10));
    await tester.pumpWidget(
      MaterialApp(
        home: Center(
          child: SizedBox.square(
            dimension: 200,
            child: EdgePicker(
              outline: square.polygon!,
              selected: 0,
              style: _style,
              lengthLabel: (m) => '${m.value} m',
              semanticLabel: 'sides',
              onSelected: (i) => selected = i,
            ),
          ),
        ),
      ),
    );
    final box = tester.getRect(find.byType(EdgePicker));
    // 200 px box, 56 px room for labels: the right side is 56 px from the edge.
    await tester.tapAt(Offset(box.right - 50, box.center.dy));
    expect(selected, 1);
  });
}
