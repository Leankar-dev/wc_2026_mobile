import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wc_2026_mobile/ui/core/share/team_flag.dart';
import 'package:wc_2026_mobile/ui/core/theme/theme.dart';
import 'package:wc_2026_mobile/ui/sticker/register/sticker_register_view_model.dart';
import 'package:wc_2026_mobile/ui/sticker/register/widgets/preview_card.dart';
import 'package:wc_2026_mobile/ui/sticker/widgets/sticker_desaturate.dart';

const StickerMatch _brazil = (
  code: 'BRA-01',
  color: Color(0xFF009C3B),
  flagPath: '/flags/bra.png',
  label: 'Brasil',
  number: '01',
  team: 'Brasil',
);

const StickerMatch _special = (
  code: 'FWC-03',
  color: Color(0xFF0E1117),
  flagPath: null,
  label: 'Especial',
  number: '03',
  team: 'Especiais',
);

Widget _host(Widget child) => MaterialApp(
  builder: (context, c) => MediaQuery(
    data: MediaQuery.of(context).copyWith(textScaler: TextScaler.linear(0.8)),
    child: c!,
  ),
  home: Scaffold(body: Center(child: child)),
);

Finder get _inCard =>
    find.descendant(of: find.byType(PreviewCard), matching: find.byType(Text));

Finder _assetImages() => find.descendant(
  of: find.byType(PreviewCard),
  matching: find.byWidgetPredicate((w) => w is Image && w.image is AssetImage),
);

Color? _headerColor(WidgetTester tester) => tester
    .widget<ColoredBox>(
      find
          .descendant(
            of: find.byType(PreviewCard),
            matching: find.byType(ColoredBox),
          )
          .first,
    )
    .color;

List<Color?> _discColors(WidgetTester tester) => tester
    .widgetList<CircleAvatar>(
      find.descendant(
        of: find.byType(PreviewCard),
        matching: find.byType(CircleAvatar),
      ),
    )
    .map((avatar) => avatar.backgroundColor)
    .toList();

