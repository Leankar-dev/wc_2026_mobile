import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:wc_2026_mobile/core/exceptions/app_exception.dart';
import 'package:wc_2026_mobile/core/result.dart';
import 'package:wc_2026_mobile/data/repositories/album/album_repository.dart';
import 'package:wc_2026_mobile/data/repositories/team/team_repository.dart';
import 'package:wc_2026_mobile/domain/models/album/album.dart';
import 'package:wc_2026_mobile/domain/models/album/album_position.dart';
import 'package:wc_2026_mobile/domain/models/album/album_summary.dart';
import 'package:wc_2026_mobile/domain/models/album/recent_sticker.dart';
import 'package:wc_2026_mobile/domain/models/album/sticker_status.dart';
import 'package:wc_2026_mobile/domain/models/album/team_album_group.dart';
import 'package:wc_2026_mobile/domain/models/team/team.dart';
import 'package:wc_2026_mobile/routing/routes.dart';
import 'package:wc_2026_mobile/ui/core/share/app_loading.dart';
import 'package:wc_2026_mobile/ui/core/share/error_indicator.dart';
import 'package:wc_2026_mobile/ui/album/album_screen.dart';
import 'package:wc_2026_mobile/ui/album/album_view_model.dart';
import 'package:wc_2026_mobile/ui/album/widgets/filter_tabs.dart';
import 'package:wc_2026_mobile/ui/album/widgets/header.dart';
import 'package:wc_2026_mobile/ui/album/widgets/sticker_tile.dart';
import 'package:wc_2026_mobile/ui/album/widgets/team_selection.dart';
import 'package:wc_2026_mobile/ui/album/widgets/team_strip.dart';
import 'package:wc_2026_mobile/ui/core/theme/theme.dart';
import 'package:wc_2026_mobile/ui/sticker/detail/detail_screen.dart';

class _FakeAlbumRepository implements AlbumRepository {
  @override
  Future<Result<void>> registerSticker({
    required String code,
    required int quantity,
  }) async => Result.done;

  @override
  Future<Result<void>> updateStickerQuantity({
    required String code,
    required int quantity,
  }) async => Result.done;

  @override
  Future<Result<void>> removeSticker(String code) async => Result.done;

  Result<AlbumSummary> summary = Result.ok(
    const AlbumSummary(total: 980, missing: 300, repeated: 12),
  );
  Result<Album> album = Result.ok(const Album(teams: [], loose: []));
  Completer<void>? gate;
  final albumCalls = <({StickerStatus? status, String? team})>[];
  var summaryCalls = 0;

  @override
  Future<Result<Album>> getAlbum({StickerStatus? status, String? team}) async {
    albumCalls.add((status: status, team: team));
    await gate?.future;
    return album;
  }

  @override
  Future<Result<AlbumSummary>> getSummary() async {
    summaryCalls++;
    return summary;
  }

  @override
  Future<Result<List<RecentSticker>>> getRecentStickers() async =>
      Result.ok(const []);
}

class _FakeTeamRepository implements TeamRepository {
  Result<List<Team>> teams = Result.ok(const [_brazil, _argentina]);
  var calls = 0;

  @override
  Future<Result<List<Team>>> getTeams() async {
    calls++;
    return teams;
  }
}

const _brazil = Team(
  code: 'BRA',
  name: 'Brazil',
  flagUrl: '/flags/bra.png',
  primaryColor: 0xFFFFDF00,
);

const _argentina = Team(
  code: 'ARG',
  name: 'Argentina',
  flagUrl: '/flags/arg.png',
  primaryColor: 0xFF6CACE4,
);

late _FakeAlbumRepository _albums;
late _FakeTeamRepository _teams;
late AlbumViewModel _viewModel;

void _useTallScreen(WidgetTester tester) {
  tester.view.physicalSize = Size(390, 2400);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
}

Widget _app(GoRouter router) => MaterialApp.router(
  routerConfig: router,
  builder: (context, child) => MediaQuery(
    data: MediaQuery.of(context).copyWith(textScaler: TextScaler.linear(0.8)),
    child: child!,
  ),
);

DetailArgs? _receivedArgs;

class _DetailProbe extends StatelessWidget {
  const _DetailProbe({required this.args});

