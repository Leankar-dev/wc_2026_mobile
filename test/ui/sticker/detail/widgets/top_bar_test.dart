import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:wc_2026_mobile/ui/core/share/glass_bar.dart';
import 'package:wc_2026_mobile/ui/core/theme/theme.dart';
import 'package:wc_2026_mobile/ui/sticker/detail/widgets/top_bar.dart';

Widget _host({
  int number = 3,
  int total = 980,
  VoidCallback? onBack,
}) => MaterialApp(
  builder: (context, child) => MediaQuery(
    data: MediaQuery.of(context).copyWith(textScaler: TextScaler.linear(0.8)),
    child: child!,
  ),
  home: Scaffold(
    body: TopBar(number: number, total: total, onBack: onBack ?? () {}),
  ),
);

void main() {
  group('TopBar', () {
    testWidgets('shows the number and the total', (tester) async {
      await tester.pumpWidget(_host());

      expect(find.text('03 / 980'), findsOneWidget);
    });

    testWidgets('pads a single digit number to two digits', (tester) async {
      await tester.pumpWidget(_host(number: 7));

      expect(find.text('07 / 980'), findsOneWidget);
    });

    testWidgets('keeps a number with more than two digits', (tester) async {
      await tester.pumpWidget(_host(number: 125, total: 980));

      expect(find.text('125 / 980'), findsOneWidget);
    });

    testWidgets('does not pad the total', (tester) async {
      await tester.pumpWidget(_host(number: 3, total: 20));

      expect(find.text('03 / 20'), findsOneWidget);
    });

    testWidgets('uses the glass bar with a back arrow', (tester) async {
      await tester.pumpWidget(_host());

      expect(find.byType(GlassBar), findsOneWidget);
      expect(find.byIcon(Icons.arrow_back), findsOneWidget);
    });

    testWidgets('calls onBack when the arrow is tapped', (tester) async {
      var backs = 0;

      await tester.pumpWidget(_host(onBack: () => backs++));
      await tester.tap(find.byIcon(Icons.arrow_back));

      expect(backs, 1);
    });

    testWidgets('draws the progress inside a pill', (tester) async {
      await tester.pumpWidget(_host());

      final pill = tester.widget<Container>(
        find
            .ancestor(
              of: find.text('03 / 980'),
              matching: find.byType(Container),
            )
            .first,
      );
      final decoration = pill.decoration! as ShapeDecoration;

      expect(decoration.shape, isA<StadiumBorder>());
      expect(decoration.color, AppColors.ink.withValues(alpha: .5));
      expect(
        tester.getSize(
          find
              .ancestor(
                of: find.text('03 / 980'),
                matching: find.byType(Container),
              )
              .first,
        ),
        Size(120, 26),
      );
    });

    testWidgets('keeps the pill at the same width for any number', (
      tester,
    ) async {
      await tester.pumpWidget(_host(number: 125));

      final size = tester.getSize(
        find
            .ancestor(
              of: find.text('125 / 980'),
              matching: find.byType(Container),
            )
            .first,
      );

      expect(size.width, 120);
    });

    testWidgets('keeps the grid margin on both sides', (tester) async {
      await tester.pumpWidget(_host());

      final bar = tester.getRect(find.byType(GlassBar));

      expect(bar.left, AppDimens.gridMargin);
      expect(bar.right, 800 - AppDimens.gridMargin);
    });

    testWidgets('leaves ten pixels above the bar', (tester) async {
      await tester.pumpWidget(_host());

      expect(tester.getTopLeft(find.byType(GlassBar)).dy, 10);
    });
  });
}
