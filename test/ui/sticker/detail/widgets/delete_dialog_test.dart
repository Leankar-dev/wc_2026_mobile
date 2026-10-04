import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:wc_2026_mobile/ui/core/theme/theme.dart';
import 'package:wc_2026_mobile/ui/sticker/detail/widgets/delete_dialog.dart';

Object? _result;

Widget _host({int number = 1, String country = 'BRA', int count = 2}) =>
    MaterialApp(
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(
          context,
        ).copyWith(textScaler: TextScaler.linear(0.8)),
        child: child!,
      ),
      home: Scaffold(
        body: Builder(
          builder: (context) => TextButton(
            onPressed: () async {
              _result = await showDialog<bool>(
                context: context,
                builder: (_) => DeleteDialog(
                  number: number,
                  country: country,
                  count: count,
                ),
              );
            },
            child: Text('open'),
          ),
        ),
      ),
    );

Future<void> _open(WidgetTester tester) async {
  tester.view.physicalSize = Size(390, 900);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);

  await tester.tap(find.text('open'));
  await tester.pumpAndSettle();
}

void main() {
  setUp(() => _result = 'unset');

  group('DeleteDialog', () {
    testWidgets('asks to delete the sticker by its country and number', (
      tester,
    ) async {
      await tester.pumpWidget(_host());
      await _open(tester);

      expect(find.text('EXCLUIR BRA - 01?'), findsOneWidget);
    });

    testWidgets('pads a single digit number', (tester) async {
      await tester.pumpWidget(_host(number: 7, country: 'ARG'));
      await _open(tester);

      expect(find.text('EXCLUIR ARG - 07?'), findsOneWidget);
    });

    testWidgets('keeps a number with two digits', (tester) async {
      await tester.pumpWidget(_host(number: 12));
      await _open(tester);

      expect(find.text('EXCLUIR BRA - 12?'), findsOneWidget);
    });

    testWidgets('shows the special section code as it comes', (tester) async {
      await tester.pumpWidget(_host(country: 'FWC', number: 3));
      await _open(tester);

      expect(find.text('EXCLUIR FWC - 03?'), findsOneWidget);
    });

    testWidgets('shows a red disc with the trash icon', (tester) async {
      await tester.pumpWidget(_host());
      await _open(tester);

      final disc = tester.widget<CircleAvatar>(
        find.descendant(
          of: find.byType(DeleteDialog),
          matching: find.byType(CircleAvatar),
        ),
      );

      expect(disc.backgroundColor, AppColors.red);
      expect(find.byIcon(Icons.delete_outline_rounded), findsOneWidget);
    });

    testWidgets('offers the delete and the cancel buttons', (tester) async {
      await tester.pumpWidget(_host());
      await _open(tester);

      expect(find.text('EXCLUIR'), findsOneWidget);
      expect(find.text('CANCELAR'), findsOneWidget);
    });

    testWidgets('styles the delete button as dangerous', (tester) async {
      await tester.pumpWidget(_host());
      await _open(tester);

      final button = tester.widget<FilledButton>(
        find.widgetWithText(FilledButton, 'EXCLUIR'),
      );

      expect(button.style, AppTheme.dangerButton);
    });

    testWidgets('styles the cancel button as a ghost', (tester) async {
      await tester.pumpWidget(_host());
      await _open(tester);

      final button = tester.widget<FilledButton>(
        find.widgetWithText(FilledButton, 'CANCELAR'),
      );

      expect(button.style, AppTheme.ghostButton);
    });

    testWidgets('returns true when the delete button is tapped', (
      tester,
    ) async {
      await tester.pumpWidget(_host());
      await _open(tester);

      await tester.tap(find.text('EXCLUIR'));
      await tester.pumpAndSettle();

      expect(_result, isTrue);
      expect(find.byType(DeleteDialog), findsNothing);
    });

    testWidgets('returns false when the cancel button is tapped', (
      tester,
    ) async {
      await tester.pumpWidget(_host());
      await _open(tester);

      await tester.tap(find.text('CANCELAR'));
      await tester.pumpAndSettle();

      expect(_result, isFalse);
      expect(find.byType(DeleteDialog), findsNothing);
    });

    testWidgets('returns null when dismissed outside the dialog', (
      tester,
    ) async {
      await tester.pumpWidget(_host());
      await _open(tester);

      await tester.tapAt(Offset(5, 5));
      await tester.pumpAndSettle();

      expect(_result, isNull);
    });

    testWidgets('paints a dark rounded dialog with a thin border', (
      tester,
    ) async {
      await tester.pumpWidget(_host());
      await _open(tester);

      final dialog = tester.widget<Dialog>(find.byType(Dialog));
      final shape = dialog.shape! as RoundedRectangleBorder;

      expect(dialog.backgroundColor, AppColors.ink);
      expect(shape.borderRadius, AppDimens.borderRadiusLg);
      expect(shape.side.color, AppColors.white.withValues(alpha: .15));
    });

    testWidgets('keeps the grid margin on both sides', (tester) async {
      await tester.pumpWidget(_host());
      await _open(tester);

      final card = tester.getRect(
        find
            .descendant(
              of: find.byType(Dialog),
              matching: find.byType(Material),
            )
            .first,
      );

      expect(card.left, AppDimens.gridMargin);
      expect(card.right, 390 - AppDimens.gridMargin);
    });

    testWidgets('ignores the count it receives for now', (tester) async {
      await tester.pumpWidget(_host(count: 1));
      await _open(tester);
      final first = tester.getSize(find.byType(Dialog));
      await tester.tap(find.text('CANCELAR'));
      await tester.pumpAndSettle();

      await tester.pumpWidget(_host(count: 50));
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();

      expect(tester.getSize(find.byType(Dialog)), first);
      expect(find.text('EXCLUIR BRA - 01?'), findsOneWidget);
    });

    testWidgets('does not overflow on a narrow screen', (tester) async {
      await tester.pumpWidget(_host());
      tester.view.physicalSize = Size(320, 700);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
    });
  });
}
