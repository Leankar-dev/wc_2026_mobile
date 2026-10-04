import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:wc_2026_mobile/core/exceptions/app_exception.dart';
import 'package:wc_2026_mobile/core/result.dart';
import 'package:wc_2026_mobile/data/repositories/album/album_repository.dart';
import 'package:wc_2026_mobile/domain/models/album/album_summary.dart';
import 'package:wc_2026_mobile/domain/models/album/recent_sticker.dart';
import 'package:wc_2026_mobile/domain/models/team/team.dart';
import 'package:wc_2026_mobile/ui/core/theme/theme.dart';
import 'package:wc_2026_mobile/ui/home/home_view_model.dart';

class _FakeAlbumRepository implements AlbumRepository {
  _FakeAlbumRepository({required this.summary, required this.recent});

  Result<AlbumSummary> summary;
  Result<List<RecentSticker>> recent;
  var summaryCalls = 0;
  var recentCalls = 0;

  @override
  Future<Result<AlbumSummary>> getSummary() async {
    summaryCalls++;
    return summary;
  }

  @override
  Future<Result<List<RecentSticker>>> getRecentStickers() async {
    recentCalls++;
    return recent;
  }
}

const _team = Team(
  code: 'BRA',
  name: 'Brazil',
  flagUrl: '/flags/bra.png',
  primaryColor: 0xFFFFDF00,
);

Future<void> _settle() => Future<void>.delayed(Duration.zero);

void main() {
  late _FakeAlbumRepository repository;
  late HomeViewModel viewModel;

  setUp(() {
    repository = _FakeAlbumRepository(
      summary: Result.ok(
        const AlbumSummary(total: 980, missing: 300, repeated: 12),
      ),
      recent: Result.ok(const [
        RecentSticker(code: 'BRA-1', number: 1, repeated: 2, team: _team),
      ]),
    );
    viewModel = HomeViewModel(albumRepository: repository);
  });

  tearDown(() => viewModel.dispose());

  group('HomeViewModel', () {
    test('starts without data', () {
      expect(viewModel.progress, isNull);
      expect(viewModel.recentStickers, isEmpty);
    });

    test('init loads the summary and the recent stickers', () async {
      viewModel.init();
      await _settle();

      expect(viewModel.progress, (collected: 680, total: 980, repeated: 12));
      expect(viewModel.recentStickers, hasLength(1));
      expect(repository.summaryCalls, 1);
      expect(repository.recentCalls, 1);
    });

    test('maps a sticker with team to its view', () async {
      viewModel.init();
      await _settle();

      expect(viewModel.recentStickers.single, (
        code: 'BRA-1',
        number: 1,
        label: 'BRA',
        teamName: 'Brazil',
        teamColor: const Color(0xFFFFDF00),
        flagCode: 'BRA',
        count: 3,
      ));
    });

    test('maps a sticker without team using the code as fallback', () async {
      repository.recent = Result.ok(const [
        RecentSticker(code: 'FWC-9', number: 9, repeated: 0),
      ]);

      viewModel.init();
      await _settle();

      expect(viewModel.recentStickers.single, (
        code: 'FWC-9',
        number: 9,
        label: 'FWC',
        teamName: 'FWC-9',
        teamColor: AppColors.ink,
        flagCode: null,
        count: 1,
      ));
    });

    test(
      'keeps the progress empty and flags the error when the summary fails',
      () async {
        repository.summary = Result.error(const NetworkException());

        viewModel.init();
        await _settle();

        expect(viewModel.progress, isNull);
        expect(viewModel.loadSummary.error, isTrue);
        expect(viewModel.loadRecent.complete, isTrue);
      },
    );

    test(
      'keeps the stickers empty and flags the error when recent fails',
      () async {
        repository.recent = Result.error(const ServerException());

        viewModel.init();
        await _settle();

        expect(viewModel.recentStickers, isEmpty);
        expect(viewModel.loadRecent.error, isTrue);
        expect(viewModel.loadSummary.complete, isTrue);
      },
    );

    test('refresh loads both sources again', () async {
      viewModel.init();
      await _settle();

      repository.summary = Result.ok(
        const AlbumSummary(total: 980, missing: 100, repeated: 3),
      );
      await viewModel.refresh();

      expect(viewModel.progress, (collected: 880, total: 980, repeated: 3));
      expect(repository.summaryCalls, 2);
      expect(repository.recentCalls, 2);
    });

    test('notifies listeners when the data arrives', () async {
      var notifications = 0;
      viewModel.addListener(() => notifications++);

      viewModel.init();
      await _settle();

      expect(notifications, greaterThanOrEqualTo(2));
    });
  });
}
