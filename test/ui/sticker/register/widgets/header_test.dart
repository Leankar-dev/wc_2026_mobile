import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wc_2026_mobile/ui/core/share/glass_bar.dart';
import 'package:wc_2026_mobile/ui/core/theme/theme.dart';
import 'package:wc_2026_mobile/ui/sticker/register/widgets/header.dart';

Widget _host({
  VoidCallback? onBack,
  Widget child = const SizedBox(key: Key('child'), width: 100, height: 100),
  EdgeInsets padding = EdgeInsets.zero,
}) => MaterialApp(
  builder: (context, c) => MediaQuery(
    data: MediaQuery.of(
      context,
    ).copyWith(padding: padding, textScaler: TextScaler.linear(0.8)),
    child: c!,
  ),
  home: Scaffold(
    body: SingleChildScrollView(
      child: Header(onBack: onBack ?? () {}, child: child),
    ),
  ),
);

void _useScreen(WidgetTester tester) {
  tester.view.physicalSize = Size(390, 900);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
}

void main() {
  group('Header', () {
    testWidgets('shows the title', (tester) async {
      _useScreen(tester);

      await tester.pumpWidget(_host());

      expect(find.text('ADICIONAR'), findsOneWidget);
      expect(find.text('FIGURINHA'), findsOneWidget);
    });

    testWidgets('uses the glass bar with a back arrow', (tester) async {
      _useScreen(tester);

      await tester.pumpWidget(_host());

      expect(find.byType(GlassBar), findsOneWidget);
      expect(find.byIcon(Icons.arrow_back), findsOneWidget);
    });

    testWidgets('calls onBack when the arrow is tapped', (tester) async {
      _useScreen(tester);
      var backs = 0;

      await tester.pumpWidget(_host(onBack: () => backs++));
      await tester.tap(find.byIcon(Icons.arrow_back));

      expect(backs, 1);
    });

    testWidgets('shows the child below the bar', (tester) async {
      _useScreen(tester);

      await tester.pumpWidget(_host());

      final bar = tester.getRect(find.byType(GlassBar));
      final child = tester.getRect(find.byKey(Key('child')));

      expect(child.top, greaterThan(bar.bottom));
    });

    testWidgets('leaves twenty two pixels between the bar and the child', (
      tester,
    ) async {
      _useScreen(tester);

      await tester.pumpWidget(_host());

      final bar = tester.getRect(find.byType(GlassBar));
      final child = tester.getRect(find.byKey(Key('child')));

      expect(child.top - bar.bottom, 22);
    });

    testWidgets('keeps the grid margin around the content', (tester) async {
      _useScreen(tester);

      await tester.pumpWidget(_host());

      final bar = tester.getRect(find.byType(GlassBar));

      expect(bar.left, AppDimens.gridMargin);
      expect(bar.right, 390 - AppDimens.gridMargin);
    });

    testWidgets('keeps the bar below the status bar', (tester) async {
      _useScreen(tester);

      await tester.pumpWidget(_host(padding: EdgeInsets.only(top: 40)));

      expect(tester.getTopLeft(find.byType(GlassBar)).dy, 50);
    });

    testWidgets('does not reserve the bottom inset', (tester) async {
      _useScreen(tester);

      await tester.pumpWidget(_host());
      final plain = tester.getSize(find.byType(Header)).height;

      await tester.pumpWidget(_host(padding: EdgeInsets.only(bottom: 34)));

      expect(tester.getSize(find.byType(Header)).height, plain);
    });

    testWidgets('grows with the child', (tester) async {
      _useScreen(tester);

      await tester.pumpWidget(
        _host(child: SizedBox(key: Key('child'), width: 100, height: 300)),
      );

      final tall = tester.getSize(find.byType(Header)).height;

      await tester.pumpWidget(_host());

      expect(tall - tester.getSize(find.byType(Header)).height, 200);
    });

    testWidgets('fills the width of the screen', (tester) async {
      _useScreen(tester);

      await tester.pumpWidget(_host());

      expect(tester.getSize(find.byType(Header)).width, 390);
    });
  });

  group('Header background', () {
    testWidgets('paints a dark base', (tester) async {
      _useScreen(tester);

      await tester.pumpWidget(_host());

      final base = tester.widget<ColoredBox>(
        find
            .descendant(
              of: find.byType(Header),
              matching: find.byType(ColoredBox),
            )
            .first,
      );

      expect(base.color, AppColors.ink);
    });

    testWidgets('draws the arc pattern', (tester) async {
      _useScreen(tester);

      await tester.pumpWidget(_host());

      expect(find.byType(SvgPicture), findsOneWidget);
    });

    testWidgets('anchors the pattern to the top and covers the area', (
      tester,
    ) async {
      _useScreen(tester);

      await tester.pumpWidget(_host());

      final pattern = tester.widget<SvgPicture>(find.byType(SvgPicture));

      expect(pattern.fit, BoxFit.cover);
      expect(pattern.alignment, Alignment.topCenter);
    });

    testWidgets('fades into the cream color at the bottom', (tester) async {
      _useScreen(tester);

      await tester.pumpWidget(_host());

      final gradient = tester
          .widgetList<DecoratedBox>(
            find.descendant(
              of: find.byType(Header),
              matching: find.byType(DecoratedBox),
            ),
          )
          .map((box) => box.decoration)
          .whereType<BoxDecoration>()
          .map((decoration) => decoration.gradient)
          .whereType<LinearGradient>()
          .single;

      expect(gradient.stops, [0, .7, 1]);
      expect(gradient.colors, [
        AppColors.ink.withValues(alpha: .25),
        AppColors.ink.withValues(alpha: .5),
        AppColors.cream,
      ]);
    });

    testWidgets('covers the whole header with the background', (tester) async {
      _useScreen(tester);

      await tester.pumpWidget(_host());

      final base = find
          .descendant(
            of: find.byType(Header),
            matching: find.byType(ColoredBox),
          )
          .first;

      expect(tester.getSize(base), tester.getSize(find.byType(Header)));
    });
  });
}
