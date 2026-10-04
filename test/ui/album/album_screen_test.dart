import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:wc_2026_mobile/ui/album/album_screen.dart';
import 'package:wc_2026_mobile/ui/album/widgets/filter_tabs.dart';
import 'package:wc_2026_mobile/ui/album/widgets/header.dart';
import 'package:wc_2026_mobile/ui/album/widgets/team_strip.dart';

Widget _host() => MaterialApp(
  builder: (context, child) => MediaQuery(
    data: MediaQuery.of(context).copyWith(textScaler: TextScaler.linear(0.8)),
    child: child!,
  ),
  home: AlbumScreen(),
);

void main() {
  group('AlbumScreen', () {
    testWidgets('shows the header and the filter tabs', (tester) async {
      await tester.pumpWidget(_host());

      expect(find.byType(Header), findsOneWidget);
      expect(find.byType(FilterTabs), findsOneWidget);
      expect(find.text('TODAS'), findsOneWidget);
    });

    testWidgets('shows the team strip with Brazil selected', (tester) async {
      await tester.pumpWidget(_host());

      final strip = tester.widget<TeamStrip>(find.byType(TeamStrip));

      expect(strip.selected, 'BRA');
      expect(strip.teams, hasLength(39));
      expect(strip.teams.map((team) => team.code), contains('BRA'));
    });

    testWidgets('keeps the team codes unique', (tester) async {
      await tester.pumpWidget(_host());

      final codes = tester
          .widget<TeamStrip>(find.byType(TeamStrip))
          .teams
          .map((team) => team.code);

      expect(codes.toSet(), hasLength(codes.length));
    });

    testWidgets('ignores taps on a team disc', (tester) async {
      await tester.pumpWidget(_host());
      await tester.tap(find.byType(InkWell).at(4));
      await tester.pump();

      expect(find.byType(AlbumScreen), findsOneWidget);
    });

    testWidgets('logs the tab that was tapped', (tester) async {
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
      await tester.pumpWidget(_host());
      await tester.tap(find.byTooltip('Voltar'));
      await tester.pump();

      expect(find.byType(AlbumScreen), findsOneWidget);
    });
  });
}
