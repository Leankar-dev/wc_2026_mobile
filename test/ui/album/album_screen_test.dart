import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:wc_2026_mobile/core/exceptions/app_exception.dart';
import 'package:wc_2026_mobile/core/result.dart';
import 'package:wc_2026_mobile/data/repositories/album/album_repository.dart';
import 'package:wc_2026_mobile/data/repositories/team/team_repository.dart';
import 'package:wc_2026_mobile/domain/models/album/album.dart';
import 'package:wc_2026_mobile/domain/models/album/album_summary.dart';
import 'package:wc_2026_mobile/domain/models/album/recent_sticker.dart';
import 'package:wc_2026_mobile/domain/models/album/sticker_status.dart';
import 'package:wc_2026_mobile/domain/models/team/team.dart';
import 'package:wc_2026_mobile/routing/routes.dart';
import 'package:wc_2026_mobile/ui/album/album_screen.dart';
import 'package:wc_2026_mobile/ui/album/album_view_model.dart';
import 'package:wc_2026_mobile/ui/album/widgets/filter_tabs.dart';
import 'package:wc_2026_mobile/ui/album/widgets/header.dart';
import 'package:wc_2026_mobile/ui/album/widgets/team_selection.dart';
import 'package:wc_2026_mobile/ui/album/widgets/team_strip.dart';

class _FakeAlbumRepository implements AlbumRepository {
  Result<AlbumSummary> summary = Result.ok(
    const AlbumSummary(total: 980, missing: 300, repeated: 12),
  );
  final albumCalls = <({StickerStatus? status, String? team})>[];
  var summaryCalls = 0;

  @override
  Future<Result<Album>> getAlbum({StickerStatus? status, String? team}) async {
    albumCalls.add((status: status, team: team));
    return Result.ok(const Album(teams: [], loose: []));
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

GoRouter _router({String initialLocation = Routes.album}) => GoRouter(
  initialLocation: initialLocation,
  routes: [
    GoRoute(path: Routes.home, builder: (_, _) => Text('home page')),
    GoRoute(
      path: Routes.album,
      builder: (_, _) => AlbumScreen(viewModel: _viewModel),
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

    testWidgets('keeps the example blocks of teams', (tester) async {
      await _openAlbum(tester);

      expect(find.byType(TeamSelection), findsNWidgets(2));
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
}
