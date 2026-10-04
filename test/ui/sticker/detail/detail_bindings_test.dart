import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';
import 'package:wc_2026_mobile/core/result.dart';
import 'package:wc_2026_mobile/data/repositories/album/album_repository.dart';
import 'package:wc_2026_mobile/domain/models/album/album.dart';
import 'package:wc_2026_mobile/domain/models/album/album_summary.dart';
import 'package:wc_2026_mobile/domain/models/album/recent_sticker.dart';
import 'package:wc_2026_mobile/domain/models/album/sticker_status.dart';
import 'package:wc_2026_mobile/ui/sticker/detail/detail_bindings.dart';
import 'package:wc_2026_mobile/ui/sticker/detail/detail_screen.dart';
import 'package:wc_2026_mobile/ui/sticker/detail/detail_view_model.dart';

class _FakeAlbumRepository implements AlbumRepository {
  final registered = <({String code, int quantity})>[];
  final updated = <({String code, int quantity})>[];
  final removed = <String>[];

  @override
  Future<Result<void>> registerSticker({
    required String code,
    required int quantity,
  }) async {
    registered.add((code: code, quantity: quantity));
    return Result.done;
  }

  @override
  Future<Result<void>> updateStickerQuantity({
    required String code,
    required int quantity,
  }) async {
    updated.add((code: code, quantity: quantity));
    return Result.done;
  }

  @override
  Future<Result<void>> removeSticker(String code) async {
    removed.add(code);
    return Result.done;
  }

  @override
  Future<Result<Album>> getAlbum({StickerStatus? status, String? team}) async =>
      Result.ok(const Album(teams: [], loose: []));

  @override
  Future<Result<AlbumSummary>> getSummary() async =>
      Result.ok(const AlbumSummary(total: 0, missing: 0, repeated: 0));

  @override
  Future<Result<List<RecentSticker>>> getRecentStickers() async =>
      Result.ok(const []);
}

const DetailArgs _args = (
  code: 'BRA-1',
  number: 1,
  team: 'Brazil',
  country: 'BRA',
  teamColor: Color(0xFFFFDF00),
  rare: false,
  count: 2,
);

DetailArgs _withCount(int count) => (
  code: _args.code,
  number: _args.number,
  team: _args.team,
  country: _args.country,
  teamColor: _args.teamColor,
  rare: _args.rare,
  count: count,
);

Widget _app({
  required _FakeAlbumRepository repository,
  required Widget Function(BuildContext context) screenBuilder,
  DetailArgs args = _args,
  Key? key,
}) => Provider<AlbumRepository>.value(
  value: repository,
  child: MaterialApp(
    home: DetailBindings(
      key: key,
      stickers: args,
      screenBuilder: screenBuilder,
    ),
  ),
);

void main() {
  late _FakeAlbumRepository repository;

  setUp(() => repository = _FakeAlbumRepository());

  group('DetailBindings', () {
    testWidgets('builds the screen with the view model available', (
      tester,
    ) async {
      DetailViewModel? provided;

      await tester.pumpWidget(
        _app(
          repository: repository,
          screenBuilder: (context) {
            provided = context.read<DetailViewModel>();
            return Text('detail');
          },
        ),
      );

      expect(find.text('detail'), findsOneWidget);
      expect(provided, isA<DetailViewModel>());
    });

    testWidgets('starts the view model with the count of the sticker', (
      tester,
    ) async {
      late DetailViewModel viewModel;

      await tester.pumpWidget(
        _app(
          repository: repository,
          screenBuilder: (context) {
            viewModel = context.read<DetailViewModel>();
            return Text('detail');
          },
        ),
      );

      expect(viewModel.count, 2);
      expect(viewModel.collected, isTrue);
      expect(viewModel.inAlbum, isTrue);
    });

    testWidgets('starts a missing sticker out of the album', (tester) async {
      late DetailViewModel viewModel;

      await tester.pumpWidget(
        _app(
          repository: repository,
          args: _withCount(0),
          screenBuilder: (context) {
            viewModel = context.read<DetailViewModel>();
            return Text('detail');
          },
        ),
      );

      expect(viewModel.count, 0);
      expect(viewModel.collected, isFalse);
      expect(viewModel.inAlbum, isFalse);
    });

    testWidgets('saves with the code of the sticker and the repository', (
      tester,
    ) async {
      late DetailViewModel viewModel;

      await tester.pumpWidget(
        _app(
          repository: repository,
          screenBuilder: (context) {
            viewModel = context.read<DetailViewModel>();
            return Text('detail');
          },
        ),
      );
      await viewModel.save.execute();

      expect(repository.updated, [(code: 'BRA-1', quantity: 2)]);
    });

    testWidgets('keeps the same view model across rebuilds', (tester) async {
      final seen = <DetailViewModel>[];

      Widget app() => _app(
        repository: repository,
        screenBuilder: (context) {
          seen.add(context.read<DetailViewModel>());
          return Text('detail');
        },
      );

      await tester.pumpWidget(app());
      await tester.pumpWidget(app());

      expect(seen.toSet(), hasLength(1));
    });

    testWidgets('builds a different view model for each screen', (
      tester,
    ) async {
      final seen = <DetailViewModel>[];

      Widget app(Key key) => _app(
        key: key,
        repository: repository,
        screenBuilder: (context) {
          seen.add(context.read<DetailViewModel>());
          return Text('detail');
        },
      );

      await tester.pumpWidget(app(ValueKey('a')));
      await tester.pumpWidget(app(ValueKey('b')));

      expect(seen.toSet(), hasLength(2));
    });

    testWidgets('keeps the screen working with the args type', (tester) async {
      await tester.pumpWidget(
        _app(
          repository: repository,
          screenBuilder: (context) => DetailScreen(sticker: _args),
        ),
      );

      expect(find.byType(DetailScreen), findsOneWidget);
    });
  });
}
