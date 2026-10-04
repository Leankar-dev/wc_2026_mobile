import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:wc_2026_mobile/ui/album/widgets/hero_card.dart';
import 'package:wc_2026_mobile/ui/core/share/team_disc.dart';
import 'package:wc_2026_mobile/ui/core/theme/theme.dart';
import 'package:wc_2026_mobile/ui/sticker/widgets/sticker_desaturate.dart';

const _teamColor = Color(0xFF009C3B);

Widget _host({
  int number = 1,
  String team = 'Brazil',
  String country = 'BRA',
  bool rare = false,
  bool collected = true,
  double? width,
}) {
  final card = HeroCard(
    number: number,
    team: team,
    country: country,
    teamColor: _teamColor,
    rare: rare,
    collected: collected,
  );

  return MaterialApp(
    builder: (context, child) => MediaQuery(
      data: MediaQuery.of(context).copyWith(textScaler: TextScaler.linear(0.8)),
      child: child!,
    ),
    home: Scaffold(
      body: Center(
        child: width == null ? card : SizedBox(width: width, child: card),
      ),
    ),
  );
}

void _useTallScreen(WidgetTester tester, {double width = 390}) {
  tester.view.physicalSize = Size(width, 1200);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
}

Color? _headerColor(WidgetTester tester) => tester
    .widget<ColoredBox>(
      find
          .descendant(
            of: find.byType(HeroCard),
            matching: find.byType(ColoredBox),
          )
          .first,
    )
    .color;

Color? _numberBoxColor(WidgetTester tester, String number) {
  final container = tester.widget<Container>(
    find
        .ancestor(of: find.text(number), matching: find.byType(Container))
        .first,
  );
  return (container.decoration! as BoxDecoration).color;
}

