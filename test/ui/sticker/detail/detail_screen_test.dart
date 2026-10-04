import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:wc_2026_mobile/routing/routes.dart';
import 'package:wc_2026_mobile/ui/album/widgets/hero_card.dart';
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

DetailArgs _withCount(int count) => (
  code: _args.code,
  number: _args.number,
  team: _args.team,
  country: _args.country,
  teamColor: _args.teamColor,
  rare: _args.rare,
  count: count,
);

DetailArgs _withRare() => (
  code: _args.code,
  number: _args.number,
  team: _args.team,
  country: _args.country,
  teamColor: _args.teamColor,
  rare: true,
  count: _args.count,
);

Widget _host({
  EdgeInsets padding = EdgeInsets.zero,
  DetailArgs sticker = _args,
}) => MaterialApp(
  builder: (context, child) => MediaQuery(
    data: MediaQuery.of(context).copyWith(
      padding: padding,
      textScaler: TextScaler.linear(0.8),
    ),
    child: child!,
  ),
  home: DetailScreen(sticker: sticker),
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
  });

  group('DetailScreen card', () {
    testWidgets('shows the card with the data of the sticker', (tester) async {
      _useTallScreen(tester);

      await tester.pumpWidget(_host());

      final card = tester.widget<HeroCard>(find.byType(HeroCard));

      expect(card.number, 1);
      expect(card.team, 'Brazil');
      expect(card.country, 'BRA');
      expect(card.teamColor, Color(0xFFFFDF00));
    });

    testWidgets('shows the team name, the label and the number', (
      tester,
    ) async {
      _useTallScreen(tester);

      await tester.pumpWidget(_host());

      expect(find.text('BRAZIL'), findsOneWidget);
      expect(find.text('SELEÇÃO OFICIAL'), findsOneWidget);
      expect(find.text('01'), findsOneWidget);
    });

    testWidgets('marks the card as collected when the count is positive', (
      tester,
    ) async {
      _useTallScreen(tester);

      await tester.pumpWidget(_host(sticker: _args));

      expect(tester.widget<HeroCard>(find.byType(HeroCard)).collected, isTrue);
    });

    testWidgets('marks the card as not collected when the count is zero', (
      tester,
    ) async {
      _useTallScreen(tester);

      await tester.pumpWidget(_host(sticker: _withCount(0)));

      expect(tester.widget<HeroCard>(find.byType(HeroCard)).collected, isFalse);
    });

    testWidgets('marks the card as collected with a single copy', (
      tester,
    ) async {
      _useTallScreen(tester);

      await tester.pumpWidget(_host(sticker: _withCount(1)));

      expect(tester.widget<HeroCard>(find.byType(HeroCard)).collected, isTrue);
    });

    testWidgets('never marks the card as rare for now', (tester) async {
      _useTallScreen(tester);

      await tester.pumpWidget(_host(sticker: _withRare()));

      expect(tester.widget<HeroCard>(find.byType(HeroCard)).rare, isFalse);
    });

    testWidgets('keeps the backdrop colored even when not collected', (
      tester,
    ) async {
      _useTallScreen(tester);

      await tester.pumpWidget(_host(sticker: _withCount(0)));

      expect(tester.widget<HeroCard>(find.byType(HeroCard)).collected, isFalse);
      expect(tester.widget<Backdrop>(find.byType(Backdrop)).collected, isTrue);
      expect(find.text('03 / 980'), findsOneWidget);
    });

    testWidgets('centers the card below the top bar', (tester) async {
      _useTallScreen(tester);

      await tester.pumpWidget(_host());

      final card = tester.getRect(find.byType(HeroCard));
      final bar = tester.getRect(find.byType(TopBar));

      expect(card.top, greaterThan(bar.bottom));
      expect(card.center.dx, closeTo(195, 0.5));
    });

    testWidgets('scrolls when the screen is shorter than the card', (
      tester,
    ) async {
      tester.view.physicalSize = Size(390, 480);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(_host());

      final scrollable = tester.state<ScrollableState>(
        find.descendant(
          of: find.byType(SingleChildScrollView),
          matching: find.byType(Scrollable),
        ),
      );

      expect(scrollable.position.maxScrollExtent, greaterThan(0));
    });

    testWidgets('does not scroll when the card fits', (tester) async {
      tester.view.physicalSize = Size(390, 1200);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(_host());

      final scrollable = tester.state<ScrollableState>(
        find.descendant(
          of: find.byType(SingleChildScrollView),
          matching: find.byType(Scrollable),
        ),
      );

      expect(scrollable.position.maxScrollExtent, 0);
    });
  });

  group('DetailScreen back', () {
    GoRouter router({required String initialLocation}) => GoRouter(
      initialLocation: initialLocation,
      routes: [
        GoRoute(path: Routes.album, builder: (_, _) => Text('album page')),
        GoRoute(
          path: Routes.stickerPath,
          builder: (_, _) => DetailScreen(sticker: _args),
        ),
      ],
    );

    Widget app(GoRouter router) => MaterialApp.router(
      routerConfig: router,
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(
          textScaler: TextScaler.linear(0.8),
        ),
        child: child!,
      ),
    );

    testWidgets('closes the detail and reports no change when it can pop', (
      tester,
    ) async {
      _useTallScreen(tester);
      final appRouter = router(initialLocation: Routes.album);

      await tester.pumpWidget(app(appRouter));
      final result = appRouter.push<bool>(Routes.sticker('BRA-1'));
      await tester.pumpAndSettle();
      expect(find.byType(DetailScreen), findsOneWidget);

      await tester.tap(find.byIcon(Icons.arrow_back));
      await tester.pumpAndSettle();

      expect(find.byType(DetailScreen), findsNothing);
      expect(find.text('album page'), findsOneWidget);
      expect(await result, isFalse);
    });

    testWidgets('goes to the album when there is nothing to go back to', (
      tester,
    ) async {
      _useTallScreen(tester);
      final appRouter = router(initialLocation: Routes.sticker('BRA-1'));

      await tester.pumpWidget(app(appRouter));
      expect(find.byType(DetailScreen), findsOneWidget);

      await tester.tap(find.byIcon(Icons.arrow_back));
      await tester.pumpAndSettle();

      expect(find.byType(DetailScreen), findsNothing);
      expect(find.text('album page'), findsOneWidget);
    });

    testWidgets('keeps the screen open when the arrow is not tapped', (
      tester,
    ) async {
      _useTallScreen(tester);
      final appRouter = router(initialLocation: Routes.sticker('BRA-1'));

      await tester.pumpWidget(app(appRouter));
      await tester.pumpAndSettle();

      expect(find.byType(DetailScreen), findsOneWidget);
      expect(find.text('album page'), findsNothing);
    });
  });
}
