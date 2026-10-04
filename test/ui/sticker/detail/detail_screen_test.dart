import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:wc_2026_mobile/ui/core/theme/theme.dart';
import 'package:wc_2026_mobile/ui/sticker/detail/detail_screen.dart';
import 'package:wc_2026_mobile/ui/sticker/detail/widgets/backdrop.dart';
import 'package:wc_2026_mobile/ui/sticker/detail/widgets/top_bar.dart';

const DetailArgs _args = (
  code: 'BRA-1',
  number: 1,
  team: 'Brazil',
  country: 'BRA',
  teamColor: Color(0xFFFFDF00),
  rare: false,
  count: 2,
);

Widget _host({EdgeInsets padding = EdgeInsets.zero}) => MaterialApp(
  builder: (context, child) => MediaQuery(
    data: MediaQuery.of(context).copyWith(
      padding: padding,
      textScaler: TextScaler.linear(0.8),
    ),
    child: child!,
  ),
  home: DetailScreen(sticker: _args),
);

void _useTallScreen(WidgetTester tester) {
  tester.view.physicalSize = Size(390, 844);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
}

void main() {
  group('DetailScreen', () {
    testWidgets('shows the backdrop and the top bar', (tester) async {
      _useTallScreen(tester);

      await tester.pumpWidget(_host());

      expect(find.byType(Backdrop), findsOneWidget);
      expect(find.byType(TopBar), findsOneWidget);
    });

    testWidgets('keeps the sticker it was opened with', (tester) async {
      _useTallScreen(tester);

      await tester.pumpWidget(_host());

      expect(
        tester.widget<DetailScreen>(find.byType(DetailScreen)).sticker,
        _args,
      );
    });

    testWidgets('draws the backdrop as collected for now', (tester) async {
      _useTallScreen(tester);

      await tester.pumpWidget(_host());

      expect(tester.widget<Backdrop>(find.byType(Backdrop)).collected, isTrue);
    });

    testWidgets('shows fixed progress values for now', (tester) async {
      _useTallScreen(tester);

      await tester.pumpWidget(_host());

      final bar = tester.widget<TopBar>(find.byType(TopBar));

      expect(bar.number, 3);
      expect(bar.total, 980);
      expect(find.text('03 / 980'), findsOneWidget);
    });

    testWidgets('uses the dark color as the page background', (tester) async {
      _useTallScreen(tester);

      await tester.pumpWidget(_host());

      expect(
        tester.widget<Scaffold>(find.byType(Scaffold)).backgroundColor,
        AppColors.ink,
      );
    });

    testWidgets('asks for light status bar icons', (tester) async {
      _useTallScreen(tester);

      await tester.pumpWidget(_host());

      final region = tester.widget<AnnotatedRegion<SystemUiOverlayStyle>>(
        find
            .descendant(
              of: find.byType(DetailScreen),
              matching: find.byType(AnnotatedRegion<SystemUiOverlayStyle>),
            )
            .first,
      );

      expect(region.value, SystemUiOverlayStyle.light);
    });

    testWidgets('keeps the top bar below the status bar', (tester) async {
      _useTallScreen(tester);

      await tester.pumpWidget(_host(padding: EdgeInsets.only(top: 40)));

      expect(tester.getTopLeft(find.byType(TopBar)).dy, 40);
    });

    testWidgets('fills the whole screen with the backdrop', (tester) async {
      _useTallScreen(tester);

      await tester.pumpWidget(_host(padding: EdgeInsets.only(top: 40)));

      expect(tester.getSize(find.byType(Backdrop)), Size(390, 844));
    });

    testWidgets('does nothing when the back arrow is tapped for now', (
      tester,
    ) async {
      _useTallScreen(tester);

      await tester.pumpWidget(_host());
      await tester.tap(find.byIcon(Icons.arrow_back));
      await tester.pump();

      expect(find.byType(DetailScreen), findsOneWidget);
    });
  });
}
