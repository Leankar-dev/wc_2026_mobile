import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:wc_2026_mobile/ui/core/theme/theme.dart';
import 'package:wc_2026_mobile/ui/sticker/detail/widgets/quantity_counter.dart';

Widget _host({int count = 3, ValueChanged<int>? onChanged}) => MaterialApp(
  builder: (context, child) => MediaQuery(
    data: MediaQuery.of(context).copyWith(textScaler: TextScaler.linear(0.8)),
    child: child!,
  ),
  home: Scaffold(
    body: Center(
      child: QuantityCounter(count: count, onChanged: onChanged ?? (_) {}),
    ),
  ),
);

Finder get _buttons => find.descendant(
  of: find.byType(QuantityCounter),
  matching: find.byType(IconButton),
);

Color? _background(WidgetTester tester, int index) => tester
    .widget<IconButton>(_buttons.at(index))
    .style
    ?.backgroundColor
    ?.resolve({});

void main() {
  group('QuantityCounter', () {
    testWidgets('asks how many stickers the user has', (tester) async {
      await tester.pumpWidget(_host());

      expect(find.text('QUANTAS FIGURINHAS'), findsOneWidget);
      expect(find.text('VOCÊ TEM?'), findsOneWidget);
    });

    testWidgets('shows the current count', (tester) async {
      await tester.pumpWidget(_host(count: 7));

      expect(find.text('7'), findsOneWidget);
    });

    testWidgets('shows a zero count', (tester) async {
      await tester.pumpWidget(_host(count: 0));

      expect(find.text('0'), findsOneWidget);
    });

    testWidgets('shows a negative count without limits for now', (
      tester,
    ) async {
      await tester.pumpWidget(_host(count: -2));

      expect(find.text('-2'), findsOneWidget);
    });

    testWidgets('shows a very large count without overflowing', (
      tester,
    ) async {
      await tester.pumpWidget(_host(count: 123456));

      expect(find.text('123456'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('draws a minus and a plus button', (tester) async {
      await tester.pumpWidget(_host());

      expect(_buttons, findsNWidgets(2));
      expect(find.byIcon(Icons.remove), findsOneWidget);
      expect(find.byIcon(Icons.add), findsOneWidget);
    });

    testWidgets('highlights only the plus button', (tester) async {
      await tester.pumpWidget(_host());

      expect(_background(tester, 0), AppColors.white.withValues(alpha: .12));
      expect(_background(tester, 1), AppColors.yellow);
    });

    testWidgets('never reports a change for now', (tester) async {
      final changes = <int>[];

      await tester.pumpWidget(_host(count: 3, onChanged: changes.add));
      await tester.tap(find.byIcon(Icons.add));
      await tester.tap(find.byIcon(Icons.remove));
      await tester.pump();

      expect(changes, isEmpty);
    });

    testWidgets('keeps the count when a button is tapped', (tester) async {
      await tester.pumpWidget(_host(count: 3));
      await tester.tap(find.byIcon(Icons.add));
      await tester.pump();

      expect(find.text('3'), findsOneWidget);
    });

    testWidgets('keeps the height at eighty pixels', (tester) async {
      await tester.pumpWidget(_host());

      expect(tester.getSize(find.byType(QuantityCounter)).height, 80);
    });

    testWidgets('fits a narrow width without overflowing', (tester) async {
      tester.view.physicalSize = Size(320, 800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(_host(count: 12));

      expect(tester.takeException(), isNull);
    });
  });
}
