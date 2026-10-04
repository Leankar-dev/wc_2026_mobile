import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:wc_2026_mobile/ui/home/widgets/album_hero.dart';

Widget _host(Widget child) => MaterialApp(
  home: Scaffold(body: SingleChildScrollView(child: child)),
);

void main() {
  group('AlbumHero', () {
    testWidgets('shows the percentage, the counts and the progress bar', (
      tester,
    ) async {
      await tester.pumpWidget(_host(AlbumHero(collected: 680, total: 1000)));

      expect(find.text('68%'), findsOneWidget);
      expect(find.text('680 / 1000 FIGURINHAS'), findsOneWidget);
      expect(
        tester
            .widget<LinearProgressIndicator>(
              find.byType(LinearProgressIndicator),
            )
            .value,
        0.68,
      );
    });

    testWidgets('shows zero progress when the album has no stickers', (
      tester,
    ) async {
      await tester.pumpWidget(_host(AlbumHero(collected: 0, total: 0)));

      expect(find.text('0%'), findsOneWidget);
      expect(find.text('0 / 0 FIGURINHAS'), findsOneWidget);
      expect(
        tester
            .widget<LinearProgressIndicator>(
              find.byType(LinearProgressIndicator),
            )
            .value,
        0.0,
      );
    });

    testWidgets('shows the full progress when the album is complete', (
      tester,
    ) async {
      await tester.pumpWidget(_host(AlbumHero(collected: 980, total: 980)));

      expect(find.text('100%'), findsOneWidget);
    });
  });
}
