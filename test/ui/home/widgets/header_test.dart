import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:wc_2026_mobile/ui/home/widgets/header.dart';

Widget _host(Header header) => MaterialApp(
  builder: (context, child) => MediaQuery(
    data: MediaQuery.of(context).copyWith(textScaler: TextScaler.linear(0.8)),
    child: child!,
  ),
  home: Scaffold(appBar: header, body: SizedBox.shrink()),
);

void main() {
  group('Home Header', () {
    testWidgets('shows the greeting, the initials and the name', (
      tester,
    ) async {
      await tester.pumpWidget(
        _host(Header(initials: 'AL', name: 'Ada Lovelace')),
      );

      expect(find.text('OLÁ COLECIONADOR'), findsOneWidget);
      expect(find.text('AL'), findsOneWidget);
      expect(find.text('Ada Lovelace'), findsOneWidget);
    });

    testWidgets('shows the notification bell', (tester) async {
      await tester.pumpWidget(_host(Header(initials: 'AL', name: 'Ada')));

      expect(find.byIcon(Icons.notifications_none_rounded), findsOneWidget);
    });

    testWidgets('keeps a long name on a single line', (tester) async {
      await tester.pumpWidget(
        _host(Header(initials: 'AL', name: 'Ada ' * 30)),
      );

      final name = tester.widget<Text>(find.textContaining('Ada Ada'));

      expect(name.maxLines, 1);
      expect(name.overflow, TextOverflow.ellipsis);
    });

    testWidgets('renders without a name', (tester) async {
      await tester.pumpWidget(_host(Header(initials: '', name: '')));

      expect(find.text('OLÁ COLECIONADOR'), findsOneWidget);
    });

    test('declares the toolbar height', () {
      expect(
        Header(initials: 'AL', name: 'Ada').preferredSize,
        Size.fromHeight(68),
      );
    });
  });
}
