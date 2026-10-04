import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:wc_2026_mobile/ui/core/theme/theme.dart';
import 'package:wc_2026_mobile/ui/sticker/register/widgets/code_field.dart';

Widget _host({String code = '', int length = 6, int letters = 3}) =>
    MaterialApp(
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(
          context,
        ).copyWith(textScaler: TextScaler.linear(0.8)),
        child: child!,
      ),
      home: Scaffold(
        body: Center(
          child: SizedBox(
            width: 350,
            child: CodeField(code: code, length: length, letters: letters),
          ),
        ),
      ),
    );

Finder get _boxes => find.descendant(
  of: find.byType(CodeField),
  matching: find.byType(DecoratedBox),
);

BoxDecoration _decoration(WidgetTester tester, int index) =>
    tester.widget<DecoratedBox>(_boxes.at(index)).decoration as BoxDecoration;

void main() {
  group('CodeField', () {
    testWidgets('draws six boxes by default', (tester) async {
      await tester.pumpWidget(_host());

      expect(_boxes, findsNWidgets(6));
    });

    testWidgets('shows the placeholder in every box', (tester) async {
      await tester.pumpWidget(_host());

      expect(find.text('A'), findsNWidgets(6));
    });

    testWidgets('draws a dash between the letters and the digits', (
      tester,
    ) async {
      await tester.pumpWidget(_host());

      expect(find.text('-'), findsOneWidget);
    });

    testWidgets('puts the dash after the third box', (tester) async {
      await tester.pumpWidget(_host());

      final third = tester.getRect(_boxes.at(2));
      final dash = tester.getCenter(find.text('-'));
      final fourth = tester.getRect(_boxes.at(3));

      expect(dash.dx, greaterThan(third.right));
      expect(dash.dx, lessThan(fourth.left));
    });

    testWidgets('separates the groups wider than the boxes in a group', (
      tester,
    ) async {
      await tester.pumpWidget(_host());

      final gapInGroup =
          tester.getRect(_boxes.at(1)).left -
          tester.getRect(_boxes.at(0)).right;
      final gapBetweenGroups =
          tester.getRect(_boxes.at(3)).left -
          tester.getRect(_boxes.at(2)).right;

      expect(gapInGroup, 8);
      expect(gapBetweenGroups, 42);
    });

    testWidgets('gives every box the same width', (tester) async {
      await tester.pumpWidget(_host());

      final widths = {
        for (var i = 0; i < 6; i++) tester.getSize(_boxes.at(i)).width,
      };

      expect(widths, hasLength(1));
    });

    testWidgets('fills the available width', (tester) async {
      await tester.pumpWidget(_host());

      final field = tester.getRect(find.byType(CodeField));

      expect(tester.getRect(_boxes.at(0)).left, closeTo(field.left, 0.5));
      expect(tester.getRect(_boxes.at(5)).right, closeTo(field.right, 0.5));
      expect(field.width, 350);
    });

    testWidgets('keeps the height at sixty six pixels', (tester) async {
      await tester.pumpWidget(_host());

      expect(tester.getSize(find.byType(CodeField)).height, 66);
    });

    testWidgets('marks every box as active with a green border', (
      tester,
    ) async {
      await tester.pumpWidget(_host());

      for (var i = 0; i < 6; i++) {
        final border = _decoration(tester, i).border! as Border;

        expect(border.top.color, AppColors.green);
        expect(border.top.width, 2);
      }
    });

    testWidgets('tints the empty active boxes with green', (tester) async {
      await tester.pumpWidget(_host());

      expect(
        _decoration(tester, 0).color,
        Color.alphaBlend(
          AppColors.green.withValues(alpha: .06),
          AppColors.white,
        ),
      );
    });

    testWidgets('rounds the boxes', (tester) async {
      await tester.pumpWidget(_host());

      expect(_decoration(tester, 0).borderRadius, AppDimens.borderRadiusSm);
    });

    testWidgets('draws the placeholder faded', (tester) async {
      await tester.pumpWidget(_host());

      final text = tester.widget<Text>(find.text('A').first);

      expect(text.style?.color, AppColors.ink.withValues(alpha: .16));
    });

    testWidgets('shows the typed characters in the first boxes', (
      tester,
    ) async {
      await tester.pumpWidget(_host(code: 'XY'));

      expect(find.text('X'), findsOneWidget);
      expect(find.text('Y'), findsOneWidget);
      expect(find.text('A'), findsNWidgets(4));
    });

    testWidgets('shows a complete code without placeholders', (tester) async {
      await tester.pumpWidget(_host(code: 'XYZ123', length: 6, letters: 3));

      for (final char in 'XYZ123'.split('')) {
        expect(find.text(char), findsOneWidget, reason: char);
      }
      expect(find.text('A'), findsNothing);
    });

    testWidgets('fills the boxes in order', (tester) async {
      await tester.pumpWidget(_host(code: 'XYZ12', length: 5, letters: 3));

      final chars = [
        for (var i = 0; i < 5; i++)
          tester
              .widget<Text>(
                find.descendant(of: _boxes.at(i), matching: find.byType(Text)),
              )
              .data,
      ];

      expect(chars, ['X', 'Y', 'Z', '1', '2']);
    });

    testWidgets('ignores the characters beyond the length', (tester) async {
      await tester.pumpWidget(_host(code: 'XYZ12345', length: 5, letters: 3));

      expect(find.text('3'), findsNothing);
      expect(find.text('2'), findsOneWidget);
      expect(_boxes, findsNWidgets(5));
    });

    testWidgets('draws the typed characters solid and the rest faded', (
      tester,
    ) async {
      await tester.pumpWidget(_host(code: 'X'));

      expect(
        tester.widget<Text>(find.text('X')).style?.color,
        AppColors.ink,
      );
      expect(
        tester.widget<Text>(find.text('A').first).style?.color,
        AppColors.ink.withValues(alpha: .16),
      );
    });

    testWidgets('keeps every box with the active border for now', (
      tester,
    ) async {
      await tester.pumpWidget(_host(code: 'XYZ'));

      for (var i = 0; i < 6; i++) {
        final border = _decoration(tester, i).border! as Border;

        expect(border.top.color, AppColors.green);
        expect(border.top.width, 2);
      }
    });

    testWidgets('paints a typed box white and an empty one tinted', (
      tester,
    ) async {
      await tester.pumpWidget(_host(code: 'X'));

      expect(_decoration(tester, 0).color, AppColors.white);
      expect(
        _decoration(tester, 1).color,
        Color.alphaBlend(
          AppColors.green.withValues(alpha: .06),
          AppColors.white,
        ),
      );
    });

    testWidgets('uses the letter placeholder even for the digit boxes', (
      tester,
    ) async {
      await tester.pumpWidget(_host());

      final digitBox = find.descendant(
        of: _boxes.at(5),
        matching: find.byType(Text),
      );

      expect(tester.widget<Text>(digitBox).data, 'A');
    });

    testWidgets('follows the length', (tester) async {
      await tester.pumpWidget(_host(length: 4, letters: 2));

      expect(_boxes, findsNWidgets(4));
      expect(find.text('-'), findsOneWidget);
    });

    testWidgets('moves the dash with the letters count', (tester) async {
      await tester.pumpWidget(_host(length: 4, letters: 2));

      final second = tester.getRect(_boxes.at(1));
      final dash = tester.getCenter(find.text('-'));
      final third = tester.getRect(_boxes.at(2));

      expect(dash.dx, greaterThan(second.right));
      expect(dash.dx, lessThan(third.left));
    });

    testWidgets('draws no dash when every box is a letter', (tester) async {
      await tester.pumpWidget(_host(length: 3, letters: 3));

      expect(find.text('-'), findsNothing);
      expect(_boxes, findsNWidgets(3));
    });
  });
}