  final DetailArgs args;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text('detail ${args.code}'),
        TextButton(onPressed: () => context.pop(true), child: Text('save')),
        TextButton(onPressed: () => context.pop(false), child: Text('discard')),
        TextButton(onPressed: () => context.pop(), child: Text('close')),
      ],
    );
  }
}

GoRouter _router({String initialLocation = Routes.album}) => GoRouter(
  initialLocation: initialLocation,
  routes: [
    GoRoute(path: Routes.home, builder: (_, _) => Text('home page')),
    GoRoute(
      path: Routes.album,
      builder: (_, _) => AlbumScreen(viewModel: _viewModel),
    ),
    GoRoute(
      path: Routes.stickerPath,
      builder: (_, state) {
        _receivedArgs = state.extra as DetailArgs;
        return Scaffold(body: _DetailProbe(args: _receivedArgs!));
      },
    ),
  ],
);

Future<void> _openAlbum(WidgetTester tester, {bool init = true}) async {
  _useTallScreen(tester);
  await tester.pumpWidget(_app(_router()));
  if (init) {
    _viewModel.init();
    await tester.pump();
    await tester.pump();
  }
}

Finder _inTabs(String text) =>
    find.descendant(of: find.byType(FilterTabs), matching: find.text(text));

Finder get _discs => find.descendant(
  of: find.byType(TeamStrip),
  matching: find.byType(InkWell),
);

