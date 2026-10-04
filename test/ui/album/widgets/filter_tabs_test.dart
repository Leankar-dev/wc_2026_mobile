import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:wc_2026_mobile/domain/models/album/sticker_status.dart';
import 'package:wc_2026_mobile/ui/album/widgets/filter_tabs.dart';
import 'package:wc_2026_mobile/ui/core/theme/theme.dart';

Widget _host(Widget child) => MaterialApp(
  builder: (context, child) => MediaQuery(
    data: MediaQuery.of(context).copyWith(textScaler: TextScaler.linear(0.8)),
    child: child!,
  ),
  home: Scaffold(body: Center(child: child)),
);

FilterTabs _tabs({
  StickerStatus? selected,
  ValueChanged<StickerStatus?>? onSelected,
}) => FilterTabs(
  total: 980,
  missing: 300,
  repeated: 12,
  selected: selected,
  onSelected: onSelected ?? (_) {},
);

Color? _colorOf(WidgetTester tester, String text) =>
    tester.widget<Text>(find.text(text)).style?.color;

void main() {
  group('FilterTabs', () {
    testWidgets('shows the three segments with their counts', (tester) async {
      await tester.pumpWidget(_host(_tabs()));

      expect(find.text('TODAS'), findsOneWidget);
      expect(find.text('FALTANDO'), findsOneWidget);
      expect(find.text('REPETIDAS'), findsOneWidget);
      expect(find.text('980'), findsOneWidget);
      expect(find.text('300'), findsOneWidget);
      expect(find.text('12'), findsOneWidget);
    });

    testWidgets('highlights only the all segment when nothing is selected', (
      tester,
    ) async {
      await tester.pumpWidget(_host(_tabs()));

      expect(_colorOf(tester, 'TODAS'), AppColors.white);
      expect(_colorOf(tester, 'FALTANDO'), AppColors.ink);
      expect(_colorOf(tester, 'REPETIDAS'), AppColors.ink);
      expect(_colorOf(tester, '980'), AppColors.yellow);
      expect(_colorOf(tester, '300'), AppColors.ink);
    });

    testWidgets('highlights the selected status', (tester) async {
      await tester.pumpWidget(_host(_tabs(selected: StickerStatus.missing)));

      expect(_colorOf(tester, 'FALTANDO'), AppColors.white);
      expect(_colorOf(tester, '300'), AppColors.yellow);
      expect(_colorOf(tester, 'TODAS'), AppColors.ink);
      expect(_colorOf(tester, 'REPETIDAS'), AppColors.ink);
    });

    testWidgets('reports the status of each tapped segment', (tester) async {
      final selections = <StickerStatus?>[];

      await tester.pumpWidget(
        _host(
          _tabs(selected: StickerStatus.missing, onSelected: selections.add),
        ),
      );
      await tester.tap(find.text('REPETIDAS'));
      await tester.tap(find.text('TODAS'));
      await tester.tap(find.text('FALTANDO'));

      expect(selections, [StickerStatus.repeated, null, StickerStatus.missing]);
    });

    testWidgets('reports again when the selected segment is tapped', (
      tester,
    ) async {
      final selections = <StickerStatus?>[];

      await tester.pumpWidget(
        _host(
          _tabs(selected: StickerStatus.repeated, onSelected: selections.add),
        ),
      );
      await tester.tap(find.text('REPETIDAS'));

      expect(selections, [StickerStatus.repeated]);
    });
  });
}
