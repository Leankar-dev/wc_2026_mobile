import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:wc_2026_mobile/ui/album/album_screen.dart';
import 'package:wc_2026_mobile/ui/album/widgets/filter_tabs.dart';
import 'package:wc_2026_mobile/ui/album/widgets/header.dart';

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
