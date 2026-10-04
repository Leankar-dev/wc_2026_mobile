import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
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
import 'package:wc_2026_mobile/ui/core/theme/theme.dart';
import 'package:wc_2026_mobile/ui/album/album_view_model.dart';

class _FakeAlbumRepository implements AlbumRepository {
  Result<Album> album = Result.ok(const Album(teams: [], loose: []));
  Result<AlbumSummary> summary = Result.ok(
    const AlbumSummary(total: 980, missing: 300, repeated: 12),
  );
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

Future<void> _settle() => Future<void>.delayed(Duration.zero);

void main() {
  late _FakeAlbumRepository albumRepository;
  late _FakeTeamRepository teamRepository;
  late AlbumViewModel viewModel;

  setUp(() {
    albumRepository = _FakeAlbumRepository();
    teamRepository = _FakeTeamRepository();
    viewModel = AlbumViewModel(
      albumRepository: albumRepository,
      teamRepository: teamRepository,
    );
  });

  tearDown(() => viewModel.dispose());

  group('AlbumViewModel', () {
    test('starts empty and without filters', () {
      expect(viewModel.teams, isEmpty);
      expect(viewModel.counts, isNull);
      expect(viewModel.status, isNull);
      expect(viewModel.teamCode, isNull);
      expect(viewModel.filtered, isFalse);
    });

    test('does not call any repository before init', () async {
      await _settle();

      expect(albumRepository.albumCalls, isEmpty);
      expect(albumRepository.summaryCalls, 0);
      expect(teamRepository.calls, 0);
    });

    test('init loads the album, the teams and the summary', () async {
      viewModel.init();
      await _settle();

      expect(albumRepository.albumCalls, hasLength(1));
      expect(teamRepository.calls, 1);
      expect(albumRepository.summaryCalls, 1);
      expect(viewModel.loadAlbum.complete, isTrue);
      expect(viewModel.loadTeams.complete, isTrue);
      expect(viewModel.loadSummary.complete, isTrue);
    });

    test('loads the album without filters', () async {
      viewModel.init();
      await _settle();

      expect(albumRepository.albumCalls, [(status: null, team: null)]);
    });

    test('exposes the teams and the counts once loaded', () async {
      viewModel.init();
      await _settle();

      expect(viewModel.teams, [_brazil, _argentina]);
      expect(
        viewModel.counts,
        const AlbumSummary(total: 980, missing: 300, repeated: 12),
      );
    });

    test('keeps the other loads when the album fails', () async {
      albumRepository.album = Result.error(const NetworkException());

      viewModel.init();
      await _settle();

      expect(viewModel.loadAlbum.error, isTrue);
      expect(viewModel.loadTeams.complete, isTrue);
      expect(viewModel.loadSummary.complete, isTrue);
      expect(viewModel.teams, isNotEmpty);
      expect(viewModel.counts, isNotNull);
    });

    test('keeps the teams empty when they fail', () async {
      teamRepository.teams = Result.error(const ServerException());

      viewModel.init();
      await _settle();

      expect(viewModel.loadTeams.error, isTrue);
      expect(viewModel.teams, isEmpty);
      expect(viewModel.loadAlbum.complete, isTrue);
      expect(viewModel.loadSummary.complete, isTrue);
    });

    test('keeps the counts empty when the summary fails', () async {
      albumRepository.summary = Result.error(const UnauthorizedException());

      viewModel.init();
      await _settle();

      expect(viewModel.loadSummary.error, isTrue);
      expect(viewModel.counts, isNull);
      expect(viewModel.loadAlbum.complete, isTrue);
      expect(viewModel.loadTeams.complete, isTrue);
    });

    test('reports the error of a failed load', () async {
      teamRepository.teams = Result.error(const NetworkException());

      viewModel.init();
      await _settle();

      expect(
        (viewModel.loadTeams.result as Error).error,
        isA<NetworkException>(),
      );
    });

    test('marks the album as running while it loads', () async {
      albumRepository.gate = Completer<void>();

      viewModel.init();
      await _settle();

      expect(viewModel.loadAlbum.running, isTrue);
      expect(viewModel.loadTeams.running, isFalse);

      albumRepository.gate!.complete();
      await _settle();

      expect(viewModel.loadAlbum.running, isFalse);
    });

    test('ignores a second album load while one is running', () async {
      albumRepository.gate = Completer<void>();

      viewModel.init();
      await _settle();
      await viewModel.loadAlbum.execute();

      expect(albumRepository.albumCalls, hasLength(1));

      albumRepository.gate!.complete();
      await _settle();
    });

    test('loads the album again after the previous load finishes', () async {
      viewModel.init();
      await _settle();
      await viewModel.loadAlbum.execute();

      expect(albumRepository.albumCalls, hasLength(2));
    });
  });

  group('AlbumViewModel filters', () {
    setUp(() async {
      viewModel.init();
      await _settle();
      albumRepository.albumCalls.clear();
    });

    test('selectedStatus stores the status and reloads the album', () async {
      viewModel.selectedStatus(StickerStatus.missing);
      await _settle();

      expect(viewModel.status, StickerStatus.missing);
      expect(viewModel.filtered, isTrue);
      expect(albumRepository.albumCalls, [
        (status: StickerStatus.missing, team: null),
      ]);
    });

    test('selectedStatus with null clears the status', () async {
      viewModel.selectedStatus(StickerStatus.repeated);
      await _settle();
      albumRepository.albumCalls.clear();

      viewModel.selectedStatus(null);
      await _settle();

      expect(viewModel.status, isNull);
      expect(viewModel.filtered, isFalse);
      expect(albumRepository.albumCalls, [(status: null, team: null)]);
    });

    test(
      'selectedStatus ignores the status that is already selected',
      () async {
        viewModel.selectedStatus(StickerStatus.missing);
        await _settle();
        albumRepository.albumCalls.clear();

        viewModel.selectedStatus(StickerStatus.missing);
        await _settle();

        expect(albumRepository.albumCalls, isEmpty);
      },
    );

    test('selectedStatus ignores null when nothing is selected', () async {
      viewModel.selectedStatus(null);
      await _settle();

      expect(albumRepository.albumCalls, isEmpty);
    });

    test('toggleTeam stores the team and reloads the album', () async {
      viewModel.toggleTeam('BRA');
      await _settle();

      expect(viewModel.teamCode, 'BRA');
      expect(viewModel.filtered, isTrue);
      expect(albumRepository.albumCalls, [(status: null, team: 'BRA')]);
    });

    test('toggleTeam clears the team that is already selected', () async {
      viewModel.toggleTeam('BRA');
      await _settle();
      albumRepository.albumCalls.clear();

      viewModel.toggleTeam('BRA');
      await _settle();

      expect(viewModel.teamCode, isNull);
      expect(viewModel.filtered, isFalse);
      expect(albumRepository.albumCalls, [(status: null, team: null)]);
    });

    test('toggleTeam switches to another team', () async {
      viewModel.toggleTeam('BRA');
      await _settle();
      viewModel.toggleTeam('ARG');
      await _settle();

      expect(viewModel.teamCode, 'ARG');
      expect(albumRepository.albumCalls.last, (status: null, team: 'ARG'));
    });

    test('combines the status and the team in the same request', () async {
      viewModel.selectedStatus(StickerStatus.repeated);
      await _settle();
      viewModel.toggleTeam('BRA');
      await _settle();

      expect(albumRepository.albumCalls.last, (
        status: StickerStatus.repeated,
        team: 'BRA',
      ));
    });

    test('notifies listeners when a filter changes', () async {
      var notifications = 0;
      viewModel.addListener(() => notifications++);

      viewModel.selectedStatus(StickerStatus.missing);
      viewModel.toggleTeam('BRA');

      expect(notifications, 2);
    });

    test('does not notify when the filter does not change', () async {
      var notifications = 0;
      viewModel.addListener(() => notifications++);

      viewModel.selectedStatus(null);

      expect(notifications, 0);
    });

    test('keeps the new filter but drops the reload during a load', () async {
      albumRepository.gate = Completer<void>();
      viewModel.loadAlbum.execute();
      await _settle();
      albumRepository.albumCalls.clear();

      viewModel.selectedStatus(StickerStatus.missing);
      await _settle();

      expect(viewModel.status, StickerStatus.missing);
      expect(albumRepository.albumCalls, isEmpty);

      albumRepository.gate!.complete();
      await _settle();
    });
  });

  group('AlbumViewModel refresh', () {
    test('reloads the album, the teams and the summary', () async {
      viewModel.init();
      await _settle();

      await viewModel.refresh();

      expect(albumRepository.albumCalls, hasLength(2));
      expect(teamRepository.calls, 2);
      expect(albumRepository.summaryCalls, 2);
    });

    test('keeps the active filters', () async {
      viewModel.init();
      await _settle();
      viewModel.toggleTeam('BRA');
      await _settle();

      await viewModel.refresh();

      expect(albumRepository.albumCalls.last, (status: null, team: 'BRA'));
    });

    test('refreshes the counts', () async {
      viewModel.init();
      await _settle();
      albumRepository.summary = Result.ok(
        const AlbumSummary(total: 980, missing: 100, repeated: 3),
      );

      await viewModel.refresh();

      expect(viewModel.counts?.missing, 100);
    });
  });

  group('AlbumViewModel sections', () {
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

    Future<void> loadAlbum(Album album) async {
      albumRepository.album = Result.ok(album);
      viewModel.init();
      await _settle();
    }

    test('has no sections before the album loads', () {
      expect(viewModel.sectionsMatching(''), isEmpty);
    });

    test('has no sections when the album is empty', () async {
      await loadAlbum(const Album(teams: [], loose: []));

      expect(viewModel.sectionsMatching(''), isEmpty);
    });

    test('has no sections when the album fails', () async {
      albumRepository.album = Result.error(const NetworkException());
      viewModel.init();
      await _settle();

      expect(viewModel.sectionsMatching(''), isEmpty);
    });

    test('builds one section per team with its name, flag and color', () async {
      await loadAlbum(
        Album(
          teams: [
            TeamAlbumGroup(team: _brazil, stickers: [position('BRA-1', 1)]),
            TeamAlbumGroup(team: _argentina, stickers: [position('ARG-1', 1)]),
          ],
          loose: const [],
        ),
      );

      final sections = viewModel.sectionsMatching('');

      expect(sections.map((s) => s.name), ['Brazil', 'Argentina']);
      expect(sections.map((s) => s.flagPath), [
        '/flags/bra.png',
        '/flags/arg.png',
      ]);
      expect(sections.map((s) => s.color), [
        Color(0xFFFFDF00),
        Color(0xFF6CACE4),
      ]);
    });

    test('adds the special section after the teams', () async {
      await loadAlbum(
        Album(
          teams: [
            TeamAlbumGroup(team: _brazil, stickers: [position('BRA-1', 1)]),
          ],
          loose: [position('FWC-1', 1)],
        ),
      );

      final sections = viewModel.sectionsMatching('');

      expect(sections.map((s) => s.name), ['Brazil', 'ESPECIAIS']);
      expect(sections.last.flagPath, isNull);
      expect(sections.last.color, AppColors.ink);
    });

    test('skips teams without stickers and an empty special list', () async {
      await loadAlbum(
        Album(
          teams: [
            TeamAlbumGroup(team: _brazil, stickers: const []),
            TeamAlbumGroup(team: _argentina, stickers: [position('ARG-1', 1)]),
          ],
          loose: const [],
        ),
      );

      expect(viewModel.sectionsMatching('').map((s) => s.name), ['Argentina']);
    });

    test('counts the owned and repeated stickers as collected', () async {
      await loadAlbum(
        Album(
          teams: [
            TeamAlbumGroup(
              team: _brazil,
              stickers: [
                position('BRA-1', 1, status: StickerStatus.owned),
                position(
                  'BRA-2',
                  2,
                  status: StickerStatus.repeated,
                  repeated: 2,
                ),
                position('BRA-3', 3),
                position('BRA-4', 4),
              ],
            ),
          ],
          loose: const [],
        ),
      );

      final section = viewModel.sectionsMatching('').single;

      expect(section.progress, '2 / 4');
      expect(section.stickers.map((s) => s.collected), [
        true,
        true,
        false,
        false,
      ]);
    });

    test('maps each sticker to its view', () async {
      await loadAlbum(
        Album(
          teams: [
            TeamAlbumGroup(
              team: _brazil,
              stickers: [
                position(
                  'BRA-7',
                  7,
                  status: StickerStatus.repeated,
                  repeated: 2,
                ),
                position('BRA-8', 8),
              ],
            ),
          ],
          loose: const [],
        ),
      );

      final stickers = viewModel.sectionsMatching('').single.stickers;

      expect(stickers.first, (
        code: 'BRA-7',
        number: 7,
        label: 'BRA',
        collected: true,
        count: 3,
        player: 'JOGADOR 7',
      ));
      expect(stickers.last, (
        code: 'BRA-8',
        number: 8,
        label: 'BRA',
        collected: false,
        count: 0,
        player: 'JOGADOR 8',
      ));
    });

    test('labels the special stickers as special', () async {
      await loadAlbum(Album(teams: const [], loose: [position('FWC-3', 3)]));

      final sticker = viewModel.sectionsMatching('').single.stickers.single;

      expect(sticker.label, 'FWC');
      expect(sticker.player, 'ESPECIAL 3');
    });

    test('isCollected is false only for missing stickers', () {
      expect(viewModel.isCollected(position('A-1', 1)), isFalse);
      expect(
        viewModel.isCollected(position('A-1', 1, status: StickerStatus.owned)),
        isTrue,
      );
      expect(
        viewModel.isCollected(
          position('A-1', 1, status: StickerStatus.repeated),
        ),
        isTrue,
      );
    });

    Album twoTeamsAndSpecials() => Album(
      teams: [
        TeamAlbumGroup(
          team: _brazil,
          stickers: [
            position('BRA-1', 1, status: StickerStatus.owned),
            position('BRA-2', 2),
            position('BRA-10', 10),
          ],
        ),
        TeamAlbumGroup(
          team: _argentina,
          stickers: [position('ARG-1', 1), position('ARG-2', 2)],
        ),
      ],
      loose: [position('FWC-1', 1), position('FWC-2', 2)],
    );

    List<String> namesFor(String term) =>
        viewModel.sectionsMatching(term).map((s) => s.name).toList();

    test('a blank term keeps every section and sticker', () async {
      await loadAlbum(twoTeamsAndSpecials());

      final sections = viewModel.sectionsMatching('   ');

      expect(sections.map((s) => s.name), ['Brazil', 'Argentina', 'ESPECIAIS']);
      expect(sections.map((s) => s.stickers.length), [3, 2, 2]);
    });

    test('a term matching the team name keeps all its stickers', () async {
      await loadAlbum(twoTeamsAndSpecials());

      final sections = viewModel.sectionsMatching('brazil');

      expect(sections.map((s) => s.name), ['Brazil']);
      expect(sections.single.stickers, hasLength(3));
    });

    test('the search ignores case and surrounding spaces', () async {
      await loadAlbum(twoTeamsAndSpecials());

      expect(namesFor('  BrAzIl '), ['Brazil']);
    });

    test('a term matching sticker codes keeps only those stickers', () async {
      await loadAlbum(twoTeamsAndSpecials());

      final sections = viewModel.sectionsMatching('bra-1');

      expect(sections.map((s) => s.name), ['Brazil']);
      expect(sections.single.stickers.map((s) => s.code), ['BRA-1', 'BRA-10']);
    });

    test('a number term matches the codes that contain it', () async {
      await loadAlbum(twoTeamsAndSpecials());

      final sections = viewModel.sectionsMatching('1');

      expect(sections.map((s) => s.name), ['Brazil', 'Argentina', 'ESPECIAIS']);
      expect(sections.map((s) => s.stickers.length), [2, 1, 1]);
    });

    test('the team code reaches the stickers of that team', () async {
      await loadAlbum(twoTeamsAndSpecials());

      final sections = viewModel.sectionsMatching('arg');

      expect(sections.map((s) => s.name), ['Argentina']);
      expect(sections.single.stickers, hasLength(2));
    });

    test('the special section is found by its name', () async {
      await loadAlbum(twoTeamsAndSpecials());

      final sections = viewModel.sectionsMatching('especiais');

      expect(sections.map((s) => s.name), ['ESPECIAIS']);
      expect(sections.single.stickers, hasLength(2));
    });

    test('drops the sections that have no match', () async {
      await loadAlbum(twoTeamsAndSpecials());

      expect(viewModel.sectionsMatching('zzz'), isEmpty);
    });

    test('shows collected over total without filters or search', () async {
      await loadAlbum(twoTeamsAndSpecials());

      final progress = viewModel.sectionsMatching('').map((s) => s.progress);

      expect(progress, ['1 / 3', '0 / 2', '0 / 2']);
    });

    test('shows the item count while searching', () async {
      await loadAlbum(twoTeamsAndSpecials());

      expect(viewModel.sectionsMatching('brazil').single.progress, '3 itens');
      expect(viewModel.sectionsMatching('bra-10').single.progress, '1 Item');
    });

    test('the item count follows the matched stickers', () async {
      await loadAlbum(twoTeamsAndSpecials());

      expect(viewModel.sectionsMatching('bra-1').single.progress, '2 itens');
    });

    test('shows the item count when a status filter is active', () async {
      await loadAlbum(twoTeamsAndSpecials());

      viewModel.selectedStatus(StickerStatus.missing);
      await _settle();

      expect(viewModel.sectionsMatching('').first.progress, '3 itens');
    });

    test('shows the item count when a team filter is active', () async {
      await loadAlbum(twoTeamsAndSpecials());

      viewModel.toggleTeam('BRA');
      await _settle();

      expect(viewModel.sectionsMatching('').first.progress, '3 itens');
    });

    test(
      'goes back to collected over total when the filters are cleared',
      () async {
        await loadAlbum(twoTeamsAndSpecials());
        viewModel.toggleTeam('BRA');
        await _settle();
        viewModel.toggleTeam('BRA');
        await _settle();

        expect(viewModel.sectionsMatching('').first.progress, '1 / 3');
      },
    );
  });
}