void main() {
  setUp(() {
    _albums = _FakeAlbumRepository();
    _teams = _FakeTeamRepository();
    _viewModel = AlbumViewModel(
      albumRepository: _albums,
      teamRepository: _teams,
    );
  });

  tearDown(() => _viewModel.dispose());

  group('AlbumScreen', () {
    testWidgets('shows the header and the search field', (tester) async {
      await _openAlbum(tester);

      expect(find.byType(Header), findsOneWidget);
      expect(find.byType(TextField), findsOneWidget);
      expect(find.text('Buscar figurinha, país ou nº…'), findsOneWidget);
    });

    testWidgets('accepts typing in the search field', (tester) async {
      await _openAlbum(tester);
      await tester.enterText(find.byType(TextField), 'bra');
      await tester.pump();

      expect(find.text('bra'), findsOneWidget);
    });

    testWidgets('hides the filters until their data arrives', (tester) async {
      await _openAlbum(tester, init: false);

      expect(find.byType(FilterTabs), findsNothing);
      expect(find.byType(TeamStrip), findsNothing);
    });

    testWidgets('shows the tabs with the counts of the summary', (
      tester,
    ) async {
      await _openAlbum(tester);

      expect(find.byType(FilterTabs), findsOneWidget);
      expect(_inTabs('980'), findsOneWidget);
      expect(_inTabs('300'), findsOneWidget);
      expect(_inTabs('12'), findsOneWidget);
    });

    testWidgets('shows the team strip with the loaded teams', (tester) async {
      await _openAlbum(tester);

      final strip = tester.widget<TeamStrip>(find.byType(TeamStrip));

      expect(strip.teams, [_brazil, _argentina]);
      expect(strip.selected, isNull);
      expect(_discs, findsNWidgets(2));
    });

    testWidgets('hides the tabs when the summary fails', (tester) async {
      _albums.summary = Result.error(const NetworkException());

      await _openAlbum(tester);

      expect(find.byType(FilterTabs), findsNothing);
      expect(find.byType(TeamStrip), findsOneWidget);
    });

    testWidgets('hides the strip when there are no teams', (tester) async {
      _teams.teams = Result.ok(const []);

      await _openAlbum(tester);

      expect(find.byType(TeamStrip), findsNothing);
      expect(find.byType(FilterTabs), findsOneWidget);
    });
  });

  group('AlbumScreen album', () {
    AlbumPosition position(
      String code,
      int number, {
      StickerStatus status = StickerStatus.missing,
      int repeated = 0,
    }) => AlbumPosition(
      code: code,
      number: number,
      status: status,
      repeated: repeated,
    );

    Album album() => Album(
      teams: [
        TeamAlbumGroup(
          team: _brazil,
          stickers: [
            position('BRA-1', 1, status: StickerStatus.owned),
            position('BRA-2', 2),
          ],
        ),
        TeamAlbumGroup(
          team: _argentina,
          stickers: [
            position('ARG-1', 1, status: StickerStatus.repeated, repeated: 1),
            position('ARG-2', 2, status: StickerStatus.owned),
            position('ARG-3', 3),
          ],
        ),
      ],
      loose: [position('FWC-1', 1)],
    );

    testWidgets('shows the empty message when there are no stickers', (
      tester,
    ) async {
      await _openAlbum(tester);

      expect(find.text('Nenhuma figurinha neste recorte'), findsOneWidget);
      expect(find.byType(TeamSelection), findsNothing);
    });

    testWidgets('shows the loader while the album loads', (tester) async {
      _albums.gate = Completer<void>();

      await _openAlbum(tester);

      expect(find.byType(AppLoading), findsOneWidget);
      expect(find.text('Nenhuma figurinha neste recorte'), findsNothing);

      _albums.gate!.complete();
      await tester.pump();
      await tester.pump();

      expect(find.byType(AppLoading), findsNothing);
    });

    testWidgets('shows the error message and retries the album', (
      tester,
    ) async {
      _albums.album = Result.error(const NetworkException());
      await _openAlbum(tester);

      expect(find.byType(ErrorIndicator), findsOneWidget);
      expect(
        find.text('Sem conexão. Verifique sua internet e tente novamente.'),
        findsOneWidget,
      );

      _albums.album = Result.ok(album());
      await tester.tap(find.text('Tentar Novamente'));
      await tester.pump();
      await tester.pump();

      expect(_albums.albumCalls, hasLength(2));
      expect(find.byType(ErrorIndicator), findsNothing);
      expect(find.byType(TeamSelection), findsNWidgets(3));
    });

    testWidgets('shows one block per team and one for the special ones', (
      tester,
    ) async {
      _albums.album = Result.ok(album());

      await _openAlbum(tester);

      final blocks = tester
          .widgetList<TeamSelection>(find.byType(TeamSelection))
          .toList();

      expect(blocks.map((block) => block.name), [
        'Brazil',
        'Argentina',
        'ESPECIAIS',
      ]);
      expect(blocks.map((block) => block.progress), [
        '1 / 2',
        '2 / 3',
        '0 / 1',
      ]);
    });

    testWidgets('shows one tile per sticker with its collected state', (
      tester,
    ) async {
      _albums.album = Result.ok(album());

      await _openAlbum(tester);

      final tiles = tester
          .widgetList<StickerTile>(find.byType(StickerTile))
          .toList();

      expect(tiles, hasLength(6));
      expect(tiles.where((tile) => tile.collected), hasLength(3));
      expect(find.text('— FALTANDO —'), findsNWidgets(3));
    });

    testWidgets('filters the blocks by what is typed in the search', (
      tester,
    ) async {
      _albums.album = Result.ok(album());

      await _openAlbum(tester);
      await tester.enterText(find.byType(TextField), 'argentina');
      await tester.pump();

      final blocks = tester
          .widgetList<TeamSelection>(find.byType(TeamSelection))
          .toList();

      expect(blocks.map((block) => block.name), ['Argentina']);
      expect(blocks.single.progress, '3 itens');
      expect(find.byType(StickerTile), findsNWidgets(3));
    });

    testWidgets('keeps only the stickers whose code matches', (tester) async {
      _albums.album = Result.ok(album());

      await _openAlbum(tester);
      await tester.enterText(find.byType(TextField), 'fwc');
      await tester.pump();

      final blocks = tester
          .widgetList<TeamSelection>(find.byType(TeamSelection))
          .toList();

      expect(blocks.map((block) => block.name), ['ESPECIAIS']);
      expect(blocks.single.progress, '1 Item');
    });

    testWidgets('restores every block when the search is cleared', (
      tester,
    ) async {
      _albums.album = Result.ok(album());

      await _openAlbum(tester);
      await tester.enterText(find.byType(TextField), 'argentina');
      await tester.pump();
      await tester.enterText(find.byType(TextField), '');
      await tester.pump();

      expect(find.byType(TeamSelection), findsNWidgets(3));
      expect(find.text('1 / 2'), findsOneWidget);
    });

    testWidgets('shows the empty message when nothing matches', (tester) async {
      _albums.album = Result.ok(album());

      await _openAlbum(tester);
      await tester.enterText(find.byType(TextField), 'zzz');
      await tester.pump();

      expect(find.byType(TeamSelection), findsNothing);
      expect(find.text('Nenhuma figurinha neste recorte'), findsOneWidget);
    });

    testWidgets('clears the team filter when the same team is tapped twice', (
      tester,
    ) async {
      _albums.album = Result.ok(album());
      await _openAlbum(tester);
      _albums.albumCalls.clear();

      await tester.tap(_discs.at(0));
      await tester.pump();
      await tester.pump();
      await tester.tap(_discs.at(0));
      await tester.pump();
      await tester.pump();

      expect(_viewModel.teamCode, isNull);
      expect(_albums.albumCalls, [
        (status: null, team: 'BRA'),
        (status: null, team: null),
      ]);
      expect(tester.widget<TeamStrip>(find.byType(TeamStrip)).selected, isNull);
    });

    testWidgets('keeps the blocks after a status filter loads', (tester) async {
      _albums.album = Result.ok(album());
      await _openAlbum(tester);

      await tester.tap(find.text('FALTANDO'));
      await tester.pump();
      await tester.pump();

      expect(find.byType(TeamSelection), findsNWidgets(3));
      expect(_viewModel.status, StickerStatus.missing);
    });
  });

  group('AlbumScreen filters', () {
    testWidgets('selects the tab that was tapped and reloads the album', (
      tester,
    ) async {
      await _openAlbum(tester);
      _albums.albumCalls.clear();

      await tester.tap(find.text('FALTANDO'));
      await tester.pump();

      expect(_viewModel.status, StickerStatus.missing);
      expect(
        tester.widget<FilterTabs>(find.byType(FilterTabs)).selected,
        StickerStatus.missing,
      );
      expect(_albums.albumCalls, [(status: StickerStatus.missing, team: null)]);
    });

    testWidgets('clears the status when the all tab is tapped', (tester) async {
      await _openAlbum(tester);
      await tester.tap(find.text('REPETIDAS'));
      await tester.pump();
      await tester.pump();

      await tester.tap(find.text('TODAS'));
      await tester.pump();

      expect(_viewModel.status, isNull);
      expect(tester.widget<FilterTabs>(find.byType(FilterTabs)).selected, null);
    });

    testWidgets('selects the team that was tapped and reloads the album', (
      tester,
    ) async {
      await _openAlbum(tester);
      _albums.albumCalls.clear();

      await tester.tap(_discs.at(1));
      await tester.pump();

      expect(_viewModel.teamCode, 'ARG');
      expect(tester.widget<TeamStrip>(find.byType(TeamStrip)).selected, 'ARG');
      expect(_albums.albumCalls, [(status: null, team: 'ARG')]);
    });

    testWidgets('enlarges the selected team disc', (tester) async {
      await _openAlbum(tester);

      await tester.tap(_discs.at(0));
      await tester.pump();

      expect(tester.getSize(_discs.at(0)).width, 52);
      expect(tester.getSize(_discs.at(1)).width, 44);
    });

    testWidgets('keeps the tab counts when a filter is applied', (
      tester,
    ) async {
      await _openAlbum(tester);

      await tester.tap(find.text('FALTANDO'));
      await tester.pump();

      expect(_inTabs('980'), findsOneWidget);
      expect(_inTabs('300'), findsOneWidget);
    });
  });

  group('AlbumScreen refresh and navigation', () {
    testWidgets('reloads the three sources when pulled down', (tester) async {
      await _openAlbum(tester);

      unawaited(
        tester
            .state<RefreshIndicatorState>(find.byType(RefreshIndicator))
            .show(),
      );
      await tester.pump();
      await tester.pump(Duration(seconds: 1));
      await tester.pumpAndSettle();

      expect(_albums.albumCalls, hasLength(2));
      expect(_albums.summaryCalls, 2);
      expect(_teams.calls, 2);
    });

    testWidgets('goes back to the previous page when there is one', (
      tester,
    ) async {
      _useTallScreen(tester);
      final router = _router(initialLocation: Routes.home);

      await tester.pumpWidget(_app(router));
      unawaited(router.push(Routes.album));
      await tester.pumpAndSettle();
      expect(find.byType(AlbumScreen), findsOneWidget);

      await tester.tap(find.byTooltip('Voltar'));
      await tester.pumpAndSettle();

      expect(find.byType(AlbumScreen), findsNothing);
      expect(find.text('home page'), findsOneWidget);
    });

    testWidgets('goes to the home when there is nothing to go back to', (
      tester,
    ) async {
      await _openAlbum(tester, init: false);
      expect(find.byType(AlbumScreen), findsOneWidget);

      await tester.tap(find.byTooltip('Voltar'));
      await tester.pumpAndSettle();

      expect(find.byType(AlbumScreen), findsNothing);
      expect(find.text('home page'), findsOneWidget);
    });
  });

  group('AlbumScreen sticker detail', () {
    Album album() => Album(
      teams: [
        TeamAlbumGroup(
          team: _brazil,
          stickers: const [
            AlbumPosition(
              code: 'BRA-1',
              number: 1,
              status: StickerStatus.repeated,
              repeated: 2,
            ),
            AlbumPosition(
              code: 'BRA-2',
              number: 2,
              status: StickerStatus.missing,
              repeated: 0,
            ),
          ],
        ),
      ],
      loose: const [
        AlbumPosition(
          code: 'FWC-1',
          number: 1,
          status: StickerStatus.owned,
          repeated: 0,
        ),
      ],
    );

    setUp(() {
      _receivedArgs = null;
      _albums.album = Result.ok(album());
    });

    testWidgets('opens the detail of the tapped sticker', (tester) async {
      await _openAlbum(tester);

      await tester.tap(find.byType(StickerTile).first);
      await tester.pumpAndSettle();

      expect(find.byType(AlbumScreen), findsNothing);
      expect(find.text('detail BRA-1'), findsOneWidget);
    });

    testWidgets('sends the data of the sticker to the detail', (tester) async {
      await _openAlbum(tester);

      await tester.tap(find.byType(StickerTile).first);
      await tester.pumpAndSettle();

      expect(_receivedArgs, (
        code: 'BRA-1',
        number: 1,
        team: 'Brazil',
        country: 'BRA',
        teamColor: Color(0xFFFFDF00),
        rare: false,
        count: 3,
      ));
    });

    testWidgets('sends a count of zero for a missing sticker', (tester) async {
      await _openAlbum(tester);

      await tester.tap(find.byType(StickerTile).at(1));
      await tester.pumpAndSettle();

      expect(_receivedArgs?.code, 'BRA-2');
      expect(_receivedArgs?.count, 0);
    });

    testWidgets('names the special section as the team of its stickers', (
      tester,
    ) async {
      await _openAlbum(tester);

      await tester.tap(find.byType(StickerTile).last);
      await tester.pumpAndSettle();

      expect(_receivedArgs?.team, 'ESPECIAIS');
      expect(_receivedArgs?.teamColor, AppColors.ink);
    });

    testWidgets('reloads the album when the detail reports a change', (
      tester,
    ) async {
      await _openAlbum(tester);
      final loadsBefore = _albums.albumCalls.length;

      await tester.tap(find.byType(StickerTile).first);
      await tester.pumpAndSettle();
      await tester.tap(find.text('save'));
      await tester.pumpAndSettle();

      expect(find.byType(AlbumScreen), findsOneWidget);
      expect(_albums.albumCalls.length, loadsBefore + 1);
      expect(_albums.summaryCalls, 2);
      expect(_teams.calls, 2);
    });

    testWidgets('does not reload when the detail reports no change', (
      tester,
    ) async {
      await _openAlbum(tester);
      final loadsBefore = _albums.albumCalls.length;

      await tester.tap(find.byType(StickerTile).first);
      await tester.pumpAndSettle();
      await tester.tap(find.text('discard'));
      await tester.pumpAndSettle();

      expect(find.byType(AlbumScreen), findsOneWidget);
      expect(_albums.albumCalls.length, loadsBefore);
    });

    testWidgets('does not reload when the detail closes without a result', (
      tester,
    ) async {
      await _openAlbum(tester);
      final loadsBefore = _albums.albumCalls.length;

      await tester.tap(find.byType(StickerTile).first);
      await tester.pumpAndSettle();
      await tester.tap(find.text('close'));
      await tester.pumpAndSettle();

      expect(find.byType(AlbumScreen), findsOneWidget);
      expect(_albums.albumCalls.length, loadsBefore);
    });
  });
}
