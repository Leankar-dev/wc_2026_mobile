import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:wc_2026_mobile/ui/album/album_screen.dart';
import 'package:wc_2026_mobile/ui/album/widgets/filter_tabs.dart';
import 'package:wc_2026_mobile/ui/album/widgets/header.dart';
import 'package:wc_2026_mobile/ui/album/widgets/sticker_tile.dart';
import 'package:wc_2026_mobile/ui/album/widgets/team_selection.dart';
import 'package:wc_2026_mobile/ui/album/widgets/team_strip.dart';

Widget _host() => MaterialApp(
  builder: (context, child) => MediaQuery(
    data: MediaQuery.of(context).copyWith(textScaler: TextScaler.linear(0.8)),
    child: child!,
  ),
  home: AlbumScreen(),
);

void _useTallScreen(WidgetTester tester) {
  tester.view.physicalSize = Size(390, 2400);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
}

void main() {
  group('AlbumScreen', () {
    testWidgets('shows the header and the search field', (tester) async {
      _useTallScreen(tester);

      await tester.pumpWidget(_host());

      expect(find.byType(Header), findsOneWidget);
      expect(find.byType(TextField), findsOneWidget);
      expect(find.text('Buscar figurinha, país ou nº…'), findsOneWidget);
      expect(find.byIcon(Icons.search), findsOneWidget);
    });

    testWidgets('accepts typing in the search field', (tester) async {
      _useTallScreen(tester);

      await tester.pumpWidget(_host());
      await tester.enterText(find.byType(TextField), 'bra');
      await tester.pump();

      expect(find.text('bra'), findsOneWidget);
    });

    testWidgets('shows the filter tabs with their counts', (tester) async {
      _useTallScreen(tester);

      await tester.pumpWidget(_host());

      Finder inTabs(String text) => find.descendant(
        of: find.byType(FilterTabs),
        matching: find.text(text),
      );

      expect(find.byType(FilterTabs), findsOneWidget);
      expect(inTabs('TODAS'), findsOneWidget);
      expect(inTabs('10'), findsOneWidget);
      expect(inTabs('20'), findsOneWidget);
      expect(inTabs('30'), findsOneWidget);
    });

    testWidgets('shows the team strip with Brazil selected', (tester) async {
      _useTallScreen(tester);

      await tester.pumpWidget(_host());

      final strip = tester.widget<TeamStrip>(find.byType(TeamStrip));

      expect(strip.selected, 'BRA');
      expect(strip.teams, hasLength(39));
      expect(strip.teams.map((team) => team.code), contains('BRA'));
    });

    testWidgets('keeps the team codes unique', (tester) async {
      _useTallScreen(tester);

      await tester.pumpWidget(_host());

      final codes = tester
          .widget<TeamStrip>(find.byType(TeamStrip))
          .teams
          .map((team) => team.code);

      expect(codes.toSet(), hasLength(codes.length));
    });

    testWidgets('shows the two team blocks with their progress', (
      tester,
    ) async {
      _useTallScreen(tester);

      await tester.pumpWidget(_host());

      final blocks = tester
          .widgetList<TeamSelection>(find.byType(TeamSelection))
          .toList();

      expect(blocks.map((block) => block.name), ['Brasil', 'BEL']);
      expect(blocks.map((block) => block.progress), ['2/21', '5/21']);
      expect(find.text('Brasil'), findsOneWidget);
      expect(find.text('2/21'), findsOneWidget);
      expect(find.text('5/21'), findsOneWidget);
    });

    testWidgets('shows six stickers per block, two collected', (tester) async {
      _useTallScreen(tester);

      await tester.pumpWidget(_host());

      final tiles = tester
          .widgetList<StickerTile>(find.byType(StickerTile))
          .toList();

      expect(tiles, hasLength(12));
      expect(tiles.where((tile) => tile.collected), hasLength(4));
      expect(find.text('— FALTANDO —'), findsNWidgets(8));
    });

    testWidgets('reaches the second block by scrolling', (tester) async {
      await tester.pumpWidget(_host());

      await tester.scrollUntilVisible(
        find.text('5/21'),
        300,
        scrollable: find.byType(Scrollable).first,
      );

      expect(find.text('5/21'), findsOneWidget);
    });

    testWidgets('refreshes without errors when pulled down', (tester) async {
      _useTallScreen(tester);

      await tester.pumpWidget(_host());
      await tester.fling(
        find.byType(CustomScrollView),
        Offset(0, 300),
        1000,
      );
      await tester.pumpAndSettle();

      expect(find.byType(AlbumScreen), findsOneWidget);
    });

    testWidgets('ignores taps on a team disc', (tester) async {
      _useTallScreen(tester);

      await tester.pumpWidget(_host());
      await tester.tap(
        find
            .descendant(
              of: find.byType(TeamStrip),
              matching: find.byType(InkWell),
            )
            .at(2),
      );
      await tester.pump();

      expect(find.byType(AlbumScreen), findsOneWidget);
    });

    testWidgets('logs the tab that was tapped', (tester) async {
      _useTallScreen(tester);

      final original = debugPrint;
      final logs = <String?>[];
      debugPrint = (message, {wrapWidth}) => logs.add(message);

      try {
        await tester.pumpWidget(_host());
        await tester.tap(find.text('FALTANDO'));
      } finally {
        debugPrint = original;
      }

      expect(logs, ['Alterando a tab StickerStatus.missing']);
    });

    testWidgets('ignores taps on the back button', (tester) async {
      _useTallScreen(tester);

      await tester.pumpWidget(_host());
      await tester.tap(find.byTooltip('Voltar'));
      await tester.pump();

      expect(find.byType(AlbumScreen), findsOneWidget);
    });
  });
}
