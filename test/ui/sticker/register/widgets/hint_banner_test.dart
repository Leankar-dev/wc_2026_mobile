import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wc_2026_mobile/ui/core/share/team_flag.dart';
import 'package:wc_2026_mobile/ui/core/theme/theme.dart';
import 'package:wc_2026_mobile/ui/sticker/register/sticker_register_view_model.dart';
import 'package:wc_2026_mobile/ui/sticker/register/widgets/hint_banner.dart';

const StickerMatch _brazil = (
  code: 'BRA-01',
  color: Color(0xFF009C3B),
  flagPath: '/flags/bra.png',
  label: 'BRA-01',
  number: '01',
  team: 'Brasil',
);

const StickerMatch _special = (
  code: 'FWC-03',
  color: Color(0xFF0E1117),
  flagPath: null,
  label: 'FWC-03',
  number: '03',
  team: 'Especiais',
);

Widget _host(StickerMatch? match, {double width = 350}) => MaterialApp(
  builder: (context, child) => MediaQuery(
    data: MediaQuery.of(context).copyWith(textScaler: TextScaler.linear(0.8)),
    child: child!,
  ),
  home: Scaffold(
    body: Center(
      child: SizedBox(
        width: width,
        child: HintBanner(match: match),
      ),
    ),
  ),
);

BoxDecoration _pillDecoration(WidgetTester tester) =>
    tester
            .widget<Container>(
              find.descendant(
                of: find.byType(HintBanner),
                matching: find.byType(Container),
              ),
            )
            .decoration!
        as BoxDecoration;

ShapeDecoration _pill(WidgetTester tester) =>
    tester
            .widget<Container>(
              find
                  .descendant(
                    of: find.byType(HintBanner),
                    matching: find.byType(Container),
                  )
                  .first,
            )
            .decoration!
        as ShapeDecoration;

void main() {
  group('HintBanner without a match', () {
    testWidgets('explains the format of the code', (tester) async {
      await tester.pumpWidget(_host(null));

      expect(find.text('DIGITE 3 LETRAS DO TIME + 2 NÚMEROS'), findsOneWidget);
    });

    testWidgets('does not show the found state', (tester) async {
      await tester.pumpWidget(_host(null));

      expect(find.textContaining('ENCONTRADA'), findsNothing);
      expect(find.byIcon(Icons.check_rounded), findsNothing);
      expect(find.byType(TeamFlag), findsNothing);
    });

    testWidgets('uses a faint dark background', (tester) async {
      await tester.pumpWidget(_host(null));

      expect(_pill(tester).color, AppColors.ink.withValues(alpha: .05));
    });

    testWidgets('uses the gray text', (tester) async {
      await tester.pumpWidget(_host(null));

      expect(
        tester
            .widget<Text>(find.text('DIGITE 3 LETRAS DO TIME + 2 NÚMEROS'))
            .style
            ?.color,
        AppColors.grayText,
      );
    });
  });

  group('HintBanner with a team', () {
    testWidgets('says the sticker was found with its label', (tester) async {
      await tester.pumpWidget(_host(_brazil));

      expect(find.text('ENCONTRADA:  BRA-01 · '), findsOneWidget);
    });

    testWidgets('shows the team in capital letters', (tester) async {
      await tester.pumpWidget(_host(_brazil));

      expect(find.text(' BRASIL'), findsOneWidget);
    });

    testWidgets('shows a check and the flag of the team', (tester) async {
      await tester.pumpWidget(_host(_brazil));

      expect(find.byIcon(Icons.check_rounded), findsOneWidget);
      expect(
        tester.widget<TeamFlag>(find.byType(TeamFlag)).path,
        '/flags/bra.png',
      );
      expect(find.byIcon(Icons.star_rounded), findsNothing);
    });

    testWidgets('draws a rectangular flag of twelve pixels', (tester) async {
      await tester.pumpWidget(_host(_brazil));

      final flag = tester.widget<TeamFlag>(find.byType(TeamFlag));

      expect(flag.size, 12);
      expect(flag.circle, isFalse);
    });

    testWidgets('uses a faint green background', (tester) async {
      await tester.pumpWidget(_host(_brazil));

      expect(_pill(tester).color, AppColors.green.withValues(alpha: .1));
    });

    testWidgets('uses the green text', (tester) async {
      await tester.pumpWidget(_host(_brazil));

      expect(
        tester.widget<Text>(find.text(' BRASIL')).style?.color,
        AppColors.green,
      );
    });
  });

  group('HintBanner with a special sticker', () {
    testWidgets('shows a star instead of a flag', (tester) async {
      await tester.pumpWidget(_host(_special));

      expect(find.byIcon(Icons.star_rounded), findsOneWidget);
      expect(find.byType(TeamFlag), findsNothing);
    });

    testWidgets('keeps the check and the found text', (tester) async {
      await tester.pumpWidget(_host(_special));

      expect(find.byIcon(Icons.check_rounded), findsOneWidget);
      expect(find.text('ENCONTRADA:  FWC-03 · '), findsOneWidget);
      expect(find.text(' ESPECIAIS'), findsOneWidget);
    });
  });

  group('HintBanner layout', () {
    testWidgets('keeps the height at thirty six pixels', (tester) async {
      await tester.pumpWidget(_host(null));
      expect(tester.getSize(find.byType(HintBanner)).height, 36);

      await tester.pumpWidget(_host(_brazil));
      expect(tester.getSize(find.byType(HintBanner)).height, 36);
    });

    testWidgets('rounds the pill', (tester) async {
      await tester.pumpWidget(_host(null));

      expect(_pill(tester).shape, isA<StadiumBorder>());
    });

    testWidgets('shrinks a long team name instead of overflowing', (
      tester,
    ) async {
      await tester.pumpWidget(
        _host((
          code: 'BIH-01',
          color: Color(0xFF002395),
          flagPath: '/flags/bih.png',
          label: 'BIH-01',
          number: '01',
          team: 'Bosnia and Herzegovina Football Federation',
        ), width: 250),
      );

      expect(tester.takeException(), isNull);
      expect(tester.getSize(find.byType(HintBanner)).height, 36);
    });

    testWidgets('shrinks the hint on a narrow width', (tester) async {
      await tester.pumpWidget(_host(null, width: 200));

      expect(tester.takeException(), isNull);
    });

    testWidgets('keeps the same height whatever the state', (tester) async {
      await tester.pumpWidget(_host(_special));

      expect(tester.getSize(find.byType(HintBanner)).height, 36);
      expect(_pillDecoration, isNotNull);
    });
  });
}
