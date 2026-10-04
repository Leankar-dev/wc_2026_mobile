import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:wc_2026_mobile/ui/album/widgets/sticker_tile.dart';
import 'package:wc_2026_mobile/ui/core/theme/theme.dart';

const _teamColor = Color(0xFFFFDF00);

Widget _host({
  int number = 1,
  bool collected = true,
  String player = 'JOGADOR',
}) => MaterialApp(
  home: Scaffold(
    body: Center(
      child: SizedBox(
        width: 80,
        height: 104,
        child: StickerTile(
          number: number,
          label: 'BRA',
          player: player,
          teamColor: _teamColor,
          collected: collected,
        ),
      ),
    ),
  ),
);

BoxDecoration _rootDecoration(WidgetTester tester) {
  final root = tester.widget<Container>(
    find
        .descendant(
          of: find.byType(StickerTile),
          matching: find.byType(Container),
        )
        .first,
  );
  return root.decoration! as BoxDecoration;
}

List<double> _imageOpacities(WidgetTester tester) => tester
    .widgetList<Image>(find.byType(Image))
    .map((image) => image.opacity!.value)
    .toList();

ShapeDecoration _tagDecoration(WidgetTester tester, String text) {
  final tag = tester.widget<Container>(
    find.ancestor(of: find.text(text), matching: find.byType(Container)).first,
  );
  return tag.decoration! as ShapeDecoration;
}

void main() {
  group('StickerTile', () {
    testWidgets('shows the team label and the two digit number', (
      tester,
    ) async {
      await tester.pumpWidget(_host());

      expect(find.text('BRA'), findsOneWidget);
      expect(find.text('01'), findsOneWidget);
    });

    testWidgets('pads single digits and keeps two digit numbers', (
      tester,
    ) async {
      await tester.pumpWidget(_host(number: 7));
      expect(find.text('07'), findsOneWidget);

      await tester.pumpWidget(_host(number: 10));
      expect(find.text('10'), findsOneWidget);
    });

    testWidgets('shows the player when the sticker is collected', (
      tester,
    ) async {
      await tester.pumpWidget(_host(player: 'NEYMAR'));

      expect(find.text('NEYMAR'), findsOneWidget);
      expect(find.text('— FALTANDO —'), findsNothing);
    });

    testWidgets('shows the missing label when the sticker is not collected', (
      tester,
    ) async {
      await tester.pumpWidget(_host(collected: false, player: 'NEYMAR'));

      expect(find.text('— FALTANDO —'), findsOneWidget);
      expect(find.text('NEYMAR'), findsNothing);
    });

    testWidgets('uses the team color and the glow when collected', (
      tester,
    ) async {
      await tester.pumpWidget(_host());

      final decoration = _rootDecoration(tester);

      expect(decoration.color, _teamColor);
      expect(decoration.boxShadow, AppShadows.glow);
    });

    testWidgets('uses the gray color and no glow when not collected', (
      tester,
    ) async {
      await tester.pumpWidget(_host(collected: false));

      final decoration = _rootDecoration(tester);

      expect(decoration.color, AppColors.gray);
      expect(decoration.boxShadow, isNull);
    });

    testWidgets('draws the images stronger when collected', (tester) async {
      await tester.pumpWidget(_host());

      expect(_imageOpacities(tester), [0.8, 0.92]);
    });

    testWidgets('draws the images faded when not collected', (tester) async {
      await tester.pumpWidget(_host(collected: false));

      expect(_imageOpacities(tester), [0.5, 0.35]);
    });

    testWidgets('highlights the tags when collected', (tester) async {
      await tester.pumpWidget(_host());

      expect(_tagDecoration(tester, 'BRA').color, AppColors.yellow);
      expect(_tagDecoration(tester, '01').color, AppColors.white);
    });

    testWidgets('softens the tags when not collected', (tester) async {
      await tester.pumpWidget(_host(collected: false));

      final soft = AppColors.white.withValues(alpha: .6);

      expect(_tagDecoration(tester, 'BRA').color, soft);
      expect(_tagDecoration(tester, '01').color, soft);
    });
  });
}
