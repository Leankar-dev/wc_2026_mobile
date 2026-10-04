import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';
import 'package:wc_2026_mobile/core/result.dart';
import 'package:wc_2026_mobile/data/repositories/album/album_repository.dart';
import 'package:wc_2026_mobile/data/repositories/team/team_repository.dart';
import 'package:wc_2026_mobile/domain/models/album/album.dart';
import 'package:wc_2026_mobile/domain/models/album/album_summary.dart';
import 'package:wc_2026_mobile/domain/models/album/recent_sticker.dart';
import 'package:wc_2026_mobile/domain/models/album/sticker_status.dart';
import 'package:wc_2026_mobile/domain/models/team/team.dart';
import 'package:wc_2026_mobile/ui/album/album_bindings.dart';
import 'package:wc_2026_mobile/ui/album/album_view_model.dart';

class _FakeAlbumRepository implements AlbumRepository {
  var albumCalls = 0;
  var summaryCalls = 0;

  @override
  Future<Result<Album>> getAlbum({StickerStatus? status, String? team}) async {
    albumCalls++;
    return Result.ok(const Album(teams: [], loose: []));
  }

  @override
  Future<Result<AlbumSummary>> getSummary() async {
    summaryCalls++;
    return Result.ok(
      const AlbumSummary(total: 980, missing: 300, repeated: 12),
    );
  }

  @override
  Future<Result<List<RecentSticker>>> getRecentStickers() async =>
      Result.ok(const []);
}

class _FakeTeamRepository implements TeamRepository {
  var calls = 0;

  @override
  Future<Result<List<Team>>> getTeams() async {
    calls++;
    return Result.ok(const []);
  }
}

Widget _app({
  required _FakeAlbumRepository albumRepository,
  required _FakeTeamRepository teamRepository,
  required Widget Function(BuildContext context) screenBuilder,
}) => MultiProvider(
  providers: [
    Provider<AlbumRepository>.value(value: albumRepository),
    Provider<TeamRepository>.value(value: teamRepository),
  ],
  child: MaterialApp(home: AlbumBindings(screenBuilder: screenBuilder)),
);

void main() {
  late _FakeAlbumRepository albumRepository;
  late _FakeTeamRepository teamRepository;

  setUp(() {
    albumRepository = _FakeAlbumRepository();
    teamRepository = _FakeTeamRepository();
  });

  group('AlbumBindings', () {
    testWidgets('provides the AlbumViewModel to the screen', (tester) async {
      AlbumViewModel? provided;

      await tester.pumpWidget(
        _app(
          albumRepository: albumRepository,
          teamRepository: teamRepository,
          screenBuilder: (context) {
            provided = context.read<AlbumViewModel>();
            return Text('screen');
          },
        ),
      );

      expect(find.text('screen'), findsOneWidget);
      expect(provided, isA<AlbumViewModel>());
    });

    testWidgets('starts the three loads when the screen opens', (tester) async {
      await tester.pumpWidget(
        _app(
          albumRepository: albumRepository,
          teamRepository: teamRepository,
          screenBuilder: (context) {
            context.read<AlbumViewModel>();
            return Text('screen');
          },
        ),
      );
      await tester.pump();

      expect(albumRepository.albumCalls, 1);
      expect(albumRepository.summaryCalls, 1);
      expect(teamRepository.calls, 1);
    });

    testWidgets('keeps the same view model and loads once across rebuilds', (
      tester,
    ) async {
      final seen = <AlbumViewModel>[];

      Widget app() => _app(
        albumRepository: albumRepository,
        teamRepository: teamRepository,
        screenBuilder: (context) {
          seen.add(context.read<AlbumViewModel>());
          return Text('screen');
        },
      );

      await tester.pumpWidget(app());
      await tester.pumpWidget(app());
      await tester.pump();

      expect(seen.toSet(), hasLength(1));
      expect(albumRepository.albumCalls, 1);
    });
  });
}
