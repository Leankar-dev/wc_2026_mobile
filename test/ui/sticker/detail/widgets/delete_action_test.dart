import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:wc_2026_mobile/ui/core/theme/theme.dart';
import 'package:wc_2026_mobile/ui/sticker/detail/widgets/delete_action.dart';

Widget _host({VoidCallback? onPressed}) => MaterialApp(
  builder: (context, child) => MediaQuery(
    data: MediaQuery.of(context).copyWith(textScaler: TextScaler.linear(0.8)),
    child: child!,
  ),
  home: Scaffold(
    body: Center(
      child: SizedBox(
        width: 300,
        child: DeleteAction(onPressed: onPressed ?? () {}),
      ),
    ),
  ),
);

void main() {
  group('DeleteAction', () {
    testWidgets('shows the label and the trash icon', (tester) async {
      await tester.pumpWidget(_host());

      expect(find.text('EXCLUIR FIGURINHA'), findsOneWidget);
      expect(find.byIcon(Icons.delete_outline_rounded), findsOneWidget);
    });

    testWidgets('calls onPressed when tapped', (tester) async {
      var taps = 0;

      await tester.pumpWidget(_host(onPressed: () => taps++));
      await tester.tap(find.byType(DeleteAction));

      expect(taps, 1);
    });

    testWidgets('uses the danger ghost style', (tester) async {
      await tester.pumpWidget(_host());

      expect(
        tester.widget<FilledButton>(find.byType(FilledButton)).style,
        AppTheme.dangerGhostButton,
      );
    });

    testWidgets('keeps the label and the icon together in the center', (
      tester,
    ) async {
      await tester.pumpWidget(_host());

      final button = tester.getRect(find.byType(FilledButton));
      final label = tester.getCenter(find.text('EXCLUIR FIGURINHA'));

      expect(label.dx, lessThan(button.center.dx));
      expect(tester.getCenter(find.byType(Icon)).dx, greaterThan(label.dx));
    });

    testWidgets('does not overflow on a narrow width', (tester) async {
      tester.view.physicalSize = Size(320, 800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(_host());

      expect(tester.takeException(), isNull);
    });
  });
}
