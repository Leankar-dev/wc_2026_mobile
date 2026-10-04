import 'package:flutter/material.dart' as flutter show Material;
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:wc_2026_mobile/ui/album/album_view_model.dart';
import 'package:wc_2026_mobile/ui/album/widgets/sticker_tile.dart';
import 'package:wc_2026_mobile/ui/album/widgets/team_selection.dart';
import 'package:wc_2026_mobile/ui/core/share/team_flag.dart';

const _color = Color(0xFF009C3B);

AlbumStickerView _sticker(int number, {bool collected = true}) => (
  code: 'BRA-$number',
  number: number,
  label: 'BRA',
  player: 'JOGADOR $number',
  collected: collected,
  count: collected ? 1 : 0,
);

Widget _host({
  String name = 'Brazil',
  String? flagPath = '/flags/bra.png',
  String progress = '3/20',
  List<AlbumStickerView> stickers = const [],
}) => MaterialApp(
  builder: (context, child) => MediaQuery(
    data: MediaQuery.of(context).copyWith(textScaler: TextScaler.linear(0.8)),
    child: child!,
  ),
  home: Scaffold(
    body: CustomScrollView(
      slivers: [
        TeamSelection(
          name: name,
          flagPath: flagPath,
          color: _color,
          progress: progress,
          stickers: stickers,
          onStickerTap: (_) {},
        ),
      ],
    ),
  ),
);

void _useNarrowScreen(WidgetTester tester) {
  tester.view.physicalSize = Size(390, 1600);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
}

void main() {
  group('TeamSelection', () {
    testWidgets('shows the team name and the progress', (tester) async {
      _useNarrowScreen(tester);

      await tester.pumpWidget(_host());

      expect(find.text('Brazil'), findsOneWidget);
      expect(find.text('3/20'), findsOneWidget);
    });

    testWidgets('shows one tile per sticker', (tester) async {
      _useNarrowScreen(tester);

      await tester.pumpWidget(
        _host(stickers: [for (var i = 1; i <= 6; i++) _sticker(i)]),
      );

      expect(find.byType(StickerTile), findsNWidgets(6));
    });

    testWidgets('shows only the header when there are no stickers', (
      tester,
    ) async {
      _useNarrowScreen(tester);

      await tester.pumpWidget(_host());

      expect(find.byType(StickerTile), findsNothing);
      expect(find.text('Brazil'), findsOneWidget);
    });

    testWidgets('passes the sticker data and the team color to each tile', (
      tester,
    ) async {
      _useNarrowScreen(tester);

      await tester.pumpWidget(
        _host(stickers: [_sticker(1), _sticker(2, collected: false)]),
      );

      final tiles = tester
          .widgetList<StickerTile>(find.byType(StickerTile))
          .toList();

      expect(tiles.map((tile) => tile.number), [1, 2]);
      expect(tiles.map((tile) => tile.player), ['JOGADOR 1', 'JOGADOR 2']);
      expect(tiles.map((tile) => tile.collected), [true, false]);
      expect(tiles.map((tile) => tile.teamColor), [_color, _color]);
    });

    testWidgets('lays the tiles out in four columns', (tester) async {
      _useNarrowScreen(tester);

      await tester.pumpWidget(
        _host(stickers: [for (var i = 1; i <= 5; i++) _sticker(i)]),
      );

      final tops = [
        for (var i = 0; i < 5; i++)
          tester.getTopLeft(find.byType(StickerTile).at(i)).dy,
      ];
      final lefts = [
        for (var i = 0; i < 5; i++)
          tester.getTopLeft(find.byType(StickerTile).at(i)).dx,
      ];

      expect(tops.take(4).toSet(), hasLength(1));
      expect(tops[4], greaterThan(tops[0]));
      expect(lefts[4], lefts[0]);
      expect(lefts.take(4).toSet(), hasLength(4));
    });

    testWidgets('keeps the tile proportion', (tester) async {
      _useNarrowScreen(tester);

      await tester.pumpWidget(_host(stickers: [_sticker(1)]));

      final size = tester.getSize(find.byType(StickerTile));

      expect(size.width / size.height, closeTo(80 / 104, 0.001));
    });

    testWidgets('colors the flag border and the progress pill', (tester) async {
      _useNarrowScreen(tester);

      await tester.pumpWidget(_host());

      final borders = tester
          .widgetList<flutter.Material>(find.byType(flutter.Material))
          .map((material) => material.shape)
          .whereType<CircleBorder>()
          .map((shape) => shape.side)
          .toList();
      final pill = tester
          .widgetList<Container>(find.byType(Container))
          .map((container) => container.decoration)
          .whereType<ShapeDecoration>()
          .single;

      expect(borders.single.color, _color);
      expect(borders.single.width, 2.0);
      expect(pill.color, _color.withValues(alpha: .12));
    });

    testWidgets('keeps a long name on a single line', (tester) async {
      _useNarrowScreen(tester);

      await tester.pumpWidget(_host(name: 'Very long team name ' * 10));

      final name = tester.widget<Text>(find.textContaining('Very long'));

      expect(name.maxLines, 1);
      expect(name.overflow, TextOverflow.ellipsis);
    });

    testWidgets('renders the header without a flag path', (tester) async {
      _useNarrowScreen(tester);

      await tester.pumpWidget(_host(flagPath: null));

      expect(find.byType(TeamFlag), findsOneWidget);
      expect(find.text('Brazil'), findsOneWidget);
    });
  });

  group('TeamSelection tap', () {
    Widget hostWithTap({
      required List<AlbumStickerView> stickers,
      required ValueChanged<AlbumStickerView> onStickerTap,
    }) => MaterialApp(
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(
          textScaler: TextScaler.linear(0.8),
        ),
        child: child!,
      ),
      home: Scaffold(
        body: CustomScrollView(
          slivers: [
            TeamSelection(
              name: 'Brazil',
              flagPath: '/flags/bra.png',
              color: _color,
              progress: '3/20',
              stickers: stickers,
              onStickerTap: onStickerTap,
            ),
          ],
        ),
      ),
    );

    testWidgets('reports the sticker of the tapped tile', (tester) async {
      _useNarrowScreen(tester);
      final stickers = [for (var i = 1; i <= 4; i++) _sticker(i)];
      final tapped = <AlbumStickerView>[];

      await tester.pumpWidget(
        hostWithTap(stickers: stickers, onStickerTap: tapped.add),
      );
      await tester.tap(find.byType(StickerTile).at(2));
      await tester.tap(find.byType(StickerTile).at(0));

      expect(tapped, [stickers[2], stickers[0]]);
    });

    testWidgets('reports missing stickers too', (tester) async {
      _useNarrowScreen(tester);
      final stickers = [_sticker(1, collected: false)];
      final tapped = <AlbumStickerView>[];

      await tester.pumpWidget(
        hostWithTap(stickers: stickers, onStickerTap: tapped.add),
      );
      await tester.tap(find.byType(StickerTile));

      expect(tapped.single.collected, isFalse);
      expect(tapped.single.number, 1);
    });

    testWidgets('makes every tile tappable', (tester) async {
      _useNarrowScreen(tester);

      await tester.pumpWidget(
        hostWithTap(
          stickers: [for (var i = 1; i <= 5; i++) _sticker(i)],
          onStickerTap: (_) {},
        ),
      );

      final tiles = tester.widgetList<StickerTile>(find.byType(StickerTile));

      expect(tiles.every((tile) => tile.onTap != null), isTrue);
    });
  });
}
