import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:wc_2026_mobile/ui/album/widgets/header.dart';

Widget _host(Header header) => MaterialApp(
  builder: (context, child) => MediaQuery(
    data: MediaQuery.of(context).copyWith(textScaler: TextScaler.linear(0.8)),
    child: child!,
  ),
  home: Scaffold(appBar: header, body: SizedBox.shrink()),
);

void main() {
  group('Album Header', () {
    testWidgets('shows the album title', (tester) async {
      await tester.pumpWidget(_host(Header(onBack: () {})));

      expect(find.text('MEU'), findsOneWidget);
      expect(find.text('ÁLBUM'), findsOneWidget);
    });

    testWidgets('exposes the back button with a tooltip', (tester) async {
      await tester.pumpWidget(_host(Header(onBack: () {})));

      expect(find.byTooltip('Voltar'), findsOneWidget);
      expect(find.byIcon(Icons.arrow_back), findsOneWidget);
    });

    testWidgets('calls onBack when the back button is tapped', (tester) async {
      var backs = 0;

      await tester.pumpWidget(_host(Header(onBack: () => backs++)));
      await tester.tap(find.byTooltip('Voltar'));
      await tester.pump();

      expect(backs, 1);
    });

    testWidgets('shows the more button as a non interactive disc', (
      tester,
    ) async {
      await tester.pumpWidget(_host(Header(onBack: () {})));

      expect(find.byIcon(Icons.more_horiz), findsOneWidget);
      expect(find.byType(IconButton), findsOneWidget);
    });

    test('declares the toolbar height', () {
      expect(Header(onBack: () {}).preferredSize, Size.fromHeight(64));
    });
  });
}
