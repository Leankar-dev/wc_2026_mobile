import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:wc_2026_mobile/ui/core/theme/theme.dart';
import 'package:wc_2026_mobile/ui/sticker/widgets/sticker_action_button.dart';

Widget _host({
  VoidCallback? onPressed,
  bool enabled = true,
  ButtonStyle? style,
  double? discSize,
}) {
  final callback = enabled ? (onPressed ?? () {}) : null;

  return MaterialApp(
    builder: (context, child) => MediaQuery(
      data: MediaQuery.of(context).copyWith(textScaler: TextScaler.linear(0.8)),
      child: child!,
    ),
    home: Scaffold(
      body: Center(
        child: SizedBox(
          width: 300,
          child: discSize == null
              ? StickerActionButton(
                  label: 'Salvar',
                  icon: Icons.check_rounded,
                  onPressed: callback,
                  style: style,
                )
              : StickerActionButton(
                  label: 'Salvar',
                  icon: Icons.check_rounded,
                  onPressed: callback,
                  style: style,
                  discSize: discSize,
                ),
        ),
      ),
    ),
  );
}

CircleAvatar _disc(WidgetTester tester) => tester.widget<CircleAvatar>(
  find.descendant(
    of: find.byType(StickerActionButton),
    matching: find.byType(CircleAvatar),
  ),
);

Icon _icon(WidgetTester tester) => tester.widget<Icon>(
  find.descendant(
    of: find.byType(StickerActionButton),
    matching: find.byType(Icon),
  ),
);

void main() {
  group('StickerActionButton', () {
    testWidgets('shows the label and the icon', (tester) async {
      await tester.pumpWidget(_host());

      expect(find.text('Salvar'), findsOneWidget);
      expect(find.byIcon(Icons.check_rounded), findsOneWidget);
    });

    testWidgets('centers the label in the available space', (tester) async {
      await tester.pumpWidget(_host());

      final button = tester.getRect(find.byType(FilledButton));
      final label = tester.getCenter(find.text('Salvar'));

      expect(label.dx, closeTo(button.center.dx, 1));
    });

    testWidgets('calls onPressed when tapped', (tester) async {
      var taps = 0;

      await tester.pumpWidget(_host(onPressed: () => taps++));
      await tester.tap(find.byType(StickerActionButton));

      expect(taps, 1);
    });

    testWidgets('uses a dark disc with a yellow icon when enabled', (
      tester,
    ) async {
      await tester.pumpWidget(_host());

      expect(_disc(tester).backgroundColor, AppColors.ink);
      expect(_icon(tester).color, AppColors.yellow);
    });

    testWidgets('uses a muted disc and icon when disabled', (tester) async {
      await tester.pumpWidget(_host(enabled: false));

      expect(_disc(tester).backgroundColor, AppColors.borderStrong);
      expect(_icon(tester).color, AppColors.grayText);
    });

    testWidgets('does not react to taps when disabled', (tester) async {
      var taps = 0;

      await tester.pumpWidget(_host(enabled: false, onPressed: () => taps++));
      await tester.tap(find.byType(StickerActionButton));

      expect(taps, 0);
    });

    testWidgets('sizes the disc at twenty four by default', (tester) async {
      await tester.pumpWidget(_host());

      expect(_disc(tester).radius, 12);
    });

    testWidgets('sizes the disc from discSize', (tester) async {
      await tester.pumpWidget(_host(discSize: 40));

      expect(_disc(tester).radius, 20);
    });

    testWidgets('keeps the label centered with a larger disc', (tester) async {
      await tester.pumpWidget(_host(discSize: 40));

      final button = tester.getRect(find.byType(FilledButton));
      final label = tester.getCenter(find.text('Salvar'));

      expect(label.dx, closeTo(button.center.dx, 1));
    });

    testWidgets('ignores the style it receives for now', (tester) async {
      await tester.pumpWidget(_host());
      final base = tester.widget<FilledButton>(find.byType(FilledButton)).style;

      await tester.pumpWidget(_host(style: AppTheme.dangerGhostButton));
      final styled = tester
          .widget<FilledButton>(find.byType(FilledButton))
          .style;

      expect(styled, base);
    });
  });
}
