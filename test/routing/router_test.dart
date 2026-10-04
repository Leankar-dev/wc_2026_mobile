import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';
import 'package:wc_2026_mobile/core/auth/auth_session_notifier.dart';
import 'package:wc_2026_mobile/core/result.dart';
import 'package:wc_2026_mobile/data/repositories/album/album_repository.dart';
import 'package:wc_2026_mobile/data/repositories/auth_session/auth_session_repository.dart';
import 'package:wc_2026_mobile/domain/models/album/album.dart';
import 'package:wc_2026_mobile/domain/models/album/album_summary.dart';
import 'package:wc_2026_mobile/domain/models/album/recent_sticker.dart';
import 'package:wc_2026_mobile/domain/models/album/sticker_status.dart';
import 'package:wc_2026_mobile/domain/models/auth_session.dart';
import 'package:wc_2026_mobile/domain/use_cases/auth/auth_logout_use_case.dart';
import 'package:wc_2026_mobile/domain/use_cases/auth/auth_restore_session_use_case.dart';
import 'package:wc_2026_mobile/routing/router.dart';
import 'package:wc_2026_mobile/routing/routes.dart';
import 'package:wc_2026_mobile/ui/sticker/detail/detail_screen.dart';
import 'package:wc_2026_mobile/ui/sticker/detail/widgets/backdrop.dart';
import 'package:wc_2026_mobile/ui/sticker/detail/widgets/top_bar.dart';

class _FakeAuthSessionRepository implements AuthSessionRepository {
  @override
  Future<Result<void>> delete() async => Result.done;

  @override
  Future<Result<AuthSession?>> fetch() async => Result.ok(
    const AuthSession(
      token: 'abc',
      user: AuthSessionUser(name: 'Ada', email: 'ada@mail.com'),
    ),
  );

  @override
  Future<Result<void>> save(AuthSession session) async => Result.done;
}

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

AuthSessionNotifier _signedInNotifier() {
  final repository = _FakeAuthSessionRepository();
  return AuthSessionNotifier(
    authLogoutUseCase: AuthLogoutUseCase(authSessionRepository: repository),
    authRestoreSessionUseCase: AuthRestoreSessionUseCase(
      authSessionRepository: repository,
    ),
    sessionEnded: Stream<void>.empty(),
  );
}

Future<GoRouter> _openApp(
  WidgetTester tester,
  AuthSessionNotifier notifier,
) async {
  tester.view.physicalSize = Size(390, 1600);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);

  final appRouter = router(notifier);

  await tester.pumpWidget(
    MultiProvider(
      providers: [
        ChangeNotifierProvider<AuthSessionNotifier>.value(value: notifier),
        Provider<AlbumRepository>.value(value: _FakeAlbumRepository()),
      ],
      child: MaterialApp.router(
        routerConfig: appRouter,
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(textScaler: TextScaler.linear(0.8)),
          child: child!,
        ),
      ),
    ),
  );
  await tester.pump();
  return appRouter;
}

void main() {
  group('router sticker detail route', () {
    testWidgets('opens the detail screen with the sticker it receives', (
      tester,
    ) async {
      final notifier = _signedInNotifier();
      final appRouter = await _openApp(tester, notifier);

      appRouter.go(Routes.sticker('BRA-1'), extra: _args);
      await tester.pump();
      await tester.pump();

      final screen = tester.widget<DetailScreen>(find.byType(DetailScreen));

      expect(screen.sticker, _args);
      expect(find.byType(Backdrop), findsOneWidget);
      expect(find.byType(TopBar), findsOneWidget);

      notifier.dispose();
    });

    testWidgets('starts the detail of a missing sticker without a copy', (
      tester,
    ) async {
      final notifier = _signedInNotifier();
      final appRouter = await _openApp(tester, notifier);

      appRouter.go(
        Routes.sticker('BRA-1'),
        extra: (
          code: 'BRA-1',
          number: 1,
          team: 'Brazil',
          country: 'BRA',
          teamColor: Color(0xFFFFDF00),
          rare: false,
          count: 0,
        ),
      );
      await tester.pump();
      await tester.pump();

      expect(find.text('TENHO ESTA FIGURINHA'), findsOneWidget);
      expect(find.text('EXCLUIR FIGURINHA'), findsNothing);

      notifier.dispose();
    });

    testWidgets('starts the detail of a sticker in the album', (tester) async {
      final notifier = _signedInNotifier();
      final appRouter = await _openApp(tester, notifier);

      appRouter.go(Routes.sticker('BRA-1'), extra: _args);
      await tester.pump();
      await tester.pump();

      expect(find.text('SALVAR'), findsOneWidget);
      expect(find.text('EXCLUIR FIGURINHA'), findsOneWidget);

      notifier.dispose();
    });

    testWidgets('fails when the detail is opened without the sticker', (
      tester,
    ) async {
      final notifier = _signedInNotifier();
      final appRouter = await _openApp(tester, notifier);

      appRouter.go(Routes.sticker('BRA-1'));
      await tester.pump();
      await tester.pump();

      expect(tester.takeException(), isA<TypeError>());

      notifier.dispose();
    });
  });
}
