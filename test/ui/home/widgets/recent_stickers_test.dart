import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:wc_2026_mobile/ui/home/home_view_model.dart';
import 'package:wc_2026_mobile/ui/home/widgets/recent_stickers.dart';
import 'package:wc_2026_mobile/ui/home/widgets/sticker_card.dart';

Widget _host(Widget child) => MaterialApp(
  builder: (context, child) => MediaQuery(
    data: MediaQuery.of(context).copyWith(textScaler: TextScaler.linear(0.8)),
    child: child!,
  ),
  home: Scaffold(body: child),
);

RecentStickerView _view(int number, String label) => (
  code: '$label-$number',
  number: number,
  label: label,
  teamName: label,
  teamColor: const Color(0xFFFFDF00),
  flagCode: label,
  count: 1,
);

void main() {
  group('RecentStickers', () {
    testWidgets('shows the empty message when there are no stickers', (
      tester,
    ) async {
      await tester.pumpWidget(
        _host(RecentStickers(stickers: const [], onStickerTap: (_) {})),
      );

      expect(find.byType(StickerCard), findsNothing);
      expect(find.textContaining('ainda não colou'), findsOneWidget);
    });

    testWidgets('shows one card per sticker with its own data', (tester) async {
      await tester.pumpWidget(
        _host(
          RecentStickers(
            stickers: [_view(1, 'BRA'), _view(2, 'ARG')],
            onStickerTap: (_) {},
          ),
        ),
      );

      final cards = tester.widgetList<StickerCard>(find.byType(StickerCard));

      expect(cards.map((card) => card.number), [1, 2]);
      expect(cards.map((card) => card.label), ['BRA', 'ARG']);
    });
  });
}