void main() {
  group('PreviewCard identified', () {
    testWidgets('shows the team in capital letters', (tester) async {
      await tester.pumpWidget(_host(PreviewCard(match: _brazil)));

      expect(find.text('BRASIL'), findsOneWidget);
    });

    testWidgets('says it is a national team', (tester) async {
      await tester.pumpWidget(_host(PreviewCard(match: _brazil)));

      expect(find.text('SELEÇÃO'), findsOneWidget);
      expect(find.text('ESPECIAL'), findsNothing);
    });

    testWidgets('shows the number', (tester) async {
      await tester.pumpWidget(_host(PreviewCard(match: _brazil)));

      expect(find.text('Nº'), findsOneWidget);
      expect(find.text('01'), findsOneWidget);
    });

    testWidgets('shows the label in the pill', (tester) async {
      await tester.pumpWidget(_host(PreviewCard(match: _brazil)));

      expect(find.text('Brasil'), findsOneWidget);
      expect(find.text('DIGITE O CÓDIGO'), findsNothing);
    });

    testWidgets('paints the header with the color of the match', (
      tester,
    ) async {
      await tester.pumpWidget(_host(PreviewCard(match: _brazil)));

      expect(_headerColor(tester), _brazil.color);
    });

    testWidgets('uses the yellow accent on the disc and the number', (
      tester,
    ) async {
      await tester.pumpWidget(_host(PreviewCard(match: _brazil)));

      expect(_discColors(tester).first, AppColors.white);
      expect(_discColors(tester), contains(AppColors.yellow));
    });

    testWidgets('shows the flag of the team', (tester) async {
      await tester.pumpWidget(_host(PreviewCard(match: _brazil)));

      final flag = tester.widget<TeamFlag>(find.byType(TeamFlag));

      expect(flag.path, '/flags/bra.png');
    });

    testWidgets('keeps the art in color', (tester) async {
      await tester.pumpWidget(_host(PreviewCard(match: _brazil)));

      expect(
        tester.widget<StickerDesaturate>(find.byType(StickerDesaturate)).active,
        isFalse,
      );
    });
  });

  group('PreviewCard special', () {
    testWidgets('says it is a special sticker', (tester) async {
      await tester.pumpWidget(_host(PreviewCard(match: _special)));

      expect(find.text('ESPECIAL'), findsOneWidget);
      expect(find.text('SELEÇÃO'), findsNothing);
    });

    testWidgets('shows a star instead of a flag', (tester) async {
      await tester.pumpWidget(_host(PreviewCard(match: _special)));

      expect(find.byIcon(Icons.star_rounded), findsOneWidget);
      expect(find.byType(TeamFlag), findsNothing);
    });

    testWidgets('does not use the arrow icon', (tester) async {
      await tester.pumpWidget(_host(PreviewCard(match: _special)));

      expect(find.byIcon(Icons.start_rounded), findsNothing);
    });

    testWidgets('keeps the art in color', (tester) async {
      await tester.pumpWidget(_host(PreviewCard(match: _special)));

      expect(
        tester.widget<StickerDesaturate>(find.byType(StickerDesaturate)).active,
        isFalse,
      );
    });
  });

  group('PreviewCard without a match', () {
    testWidgets('waits for the code', (tester) async {
      await tester.pumpWidget(_host(PreviewCard(match: null)));

      expect(find.text('SEM TIME'), findsOneWidget);
      expect(find.text('AGUARDANDO'), findsOneWidget);
      expect(find.text('DIGITE O CÓDIGO'), findsOneWidget);
    });

    testWidgets('shows question marks for the unknown parts', (tester) async {
      await tester.pumpWidget(_host(PreviewCard(match: null)));

      expect(find.text('?'), findsNWidgets(2));
    });

    testWidgets('paints the header gray', (tester) async {
      await tester.pumpWidget(_host(PreviewCard(match: null)));

      expect(_headerColor(tester), AppColors.grayDark);
      expect(_discColors(tester), contains(AppColors.grayLight));
    });

    testWidgets('turns the art gray', (tester) async {
      await tester.pumpWidget(_host(PreviewCard(match: null)));

      expect(
        tester.widget<StickerDesaturate>(find.byType(StickerDesaturate)).active,
        isTrue,
      );
    });

    testWidgets('shows neither a flag nor a star', (tester) async {
      await tester.pumpWidget(_host(PreviewCard(match: null)));

      expect(find.byType(TeamFlag), findsNothing);
      expect(find.byIcon(Icons.star_rounded), findsNothing);
    });
  });

  group('PreviewCard layout', () {
    testWidgets(
      'keeps the size at one hundred and eighty by two thirty eight',
      (
        tester,
      ) async {
        await tester.pumpWidget(_host(PreviewCard(match: _brazil)));

        expect(tester.getSize(find.byType(PreviewCard)), Size(180, 238));
      },
    );

    testWidgets('draws a white card with rounded corners and a shadow', (
      tester,
    ) async {
      await tester.pumpWidget(_host(PreviewCard(match: _brazil)));

      final card = tester.widget<Container>(
        find
            .descendant(
              of: find.byType(PreviewCard),
              matching: find.byType(Container),
            )
            .first,
      );
      final decoration = card.decoration! as BoxDecoration;

      expect(decoration.color, AppColors.white);
      expect(decoration.borderRadius, AppDimens.borderRadiusMd);
      expect(decoration.boxShadow, AppShadows.lg);
    });

    testWidgets('keeps the header at forty six pixels', (tester) async {
      await tester.pumpWidget(_host(PreviewCard(match: _brazil)));

      final header = find
          .descendant(
            of: find.byType(PreviewCard),
            matching: find.byType(ColoredBox),
          )
          .first;

      expect(tester.getSize(header).height, 46);
    });

    testWidgets('fits a very long team name without overflowing', (
      tester,
    ) async {
      await tester.pumpWidget(
        _host(
          PreviewCard(
            match: (
              code: 'BIH-01',
              color: Color(0xFF002395),
              flagPath: '/flags/bih.png',
              label: 'Bosnia and Herzegovina Football Federation',
              number: '01',
              team: 'Bosnia and Herzegovina Football Federation',
            ),
          ),
        ),
      );

      expect(tester.takeException(), isNull);
      expect(_inCard, findsWidgets);
    });
  });

  group('StickerPreview art', () {
    testWidgets('draws the album image and the logo', (tester) async {
      await tester.pumpWidget(_host(PreviewCard(match: _brazil)));

      expect(_assetImages(), findsNWidgets(2));
    });

    testWidgets('draws the images stronger when identified', (tester) async {
      await tester.pumpWidget(_host(PreviewCard(match: _brazil)));

      final opacities = tester
          .widgetList<Image>(_assetImages())
          .map((image) => image.opacity!.value);

      expect(opacities, [0.8, 0.92]);
    });

    testWidgets('draws the images faded without a match', (tester) async {
      await tester.pumpWidget(_host(PreviewCard(match: null)));

      final opacities = tester
          .widgetList<Image>(_assetImages())
          .map((image) => image.opacity!.value);

      expect(opacities, [0.45, 0.35]);
    });

    testWidgets('stretches the album image and keeps the logo proportion', (
      tester,
    ) async {
      await tester.pumpWidget(_host(PreviewCard(match: _brazil)));

      final fits = tester
          .widgetList<Image>(_assetImages())
          .map((image) => image.fit);

      expect(fits, [BoxFit.fill, BoxFit.contain]);
    });

    testWidgets('paints the base and the overlay with the match color', (
      tester,
    ) async {
      await tester.pumpWidget(_host(PreviewCard(match: _brazil)));

      final colors = tester
          .widgetList<ColoredBox>(
            find.descendant(
              of: find.byType(StickerPreview),
              matching: find.byType(ColoredBox),
            ),
          )
          .map((box) => box.color)
          .toList();

      expect(colors, [_brazil.color, _brazil.color.withValues(alpha: .55)]);
    });

    testWidgets('paints the base and the overlay gray without a match', (
      tester,
    ) async {
      await tester.pumpWidget(_host(PreviewCard(match: null)));

      final colors = tester
          .widgetList<ColoredBox>(
            find.descendant(
              of: find.byType(StickerPreview),
              matching: find.byType(ColoredBox),
            ),
          )
          .map((box) => box.color)
          .toList();

      expect(colors, [AppColors.gray, AppColors.gray.withValues(alpha: .7)]);
    });

    testWidgets('fades the bottom with a gradient', (tester) async {
      await tester.pumpWidget(_host(PreviewCard(match: _brazil)));

      final gradient = tester
          .widgetList<DecoratedBox>(
            find.descendant(
              of: find.byType(StickerPreview),
              matching: find.byType(DecoratedBox),
            ),
          )
          .map((box) => box.decoration)
          .whereType<BoxDecoration>()
          .map((decoration) => decoration.gradient)
          .whereType<LinearGradient>()
          .single;

      expect(gradient.stops, [0, .6, 1]);
      expect(gradient.colors.last, AppColors.ink.withValues(alpha: .55));
    });

    testWidgets('shows the code in a dark pill', (tester) async {
      await tester.pumpWidget(_host(PreviewCard(match: _brazil)));

      final pill = tester.widget<Container>(
        find
            .ancestor(of: find.text('Brasil'), matching: find.byType(Container))
            .first,
      );
      final decoration = pill.decoration! as ShapeDecoration;

      expect(decoration.shape, isA<StadiumBorder>());
      expect(decoration.color, AppColors.ink.withValues(alpha: .85));
    });

    testWidgets('colors the pill text by the state', (tester) async {
      await tester.pumpWidget(_host(PreviewCard(match: _brazil)));
      expect(
        tester.widget<Text>(find.text('Brasil')).style?.color,
        AppColors.yellow,
      );

      await tester.pumpWidget(_host(PreviewCard(match: null)));
      expect(
        tester.widget<Text>(find.text('DIGITE O CÓDIGO')).style?.color,
        AppColors.grayLight,
      );
    });

    testWidgets('can be used alone with a size', (tester) async {
      await tester.pumpWidget(
        _host(
          SizedBox(
            width: 180,
            height: 190,
            child: StickerPreview(match: _brazil),
          ),
        ),
      );

      expect(tester.getSize(find.byType(StickerPreview)), Size(180, 190));
    });
  });
}
