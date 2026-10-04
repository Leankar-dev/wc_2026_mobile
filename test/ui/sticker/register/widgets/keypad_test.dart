import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:wc_2026_mobile/ui/core/theme/theme.dart';
import 'package:wc_2026_mobile/ui/sticker/register/widgets/keypad.dart';

const _alphabet = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ';

Widget _host({
  required bool letters,
  ValueChanged<String>? onKey,
  VoidCallback? onBackspace,
  double width = 370,
}) => MaterialApp(
  builder: (context, child) => MediaQuery(
    data: MediaQuery.of(context).copyWith(textScaler: TextScaler.linear(0.8)),
    child: child!,
  ),
  home: Scaffold(
    body: SingleChildScrollView(
      child: Center(
        child: SizedBox(
          width: width,
          child: Keypad(
            letters: letters,
            onKey: onKey ?? (_) {},
            onBackspace: onBackspace ?? () {},
          ),
        ),
      ),
    ),
  ),
);

Finder get _keys =>
    find.descendant(of: find.byType(Keypad), matching: find.byType(InkWell));

void main() {
  group('Keypad letters', () {
    testWidgets('shows every letter of the alphabet', (tester) async {
      await tester.pumpWidget(_host(letters: true));

      for (final letter in _alphabet.split('')) {
        expect(find.text(letter), findsOneWidget, reason: letter);
      }
    });

    testWidgets('includes the letter V', (tester) async {
      await tester.pumpWidget(_host(letters: true));

      expect(find.text('V'), findsOneWidget);
    });

    testWidgets('shows no digits', (tester) async {
      await tester.pumpWidget(_host(letters: true));

      for (final digit in '0123456789'.split('')) {
        expect(find.text(digit), findsNothing, reason: digit);
      }
    });

    testWidgets('draws the letters, the scan and the backspace keys', (
      tester,
    ) async {
      await tester.pumpWidget(_host(letters: true));

      expect(_keys, findsNWidgets(28));
    });

    testWidgets('reports the letter that was tapped', (tester) async {
      final pressed = <String>[];

      await tester.pumpWidget(_host(letters: true, onKey: pressed.add));
      await tester.tap(find.text('V'));
      await tester.tap(find.text('A'));
      await tester.tap(find.text('Z'));

      expect(pressed, ['V', 'A', 'Z']);
    });

    testWidgets('reports every letter once', (tester) async {
      final pressed = <String>[];

      await tester.pumpWidget(_host(letters: true, onKey: pressed.add));
      for (final letter in _alphabet.split('')) {
        await tester.ensureVisible(find.text(letter));
        await tester.tap(find.text(letter));
      }

      expect(pressed.join(), _alphabet);
    });

    testWidgets('sizes the keys at forty four by forty six', (tester) async {
      await tester.pumpWidget(_host(letters: true));

      expect(tester.getSize(_keys.first), Size(44, 46));
    });

    testWidgets('spaces the keys by seven pixels', (tester) async {
      await tester.pumpWidget(_host(letters: true));

      final first = tester.getRect(_keys.at(0));
      final second = tester.getRect(_keys.at(1));

      expect(second.left - first.right, 7);
    });

    testWidgets('wraps the keys in rows of seven on a phone', (tester) async {
      await tester.pumpWidget(_host(letters: true));

      final firstRow = tester.getTopLeft(_keys.at(0)).dy;

      expect(tester.getTopLeft(_keys.at(6)).dy, firstRow);
      expect(tester.getTopLeft(_keys.at(7)).dy, greaterThan(firstRow));
    });

    testWidgets('spaces the rows by eight pixels', (tester) async {
      await tester.pumpWidget(_host(letters: true));

      final first = tester.getRect(_keys.at(0));
      final nextRow = tester.getRect(_keys.at(7));

      expect(nextRow.top - first.bottom, 8);
    });

    testWidgets('wraps into fewer keys per row on a narrow width', (
      tester,
    ) async {
      await tester.pumpWidget(_host(letters: true, width: 200));

      final firstRow = tester.getTopLeft(_keys.at(0)).dy;

      expect(tester.getTopLeft(_keys.at(4)).dy, greaterThan(firstRow));
    });

    testWidgets('uses the camera icon alone for the scan key', (tester) async {
      await tester.pumpWidget(_host(letters: true));

      expect(find.byIcon(Icons.photo_camera_rounded), findsOneWidget);
      expect(find.text('SCAN'), findsNothing);
    });

    testWidgets('does nothing when the scan key is tapped for now', (
      tester,
    ) async {
      final pressed = <String>[];
      var backspaces = 0;

      await tester.pumpWidget(
        _host(
          letters: true,
          onKey: pressed.add,
          onBackspace: () => backspaces++,
        ),
      );
      await tester.tap(find.byIcon(Icons.photo_camera_rounded));

      expect(pressed, isEmpty);
      expect(backspaces, 0);
    });

    testWidgets('paints the scan key dark', (tester) async {
      await tester.pumpWidget(_host(letters: true));

      final scan = tester.widget<Material>(
        find
            .ancestor(
              of: find.byIcon(Icons.photo_camera_rounded),
              matching: find.byType(Material),
            )
            .first,
      );

      expect(scan.color, AppColors.ink);
    });
  });

  group('Keypad digits', () {
    testWidgets('shows the digits from zero to nine', (tester) async {
      await tester.pumpWidget(_host(letters: false));

      for (final digit in '0123456789'.split('')) {
        expect(find.text(digit), findsOneWidget, reason: digit);
      }
    });

    testWidgets('shows no letters', (tester) async {
      await tester.pumpWidget(_host(letters: false));

      expect(find.text('A'), findsNothing);
      expect(find.text('V'), findsNothing);
    });

    testWidgets('draws the digits, the scan and the backspace keys', (
      tester,
    ) async {
      await tester.pumpWidget(_host(letters: false));

      expect(_keys, findsNWidgets(12));
    });

    testWidgets('reports the digit that was tapped', (tester) async {
      final pressed = <String>[];

      await tester.pumpWidget(_host(letters: false, onKey: pressed.add));
      await tester.tap(find.text('7'));
      await tester.tap(find.text('0'));

      expect(pressed, ['7', '0']);
    });

    testWidgets('sizes the keys at one hundred and ten by forty eight', (
      tester,
    ) async {
      await tester.pumpWidget(_host(letters: false));

      expect(tester.getSize(_keys.first), Size(110, 48));
    });

    testWidgets('places three keys per row on a phone', (tester) async {
      await tester.pumpWidget(_host(letters: false));

      final firstRow = tester.getTopLeft(_keys.at(0)).dy;

      expect(tester.getTopLeft(_keys.at(2)).dy, firstRow);
      expect(tester.getTopLeft(_keys.at(3)).dy, greaterThan(firstRow));
    });

    testWidgets('spaces the keys by ten and the rows by six pixels', (
      tester,
    ) async {
      await tester.pumpWidget(_host(letters: false));

      final first = tester.getRect(_keys.at(0));
      final second = tester.getRect(_keys.at(1));
      final nextRow = tester.getRect(_keys.at(3));

      expect(second.left - first.right, 10);
      expect(nextRow.top - first.bottom, 6);
    });

    testWidgets('puts the scan label next to the camera icon', (tester) async {
      await tester.pumpWidget(_host(letters: false));

      expect(find.text('SCAN'), findsOneWidget);
      expect(find.byIcon(Icons.photo_camera_rounded), findsOneWidget);
    });

    testWidgets('places the zero between the scan and the backspace', (
      tester,
    ) async {
      await tester.pumpWidget(_host(letters: false));

      final scan = tester.getCenter(find.text('SCAN')).dx;
      final zero = tester.getCenter(find.text('0')).dx;
      final backspace = tester
          .getCenter(find.byIcon(Icons.backspace_outlined))
          .dx;

      expect(scan, lessThan(zero));
      expect(zero, lessThan(backspace));
    });

    testWidgets('does nothing when the scan key is tapped for now', (
      tester,
    ) async {
      final pressed = <String>[];

      await tester.pumpWidget(_host(letters: false, onKey: pressed.add));
      await tester.tap(find.text('SCAN'));

      expect(pressed, isEmpty);
    });

    testWidgets('keeps two keys per row on a narrow width', (tester) async {
      await tester.pumpWidget(_host(letters: false, width: 300));

      final firstRow = tester.getTopLeft(_keys.at(0)).dy;

      expect(tester.getTopLeft(_keys.at(1)).dy, firstRow);
      expect(tester.getTopLeft(_keys.at(2)).dy, greaterThan(firstRow));
    });
  });

  group('Keypad backspace', () {
    testWidgets('calls onBackspace in the letters keypad', (tester) async {
      var backspaces = 0;

      await tester.pumpWidget(
        _host(letters: true, onBackspace: () => backspaces++),
      );
      await tester.tap(find.byIcon(Icons.backspace_outlined));

      expect(backspaces, 1);
    });

    testWidgets('calls onBackspace in the digits keypad', (tester) async {
      var backspaces = 0;

      await tester.pumpWidget(
        _host(letters: false, onBackspace: () => backspaces++),
      );
      await tester.tap(find.byIcon(Icons.backspace_outlined));

      expect(backspaces, 1);
    });

    testWidgets('does not report a key when the backspace is tapped', (
      tester,
    ) async {
      final pressed = <String>[];

      await tester.pumpWidget(_host(letters: true, onKey: pressed.add));
      await tester.tap(find.byIcon(Icons.backspace_outlined));

      expect(pressed, isEmpty);
    });

    testWidgets('has an accessibility label', (tester) async {
      await tester.pumpWidget(_host(letters: true));

      final icon = tester.widget<Icon>(find.byIcon(Icons.backspace_outlined));

      expect(icon.semanticLabel, 'Apagar');
    });

    testWidgets('keeps the backspace key as the last one', (tester) async {
      await tester.pumpWidget(_host(letters: true));

      final last = tester.getTopLeft(_keys.last);
      final backspace = tester.getTopLeft(
        find.ancestor(
          of: find.byIcon(Icons.backspace_outlined),
          matching: find.byType(InkWell),
        ),
      );

      expect(backspace, last);
    });
  });

  group('Keypad style', () {
    testWidgets('paints the keys white with a thin border', (tester) async {
      await tester.pumpWidget(_host(letters: true));

      final material = tester.widget<Material>(
        find
            .ancestor(of: find.text('A'), matching: find.byType(Material))
            .first,
      );
      final shape = material.shape! as RoundedRectangleBorder;

      expect(material.color, AppColors.white);
      expect(shape.side.color, AppColors.hairline);
    });

    testWidgets('rounds the letter keys less than the digit keys', (
      tester,
    ) async {
      await tester.pumpWidget(_host(letters: true));
      final letterShape =
          tester
                  .widget<Material>(
                    find
                        .ancestor(
                          of: find.text('A'),
                          matching: find.byType(Material),
                        )
                        .first,
                  )
                  .shape!
              as RoundedRectangleBorder;

      await tester.pumpWidget(_host(letters: false));
      final digitShape =
          tester
                  .widget<Material>(
                    find
                        .ancestor(
                          of: find.text('1'),
                          matching: find.byType(Material),
                        )
                        .first,
                  )
                  .shape!
              as RoundedRectangleBorder;

      expect(letterShape.borderRadius, AppDimens.borderRadiusSm);
      expect(digitShape.borderRadius, AppDimens.borderRadiusMd);
    });
  });
}
