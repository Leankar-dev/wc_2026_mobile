import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:wc_2026_mobile/ui/core/theme/theme.dart';
import 'package:wc_2026_mobile/ui/sticker/detail/widgets/backdrop.dart';

Widget _host({required bool collected}) => MaterialApp(
  home: Center(
    child: SizedBox(
      width: 390,
      height: 500,
      child: Backdrop(collected: collected),
    ),
  ),
);

Finder get _discs => find.descendant(
  of: find.byType(Backdrop),
  matching: find.byType(CircleAvatar),
);

List<Color?> _discColors(WidgetTester tester) => tester
    .widgetList<CircleAvatar>(_discs)
    .map((disc) => disc.backgroundColor)
    .toList();

void main() {
  group('Backdrop', () {
    testWidgets('draws three discs', (tester) async {
      await tester.pumpWidget(_host(collected: true));

      expect(_discs, findsNWidgets(3));
    });

    testWidgets('uses the colored palette when collected', (tester) async {
      await tester.pumpWidget(_host(collected: true));

      expect(_discColors(tester), [
        AppColors.green,
        AppColors.yellow,
        AppColors.blue.withValues(alpha: .9),
      ]);
    });

    testWidgets('uses the gray palette when not collected', (tester) async {
      await tester.pumpWidget(_host(collected: false));

      expect(_discColors(tester), [
        AppColors.gray,
        AppColors.grayLight,
        AppColors.grayDark,
      ]);
    });

    testWidgets('sizes the discs from the largest to the smallest', (
      tester,
    ) async {
      await tester.pumpWidget(_host(collected: true));

      final radii = tester
          .widgetList<CircleAvatar>(_discs)
          .map((disc) => disc.radius)
          .toList();

      expect(radii, [350, 250, 150]);
    });

    testWidgets('places the discs at fixed positions', (tester) async {
      await tester.pumpWidget(_host(collected: true));

      final positions = tester
          .widgetList<Positioned>(
            find.descendant(
              of: find.byType(Backdrop),
              matching: find.byType(Positioned),
            ),
          )
          .map((p) => (left: p.left, top: p.top))
          .toList();

      expect(positions, [
        (left: -150.0, top: -250.0),
        (left: 40.0, top: 400.0),
        (left: -150.0, top: 500.0),
      ]);
    });

    testWidgets('keeps the same positions on a larger screen', (tester) async {
      tester.view.physicalSize = Size(1200, 2000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        MaterialApp(home: Backdrop(collected: true)),
      );

      final first = tester.widgetList<Positioned>(
        find.descendant(
          of: find.byType(Backdrop),
          matching: find.byType(Positioned),
        ),
      );

      expect(first.map((p) => p.left), [-150.0, 40.0, -150.0]);
    });

    testWidgets('fills the available space', (tester) async {
      await tester.pumpWidget(_host(collected: true));

      expect(tester.getSize(find.byType(Backdrop)), Size(390, 500));
    });

    testWidgets('paints a dark base under the discs', (tester) async {
      await tester.pumpWidget(_host(collected: true));

      final base = tester.widget<ColoredBox>(
        find
            .descendant(
              of: find.byType(Backdrop),
              matching: find.byType(ColoredBox),
            )
            .first,
      );

      expect(base.color, AppColors.ink);
    });

    testWidgets('darkens the top with a gradient', (tester) async {
      await tester.pumpWidget(_host(collected: true));

      final gradient = tester
          .widgetList<DecoratedBox>(
            find.descendant(
              of: find.byType(Backdrop),
              matching: find.byType(DecoratedBox),
            ),
          )
          .map((box) => box.decoration)
          .whereType<BoxDecoration>()
          .map((decoration) => decoration.gradient)
          .whereType<LinearGradient>()
          .single;

      expect(gradient.colors, [
        AppColors.ink.withValues(alpha: .4),
        AppColors.ink.withValues(alpha: .1),
      ]);
      expect(gradient.begin, Alignment.topCenter);
      expect(gradient.end, Alignment.bottomCenter);
    });
  });
}
