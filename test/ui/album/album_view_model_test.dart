import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:wc_2026_mobile/core/exceptions/app_exception.dart';
import 'package:wc_2026_mobile/core/result.dart';
import 'package:wc_2026_mobile/data/repositories/album/album_repository.dart';
import 'package:wc_2026_mobile/data/repositories/team/team_repository.dart';
import 'package:wc_2026_mobile/domain/models/album/album.dart';
import 'package:wc_2026_mobile/domain/models/album/album_summary.dart';
import 'package:wc_2026_mobile/domain/models/album/recent_sticker.dart';
import 'package:wc_2026_mobile/domain/models/album/sticker_status.dart';
import 'package:wc_2026_mobile/domain/models/team/team.dart';
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
}
