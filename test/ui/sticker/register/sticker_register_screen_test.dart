import 'package:flutter/material.dart' as flutter show AppBar, MaterialApp;
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:wc_2026_mobile/ui/sticker/register/sticker_register_screen.dart';
import 'package:wc_2026_mobile/ui/sticker/register/widgets/code_field.dart';
import 'package:wc_2026_mobile/ui/sticker/register/widgets/keypad.dart';

Widget _host() => flutter.MaterialApp(
  builder: (context, child) => MediaQuery(
    data: MediaQuery.of(context).copyWith(textScaler: TextScaler.linear(0.8)),
    child: child!,
  ),
  home: StickerRegisterScreen(),
);

void _useScreen(WidgetTester tester, {double height = 1400}) {
  tester.view.physicalSize = Size(390, height);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
}

Future<List<String?>> _capturingLogs(
  WidgetTester tester,
  Future<void> Function() body,
) async {
  final original = debugPrint;
  final logs = <String?>[];
  debugPrint = (message, {wrapWidth}) => logs.add(message);

  try {
    await body();
  } finally {
    debugPrint = original;
  }
  return logs;
}

ScrollableState _scrollable(WidgetTester tester) =>
    tester.state<ScrollableState>(
      find.descendant(
        of: find.byType(SingleChildScrollView),
        matching: find.byType(Scrollable),
      ),
    );

void main() {
  group('StickerRegisterScreen', () {
    testWidgets('shows an app bar', (tester) async {
      _useScreen(tester);

      await tester.pumpWidget(_host());

      expect(find.byType(flutter.AppBar), findsOneWidget);
    });

    testWidgets('shows the code field with six boxes', (tester) async {
      _useScreen(tester);

      await tester.pumpWidget(_host());

      final field = tester.widget<CodeField>(find.byType(CodeField));

      expect(field.length, 6);
      expect(field.letters, 3);
      expect(field.code, isEmpty);
    });

    testWidgets('shows the letters keypad and the digits keypad', (
      tester,
    ) async {
      _useScreen(tester);

      await tester.pumpWidget(_host());

      final keypads = tester
          .widgetList<Keypad>(find.byType(Keypad))
          .map((keypad) => keypad.letters)
          .toList();

      expect(keypads, [true, false]);
    });

    testWidgets('stacks the field above the keypads', (tester) async {
      _useScreen(tester);

      await tester.pumpWidget(_host());

      final field = tester.getTopLeft(find.byType(CodeField)).dy;
      final letters = tester.getTopLeft(find.byType(Keypad).first).dy;
      final digits = tester.getTopLeft(find.byType(Keypad).last).dy;

      expect(field, lessThan(letters));
      expect(letters, lessThan(digits));
    });

    testWidgets('logs the letter that was tapped', (tester) async {
      _useScreen(tester);
      await tester.pumpWidget(_host());

      final logs = await _capturingLogs(tester, () async {
        await tester.tap(find.text('V'));
      });

      expect(logs, ['V']);
    });

    testWidgets('logs the digit that was tapped', (tester) async {
      _useScreen(tester);
      await tester.pumpWidget(_host());

      final logs = await _capturingLogs(tester, () async {
        await tester.tap(find.text('5'));
      });

      expect(logs, ['5']);
    });

    testWidgets('does nothing when a backspace is tapped for now', (
      tester,
    ) async {
      _useScreen(tester);
      await tester.pumpWidget(_host());

      final logs = await _capturingLogs(tester, () async {
        await tester.tap(find.byIcon(Icons.backspace_outlined).first);
        await tester.pump();
      });

      expect(logs, isEmpty);
      expect(find.byType(StickerRegisterScreen), findsOneWidget);
    });
  });

  group('StickerRegisterScreen scroll', () {
    testWidgets('wraps the content in a scroll view', (tester) async {
      _useScreen(tester);

      await tester.pumpWidget(_host());

      expect(find.byType(SingleChildScrollView), findsOneWidget);
    });

    testWidgets('does not scroll when everything fits', (tester) async {
      _useScreen(tester, height: 1400);

      await tester.pumpWidget(_host());

      expect(_scrollable(tester).position.maxScrollExtent, 0);
    });

    testWidgets('scrolls when the screen is short', (tester) async {
      _useScreen(tester, height: 500);

      await tester.pumpWidget(_host());

      expect(_scrollable(tester).position.maxScrollExtent, greaterThan(0));
    });

    testWidgets('reaches the digits keypad on a short screen', (tester) async {
      _useScreen(tester, height: 500);
      await tester.pumpWidget(_host());

      await tester.scrollUntilVisible(
        find.byIcon(Icons.backspace_outlined).last,
        100,
        scrollable: find.descendant(
          of: find.byType(SingleChildScrollView),
          matching: find.byType(Scrollable),
        ),
      );

      expect(find.text('0'), findsOneWidget);
    });

    testWidgets('types a digit after scrolling on a short screen', (
      tester,
    ) async {
      _useScreen(tester, height: 500);
      await tester.pumpWidget(_host());

      await tester.scrollUntilVisible(
        find.text('9'),
        100,
        scrollable: find.descendant(
          of: find.byType(SingleChildScrollView),
          matching: find.byType(Scrollable),
        ),
      );
      final logs = await _capturingLogs(tester, () async {
        await tester.tap(find.text('9'));
      });

      expect(logs, ['9']);
    });

    testWidgets('does not overflow on a very short screen', (tester) async {
      _useScreen(tester, height: 300);

      await tester.pumpWidget(_host());

      expect(tester.takeException(), isNull);
    });

    testWidgets('does not overflow on a narrow screen', (tester) async {
      tester.view.physicalSize = Size(320, 700);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(_host());

      expect(tester.takeException(), isNull);
    });
  });
}
