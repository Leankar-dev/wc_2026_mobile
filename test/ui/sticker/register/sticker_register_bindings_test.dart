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
import 'package:wc_2026_mobile/ui/sticker/register/sticker_register_bindings.dart';
import 'package:wc_2026_mobile/ui/sticker/register/sticker_register_screen.dart';
import 'package:wc_2026_mobile/ui/sticker/register/sticker_register_view_model.dart';

class _FakeAlbumRepository implements AlbumRepository {
  final registered = <({String code, int quantity})>[];

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
  }) async => Result.done;

  @override
  Future<Result<void>> removeSticker(String code) async => Result.done;

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

class _FakeTeamRepository implements TeamRepository {
  var calls = 0;

  @override
  Future<Result<List<Team>>> getTeams() async {
    calls++;
    return Result.ok(const [
      Team(
        code: 'BRA',
        name: 'Brazil',
        flagUrl: '/flags/bra.png',
        primaryColor: 0xFFFFDF00,
      ),
    ]);
  }
}

late _FakeAlbumRepository _albums;
late _FakeTeamRepository _teams;

Widget _app({
  required Widget Function(BuildContext context) screenBuilder,
  Key? key,
}) => MultiProvider(
  providers: [
    Provider<AlbumRepository>.value(value: _albums),
    Provider<TeamRepository>.value(value: _teams),
  ],
  child: MaterialApp(
    home: StickerRegisterBindings(key: key, screenBuilder: screenBuilder),
  ),
);

void main() {
  setUp(() {
    _albums = _FakeAlbumRepository();
    _teams = _FakeTeamRepository();
  });

  group('StickerRegisterBindings', () {
    testWidgets('provides the view model to the screen', (tester) async {
      StickerRegisterViewModel? provided;

      await tester.pumpWidget(
        _app(
          screenBuilder: (context) {
            provided = context.read<StickerRegisterViewModel>();
            return Text('screen');
          },
        ),
      );

      expect(find.text('screen'), findsOneWidget);
      expect(provided, isA<StickerRegisterViewModel>());
    });

    testWidgets('loads the teams when the screen reads the view model', (
      tester,
    ) async {
      await tester.pumpWidget(
        _app(
          screenBuilder: (context) {
            context.read<StickerRegisterViewModel>();
            return Text('screen');
          },
        ),
      );
      await tester.pump();

      expect(_teams.calls, 1);
    });

    testWidgets('does not load the teams until the view model is read', (
      tester,
    ) async {
      await tester.pumpWidget(_app(screenBuilder: (context) => Text('screen')));
      await tester.pump();

      expect(_teams.calls, 0);
    });

    testWidgets('starts with an empty code', (tester) async {
      late StickerRegisterViewModel viewModel;

      await tester.pumpWidget(
        _app(
          screenBuilder: (context) {
            viewModel = context.read<StickerRegisterViewModel>();
            return Text('screen');
          },
        ),
      );

      expect(viewModel.code, isEmpty);
      expect(viewModel.changed, isFalse);
    });

    testWidgets('gives the view model the repositories to identify and save', (
      tester,
    ) async {
      late StickerRegisterViewModel viewModel;

      await tester.pumpWidget(
        _app(
          screenBuilder: (context) {
            viewModel = context.read<StickerRegisterViewModel>();
            return Text('screen');
          },
        ),
      );
      await tester.pump();
      'BRA01'.split('').forEach(viewModel.type);
      await viewModel.register.execute(viewModel.match!);

      expect(_albums.registered, [(code: 'BRA-1', quantity: 1)]);
    });

    testWidgets('keeps the same view model across rebuilds', (tester) async {
      final seen = <StickerRegisterViewModel>[];

      Widget app() => _app(
        screenBuilder: (context) {
          seen.add(context.read<StickerRegisterViewModel>());
          return Text('screen');
        },
      );

      await tester.pumpWidget(app());
      await tester.pumpWidget(app());
      await tester.pump();

      expect(seen.toSet(), hasLength(1));
      expect(_teams.calls, 1);
    });

    testWidgets('builds a different view model for each screen', (
      tester,
    ) async {
      final seen = <StickerRegisterViewModel>[];

      Widget app(Key key) => _app(
        key: key,
        screenBuilder: (context) {
          seen.add(context.read<StickerRegisterViewModel>());
          return Text('screen');
        },
      );

      await tester.pumpWidget(app(ValueKey('a')));
      await tester.pumpWidget(app(ValueKey('b')));

      expect(seen.toSet(), hasLength(2));
    });

    testWidgets('builds the register screen with the provided view model', (
      tester,
    ) async {
      tester.view.physicalSize = Size(390, 1400);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        _app(
          screenBuilder: (context) =>
              StickerRegisterScreen(viewModel: context.read()),
        ),
      );
      await tester.pump();

      expect(find.byType(StickerRegisterScreen), findsOneWidget);
    });
  });
}