void main() {
  group('HeroCard', () {
    testWidgets('shows the team name in capital letters', (tester) async {
      _useTallScreen(tester);

      await tester.pumpWidget(_host(team: 'Brazil'));

      expect(find.text('BRAZIL'), findsOneWidget);
    });

    testWidgets('shows the official team label', (tester) async {
      _useTallScreen(tester);

      await tester.pumpWidget(_host());

      expect(find.text('SELEÇÃO OFICIAL'), findsOneWidget);
    });

    testWidgets('shows the number with two digits', (tester) async {
      _useTallScreen(tester);

      await tester.pumpWidget(_host(number: 7));

      expect(find.text('Nº'), findsOneWidget);
      expect(find.text('07'), findsOneWidget);
    });

    testWidgets('keeps a number with two digits', (tester) async {
      _useTallScreen(tester);

      await tester.pumpWidget(_host(number: 12));

      expect(find.text('12'), findsOneWidget);
    });

    testWidgets('paints the header with the team color when collected', (
      tester,
    ) async {
      _useTallScreen(tester);

      await tester.pumpWidget(_host(collected: true));

      expect(_headerColor(tester), _teamColor);
      expect(_numberBoxColor(tester, '01'), AppColors.yellow);
    });

    testWidgets('paints the header gray when not collected', (tester) async {
      _useTallScreen(tester);

      await tester.pumpWidget(_host(collected: false));

      expect(_headerColor(tester), AppColors.grayDark);
      expect(_numberBoxColor(tester, '01'), AppColors.grayLight);
    });

    testWidgets('shows the flag disc with the team color and code', (
      tester,
    ) async {
      _useTallScreen(tester);

      await tester.pumpWidget(_host(country: 'ARG'));

      final disc = tester.widget<TeamDisc>(find.byType(TeamDisc));

      expect(disc.flagCode, 'ARG');
      expect(disc.flagPath, isNull);
      expect(disc.color, _teamColor);
    });

    testWidgets('keeps the header at seventy pixels', (tester) async {
      _useTallScreen(tester);

      await tester.pumpWidget(_host());

      final header = find
          .descendant(
            of: find.byType(HeroCard),
            matching: find.byType(ColoredBox),
          )
          .first;

      expect(tester.getSize(header).height, 70);
    });

    testWidgets('limits the card to two hundred and eighty pixels', (
      tester,
    ) async {
      _useTallScreen(tester, width: 800);

      await tester.pumpWidget(_host());

      expect(tester.getSize(find.byType(HeroCard)), Size(280, 400));
    });

    testWidgets('keeps the proportion on a narrower space', (tester) async {
      _useTallScreen(tester);

      await tester.pumpWidget(_host(width: 200));

      final size = tester.getSize(find.byType(HeroCard));

      expect(size.width, 200);
      expect(size.width / size.height, closeTo(280 / 400, 0.001));
    });

    testWidgets('draws a white card with rounded corners and a shadow', (
      tester,
    ) async {
      _useTallScreen(tester);

      await tester.pumpWidget(_host());

      final card = tester.widget<Container>(
        find
            .descendant(
              of: find.byType(HeroCard),
              matching: find.byType(Container),
            )
            .first,
      );
      final decoration = card.decoration! as BoxDecoration;

      expect(decoration.color, AppColors.white);
      expect(decoration.borderRadius, AppDimens.borderRadiusLg);
      expect(decoration.boxShadow, AppShadows.lg);
    });

    testWidgets('does not change with the rare flag for now', (tester) async {
      _useTallScreen(tester);

      await tester.pumpWidget(_host(rare: true));
      final rare = _headerColor(tester);

      await tester.pumpWidget(_host(rare: false));

      expect(_headerColor(tester), rare);
    });

    testWidgets('keeps the official label for the special section', (
      tester,
    ) async {
      _useTallScreen(tester);

      await tester.pumpWidget(_host(team: 'ESPECIAIS', country: 'FWC'));

      expect(find.text('ESPECIAIS'), findsOneWidget);
      expect(find.text('SELEÇÃO OFICIAL'), findsOneWidget);
    });

    testWidgets('overflows the header with a very long team name', (
      tester,
    ) async {
      _useTallScreen(tester);

      await tester.pumpWidget(
        _host(team: 'Bosnia and Herzegovina Football Federation'),
      );

      expect(tester.takeException(), isNotNull);
    });
  });

  group('HeroCard art', () {
    Finder inCard(Finder finder) =>
        find.descendant(of: find.byType(HeroCard), matching: finder);

    List<Color> boxColors(WidgetTester tester) => tester
        .widgetList<ColoredBox>(inCard(find.byType(ColoredBox)))
        .map((box) => box.color)
        .toList();

    Finder assetImages() => inCard(
      find.byWidgetPredicate((w) => w is Image && w.image is AssetImage),
    );

    List<Image> images(WidgetTester tester) =>
        tester.widgetList<Image>(assetImages()).toList();

    testWidgets('fills the space below the header with the art', (
      tester,
    ) async {
      _useTallScreen(tester);

      await tester.pumpWidget(_host());

      final album = assetImages().first;

      expect(tester.getSize(album), Size(280, 330));
    });

    testWidgets('paints the art with the team color when collected', (
      tester,
    ) async {
      _useTallScreen(tester);

      await tester.pumpWidget(_host(collected: true));

      expect(boxColors(tester), [
        _teamColor,
        _teamColor,
        _teamColor.withValues(alpha: .5),
      ]);
    });

    testWidgets('paints the art gray when not collected', (tester) async {
      _useTallScreen(tester);

      await tester.pumpWidget(_host(collected: false));

      expect(boxColors(tester), [
        AppColors.grayDark,
        AppColors.gray,
        AppColors.gray.withValues(alpha: .7),
      ]);
    });

    testWidgets('draws the album image and the logo', (tester) async {
      _useTallScreen(tester);

      await tester.pumpWidget(_host());

      expect(images(tester), hasLength(2));
    });

    testWidgets('draws the images stronger when collected', (tester) async {
      _useTallScreen(tester);

      await tester.pumpWidget(_host(collected: true));

      expect(images(tester).map((i) => i.opacity!.value), [0.8, 0.95]);
    });

    testWidgets('draws the images faded when not collected', (tester) async {
      _useTallScreen(tester);

      await tester.pumpWidget(_host(collected: false));

      expect(images(tester).map((i) => i.opacity!.value), [0.55, 0.35]);
    });

    testWidgets('stretches the album image and keeps the logo proportion', (
      tester,
    ) async {
      _useTallScreen(tester);

      await tester.pumpWidget(_host());

      expect(images(tester).map((i) => i.fit), [BoxFit.fill, BoxFit.contain]);
    });

    testWidgets('fades the bottom of the art with a gradient', (tester) async {
      _useTallScreen(tester);

      await tester.pumpWidget(_host(collected: true));

      final gradient = tester
          .widgetList<DecoratedBox>(inCard(find.byType(DecoratedBox)))
          .map((box) => box.decoration)
          .whereType<BoxDecoration>()
          .map((decoration) => decoration.gradient)
          .whereType<LinearGradient>()
          .single;

      expect(gradient.colors, [
        _teamColor.withValues(alpha: 0),
        _teamColor.withValues(alpha: .15),
        AppColors.ink.withValues(alpha: .6),
      ]);
    });

    testWidgets('keeps the flag in color when collected', (tester) async {
      _useTallScreen(tester);

      await tester.pumpWidget(_host(collected: true));

      expect(
        tester.widget<StickerDesaturate>(find.byType(StickerDesaturate)).active,
        isFalse,
      );
    });

    testWidgets('turns the flag gray when not collected', (tester) async {
      _useTallScreen(tester);

      await tester.pumpWidget(_host(collected: false));

      expect(
        tester.widget<StickerDesaturate>(find.byType(StickerDesaturate)).active,
        isTrue,
      );
    });

    testWidgets('puts only the flag disc under the desaturation', (
      tester,
    ) async {
      _useTallScreen(tester);

      await tester.pumpWidget(_host(collected: false));

      expect(
        find.descendant(
          of: find.byType(StickerDesaturate),
          matching: find.byType(TeamDisc),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: find.byType(StickerDesaturate),
          matching: find.text('BRAZIL'),
        ),
        findsNothing,
      );
    });
  });
}
